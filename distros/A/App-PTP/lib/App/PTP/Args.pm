package App::PTP::Args;

use 5.022;
use strict;
use warnings;

use App::PTP::Commands ':CMD';
use App::PTP::Util;
use Getopt::Long qw(GetOptionsFromArray :config auto_abbrev no_ignore_case
                    permute auto_version);
use List::Util;
use Pod::Usage;
use Scalar::Util 'looks_like_number';

# Name of files or directory to be processed. This can also contain a reference
# to the $stdin_marker variable, to indicate that the standard input needs to be
# processed.
my @inputs;

# The list of actions applied to the input. This is a list of array reference.
# Each of these array will contain the name of the command to run, the coderef
# for it, and then its arguments if any.
my @pipeline;

# This hash contains options that are used during the pipeline and that can be
# set or un-set for each command.
my %modes;
# This hash contains options that are global for the whole program.
my %options;

my $default_input_field = '\s*,\s*|\t';
my $default_output_field = "\t";

# env(foo => default)
# Returns the given environment variable or the default value.
# Always return the default value if the HARNESS_ACTIVE variable is set (so that
# tests are not affected by environment variables).
sub env {
  my ($var, $default) = @_;
  return $default if $ENV{HARNESS_ACTIVE};
  return $ENV{$var} // $default;
}

sub get_default_modes {
  my %m;
  $m{case_sensitive} = not(env(PTP_DEFAULT_CASE_INSENSITIVE => 0));
  $m{quote_regex} = env(PTP_DEFAULT_QUOTE_REGEX => 0);
  $m{global_match} = not(env(PTP_DEFAULT_LOCAL_MATCH => 0));
  $m{comparator} = \"default";
  $m{regex_engine} = env(PTP_DEFAULT_REGEX_ENGINE => 'perl');
  $m{fatal_error} = env(PTP_DEFAULT_FATAL_ERROR => 0);
  $m{inverse_match} = env(PTP_DEFAULT_INVERSE_MATCH => 0);
  $m{input_field} = $default_input_field;
  $m{output_field} = $default_output_field;
  return %m;
}

sub get_default_options {
  my %o;
  $o{input_encoding} = 'UTF-8';
  $o{output_encoding} = 'UTF-8';
  $o{input_separator} = '\n';  # This will be interpreted in a regex
  $o{output_separator} = "\n";
  $o{preserve_eol} = 0;
  $o{fix_final_separator} = 0;
  $o{recursive} = 0;
  $o{input_filter} = undef;
  $o{debug_mode} = 0;
  $o{merge} = 0;
  $o{in_place} = 0;
  $o{output} = undef;
  $o{append} = 0;
  $o{abort} = 0;
  $o{preserve_perl_env} = 0;
  $o{use_safe} = env(PTP_DEFAULT_SAFE => 0);
  return %o;
}

# Resets all the global variables used for the command line parsing. This is
# really useful only in tests.
sub reset_global {
  @inputs = ();
  @pipeline = ();
  %modes = get_default_modes();
  %options = get_default_options();
}

sub set_output {
  my (undef, $f) = @_;
  if (defined $options{output}) {
    die "Only a single occurence of --output or --append is allowed.\n";
  }
  $options{output} = $f;
}

