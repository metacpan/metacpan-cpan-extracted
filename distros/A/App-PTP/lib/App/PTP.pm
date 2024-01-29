package App::PTP;

use 5.022;
use strict;
use warnings;

use App::PTP::Args;
use App::PTP::Commands 'warn_or_die_if_needed';
use App::PTP::Files;
use Data::Dumper;
use File::Find;
use Safe;

our $VERSION = '1.11';

$Data::Dumper::Terse = 1;  # Don't output variable names.
$Data::Dumper::Sortkeys = 1;  # Sort the content of the hash variables.
$Data::Dumper::Useqq = 1;  # Use double quote for string (better escaping).

my $safe = Safe->new();
$safe->deny_only(':subprocess', ':ownprocess', ':others', ':dangerous');
$safe->reval('use App::PTP::PerlEnv;');
$safe->reval('use File::Spec::Functions qw(:ALL);');

# maybe_expand_dirs(filepath)
# If filepath is a normal file, then returns it as, is.
# If filepath does not exist, then terminates the program with an error.
# If filepath is a directory and the $recursive option is not set then
# terminates the program with an error, otherwise returns the list of all files
# that it contains.
sub maybe_expand_dirs {
  my ($f, $options) = @_;
  if (ref $f) {
    # This will be the $stdin_marker reference.
    if ($options->{in_place}) {
      die "Reading from STDIN is incompatible with the --in-place option.\n";
    }
    return $f;
  } elsif (not -e $f) {
    die "File does not exist: ${f}\n";
  } elsif (-d _) {
    if (not $options->{recursive}) {
      die "Input is a directory (did you forget the -R option?): ${f}\n";
    }
    my @files;
    my $filter;
    if (defined $options->{input_filter}) {
      $filter = $safe->reval("sub { $options->{input_filter} }");
      die "FATAL: Cannot wrap code for --input_filter: ${@}" if $@;
    }
    find({
        # Because of the follow option, a stat has already been done on the file,
        # so the '_' magic is guaranteed to work.
        wanted => sub {
            if (-f _) {
              my $f = $_;
              if (defined $filter) {
                my $r = $filter->();
                return if warn_or_die_if_needed(
                    'Perl code failed while filtering input') || !$r;
              }
              push @files, $f;
            }
        } ,
        follow => 1,
        no_chdir => 1,
    }, $f);
    return sort @files;
  } else {
    # We assume that everything else is a file.
    return $f;
  }
}

sub process_all {
  my ($inputs, $pipeline, $options, $stdin) = @_;
  $App::PTP::Commands::I_setter->set(1);
  if ($options->{merge}) {
    print "Merging all the inputs.\n" if $options->{debug_mode};
    my $missing_final_separator = 0;
    my @content;
    for my $input (@$inputs) {
      my ($content, $missing_separator) =
          read_input($input, $options, $stdin);
      push @content, @$content;
      $missing_final_separator = $missing_separator;
    }
    App::PTP::Commands::process(
        \$App::PTP::Files::merged_marker, $pipeline, $options, \@content,
        $missing_final_separator);
    write_output(\$App::PTP::Files::merged_marker, \@content,
                 $missing_final_separator, $options);
  } else {
    for my $file_name (@$inputs) {
      my ($content, $missing_final_separator) =
          read_input($file_name, $options, $stdin);
      # Note that process can modify the input $file_name variable.
      App::PTP::Commands::process($file_name, $pipeline, $options, $content,
                                  $missing_final_separator);
      write_output($file_name, $content, $missing_final_separator, $options);
      $App::PTP::Commands::I_setter->inc();
    }
  }
}

sub Run {
  my ($stdin, $stdout, $stderr, $argv) = @_;
  select($stderr);  # All debug output, this applies inside the safe too.
  my ($inputs, $pipeline, $options) =
      App::PTP::Args::parse_command_line($argv);

  if ($options->{debug_mode}) {
    print 'options = '.Dumper($options)."\n";
    print 'inputs = '.Dumper($inputs)."\n";
    print 'pipeline = '.Dumper($pipeline)."\n";
  }

  @$inputs = map { maybe_expand_dirs($_, $options) } @$inputs;
  print 'expanded @inputs = '.Dumper($inputs)."\n" if $options->{debug_mode};

  return if $options->{abort};

  init_global_output($options, $stdout);
  process_all($inputs, $pipeline, $options, $stdin);
  close_global_output($options);
}

1;