sub options_flags {(
  'help|h' => sub { pod2usage(-exitval => 0, -verbose => 2) },
  'debug|d+' => \$options{debug_mode},
  'merge|m!' => \$options{merge},
  'in-place|i!' => \$options{in_place},
  'output|o=s' => \&set_output,
  'append|a=s' => sub { set_output(@_); $options{append} = 1; },
  'abort!' => \$options{abort},

  'recursive|R|r!' => \$options{recursive},
  'input-filter=s' =>  \$options{input_filter},
  'input-encoding|in-encoding=s' => \$options{input_encoding},
  'output-encoding|out-encoding=s' => \$options{output_encoding},
  'input-separator|in-separator=s' => \$options{input_separator},
  'output-separator|out-separator=s' => \$options{output_separator},
  'fix-final-separator!' => \$options{fix_final_separator},
  '0' => sub { $options{input_separator} = '\000';
               $options{output_separator} = '' },
  'preserve-input-separator|eol' =>
      sub { $options{preserve_eol} = 1; $options{output_separator} = '' },
  'preserve-perl-env!' => \$options{preserve_perl_env},
  'safe:2' => sub { $options{use_safe} = $_[1] },
)}

 sub modes_flags {(
  'case-sensitive|S' => sub { $modes{case_sensitive} = 1 },
  'case-insensitive|I' => sub { $modes{case_sensitive} = 0 },
  'quote-regexp|Q' => sub { $modes{quote_regex} = 1 },
  'end-quote-regexp|E' => sub { $modes{quote_regex} = 0 },
  'global-match|G' => sub { $modes{global_match} = 1 },
  'local-match|L' => sub { $modes{global_match} = 0 },
  'comparator|C=s' => sub { $modes{comparator} = $_[1] },
  'regex-engine|re=s' => 
      sub { die "Invalid value for --regex-engine: $_[1]\n" if $_[1] !~ /^\w+$/;
            $modes{regex_engine} = $_[1] },
  'fatal-error|X' => sub { $modes{fatal_error} = 1 },
  'ignore-error' => sub { $modes{fatal_error} = 0 },  # Find a short option?
  'inverse-match|V' => sub { $modes{inverse_match} = 1 },
  'normal-match|N' => sub { $modes{inverse_match} = 0 },
  'input-field-separator|F=s' => sub { $modes{input_field} = $_[1] },
  'output-field-separator|P=s' => \$modes{output_field},
  'default' => sub { $modes{input_field} = $default_input_field;
                     $modes{output_field} = $default_output_field; },
  'bytes' => sub { $modes{input_field} = ''; $modes{output_field} = ''; },
  'csv' => sub { $modes{input_field} = '\s*,\s*'; $modes{output_field} = ','; },
  'tsv' => sub { $modes{input_field} = '\t'; $modes{output_field} = "\t"; },
  'none' => sub { $modes{input_field} = '(?!)' },
)}

sub input_flags {(
  '<>' => sub { push @inputs, $_[0] },  # Any options not matched otherwise.
  '' => sub { push @inputs, \$App::PTP::Files::stdin_marker },  # a single '-'
)}

sub is_int {
  my ($str) = @_;
  return looks_like_number($str) && int($str) == $str;
}

sub validate_cut_spec {
  my ($spec) = @_;
  my @fields = split /\s*,\s*/, $spec;
  for my $f (@fields) {
    die "Fields passed to --cut must all be integers: $f\n" unless is_int($f);
    $f-- if $f > 0;
  }
  return \@fields;
}

sub action_flags {(
  'grep|g=s' =>
      sub { push @pipeline, ['grep', \&do_grep, {%modes}, $_[1]] },
  'substitute|s=s{2}' => 
      sub { push @pipeline, ['substitute', \&do_substitute, {%modes},
                             $_[1]] },
  # All the do_perl below could have the same sub using "$_[0]" instead of the
  # manually specified name.
  'perl|p=s' =>
      sub { push @pipeline, ['perl', \&do_perl, {%modes}, 'perl', $_[1]] },
  'n=s' =>
      sub { push @pipeline, ['n', \&do_perl, {%modes}, 'n', $_[1]] },
  'filter|f=s' =>
      sub { push @pipeline, ['filter', \&do_perl, {%modes}, 'filter', $_[1]] },
  'mark-line|ml=s' =>
      sub { push @pipeline, ['mark-line', \&do_perl, {%modes}, 'mark-line',
                             $_[1]] },
  'execute|e=s' =>
      sub { push @pipeline, ['execute', \&do_execute, {%modes}, $_[1]] },    
  'load|l=s' =>
      sub { push @pipeline, ['load', \&do_load, {%modes}, $_[1]] },
  'sort' => sub { push @pipeline, ['sort', \&do_sort, {%modes}] },
  'numeric-sort|ns' =>
      sub { my $opt = {%modes, comparator => \"numeric" };
            push @pipeline, [ 'numeric-sort', \&do_sort, $opt] },
  'locale-sort|ls' =>
      sub { my $opt = {%modes, comparator => \"locale" };
            push @pipeline, [ 'numeric-sort', \&do_sort, $opt] },
  'custom-sort|cs=s' =>
      sub { my $opt = {%modes, comparator => $_[1] };
            push @pipeline, [ 'custom-sort', \&do_sort, $opt] },
  'unique|u' =>
      sub { push @pipeline, ['unique', \&do_list_op, {%modes},
                             \&App::PTP::Util::uniqstr, 0] },
  'head:i' => sub { push @pipeline, ['head', \&do_head, {%modes}, $_[1]] },
  'tail:i' => sub { push @pipeline, ['tail', \&do_tail, {%modes}, $_[1]] },
  'reverse|tac' =>
      sub { push @pipeline,
                 ['reverse', \&do_list_op, {%modes}, sub {reverse @_ }, 1] },
  'shuffle' =>
      sub { push @pipeline, ['shuffle', \&do_list_op, {%modes},
                             \&List::Util::shuffle, 0] },
  'delete-marked' =>
      sub { push @pipeline, ['delete-marked', \&do_delete_marked, {%modes}, 
                             0] },
  'delete-before' =>
      sub { push @pipeline, ['delete-before', \&do_delete_marked, {%modes},
                             -1] },
  'delete-after' =>
      sub { push @pipeline, ['delete-after', \&do_delete_marked, {%modes},
                             1] },
  'delete-at-offset=i' =>
      sub { push @pipeline, ['delete-at-offset', \&do_delete_marked, {%modes},
                             $_[1]] },
  'insert-before=s' =>
      sub { push @pipeline, ['insert-before', \&do_insert_marked, {%modes},
                             -1, $_[1]] },
  'insert-after=s' =>
      sub { push @pipeline, ['insert-after', \&do_insert_marked, {%modes},
                             0, $_[1]] },
  'insert-at-offset=s{2}' =>
      sub { push @pipeline, ['insert-at-offset', \&do_insert_marked, {%modes},
                             $_[1]] },
  'clear-markers' =>
      sub { push @pipeline, ['clear-markers', \&do_set_markers, {%modes}, 0] },
  'set-all-markers' =>
      sub { push @pipeline, ['set-all-markers', \&do_set_markers, {%modes},
                             1] },
  'cut=s' => sub { push @pipeline, ['cut', \&do_cut, {%modes},
                   validate_cut_spec($_[1])] },
  'paste=s' => sub { push @pipeline, ['paste', \&do_paste, {%modes}, $_[1]] },
  'pivot' => sub { push @pipeline, ['pivot', \&do_pivot, {%modes}, 0] },
  'transpose' => sub { push @pipeline, ['transpose', \&do_pivot, {%modes}, 1] },
  'number-lines|nl' =>
      sub { push @pipeline, ['number-lines', \&do_number_lines, {%modes}] },
  'file-name|fn' =>
      sub { push @pipeline, ['file-name', \&do_file_name, {%modes}, 1] },
  'prefix-file-name|pfn' =>
      sub { push @pipeline, ['prefix-file-name', \&do_file_name, {%modes}, 0] },
  'line-count|lc' =>
      sub { push @pipeline, ['line-count', \&do_line_count, {%modes}] },
  'tee=s' => sub { push @pipeline, ['tee', \&do_tee, {%modes}, $_[1]] }
)}

sub all_args {
  return (options_flags(), modes_flags(), input_flags(), action_flags());
}

# parse_command_line(\@args)
sub parse_command_line {
  my ($args) = @_;
  reset_global();
  GetOptionsFromArray($args, all_args())
    or pod2usage(-exitval => 2, -verbose => 0);
    
  if ($options{debug_mode} > 1) {
    # When -d is specified multiple times, we add the marker on the final
    # output.
    push @pipeline, ['show-marker', \&do_perl, {%modes}, 'perl',
                     'pf "%s %s", ($m ? "*" : " "), $_']
  }

  # Because of the way the options are processed, each --replace options
  # (expecting two arguments) is pushed twice in the pipeline sub (once for each
  # argument). We're fixing this here.
  for my $i (0 .. $#pipeline) {
    if ($pipeline[$i][0] eq 'substitute') {
      push @{$pipeline[$i]}, $pipeline[$i+1]->[3];
      $pipeline[$i+1][0] = 'garbage';
    } elsif ($pipeline[$i][0] eq 'insert-at-offset') {
      my $o = $pipeline[$i]->[3];
      if (!ist_int($o)) {
        die "The first argument to --insert-at-offset must be an integer: $o\n";
      }
      push @{$pipeline[$i]}, $pipeline[$i+1]->[3];
      $pipeline[$i+1][0] = 'garbage';
    }
  }
  @pipeline = grep { $_->[0] ne 'garbage' } @pipeline;

  # Add any options that were passed after a '--' to the list of inputs.
  push @inputs, @$args;

  # Add the standard input marker to the inputs if no other input were
  # specified.
  push @inputs, \$App::PTP::Files::stdin_marker if not @inputs;

  if ($options{in_place} && $options{merge}) {
    die "The --in-place and --merge options are incompatible.\n";
  }

  if ($options{in_place} && $options{output}) {
    if ($options{append}) {
      die "The --in-place and --append options are incompatible.\n";
    } else {
      die "The --in-place and --output options are incompatible.\n";
    }
  }
  
  if (defined $options{input_filter} && !$options{recursive}) {
    print "WARNING: The --input-filter option is useless unless --recursive is specified too.\n";
  }
  
  return (\@inputs, \@pipeline, \%options);
}

1;
