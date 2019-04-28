# This module contains the function that are pushed in the pipelines and which
# are operating on the input files.

package App::PTP::Commands;

use 5.022;
use strict;
use warnings;

no warnings 'experimental::smartmatch';
use feature 'switch';

use App::PTP::Files qw(write_side_output read_side_input);
use App::PTP::PerlEnv;
use App::PTP::Util;
use Cwd qw(abs_path);
use Data::Dumper;
use Exporter 'import';
use File::Spec::Functions qw(rel2abs);
use List::Util qw(min max);
use Safe;

# Every public function is exported by default.
my @all_cmd = 
    qw(prepare_perl_env do_grep do_substitute do_perl
    do_execute do_load do_sort do_list_op do_tail do_head do_delete_marked
    do_insert_marked do_set_markers do_number_lines do_file_name do_line_count
    do_cut do_paste do_pivot do_tee);
our @EXPORT_OK = (@all_cmd, 'warn_or_die_if_needed');
our %EXPORT_TAGS = (CMD => \@all_cmd);

our @markers;  # The current marker array, not shared in the safe.
tie @App::PTP::PerlEnv::m, 'App::PTP::Util::MarkersArray';

my $f_setter = tie $App::PTP::PerlEnv::f, 'App::PTP::Util::ReadOnlyVar';
my $F_setter = tie $App::PTP::PerlEnv::F, 'App::PTP::Util::ReadOnlyVar';
my $n_setter = tie $App::PTP::PerlEnv::n, 'App::PTP::Util::ReadOnlyVar';
my $N_setter = tie $App::PTP::PerlEnv::N, 'App::PTP::Util::ReadOnlyVar';
my $m_setter = tie $App::PTP::PerlEnv::m, 'App::PTP::Util::AliasVar';
# This variable is public because it is set in the App::PTP::process_all method.
our $I_setter = tie $App::PTP::PerlEnv::I, 'App::PTP::Util::ReadOnlyVar';

# This 'safe' provides an isolated environment for all the regex and perl code
# execution provided by the user.
my $safe;  # Sets to Safe->new() before each new file processed;

# Prepare the $safe variable so that it can execute code with access to our
# PerlEnv.
sub new_safe {
  my ($options) = @_;
  if ($safe and $options->{preserve_perl_env} and
      $safe->reval('$PerlEnv_LOADED')) {
    print "Skipping creation of new safe.\n" if $options->{debug_mode};
    return;
  }
  print "Creating a new safe.\n" if $options->{debug_mode};
  $safe = Safe->new();
  $safe->share_from('App::PTP::PerlEnv', \@App::PTP::PerlEnv::EXPORT_OK);
  if ($options->{use_safe} > 1) {
    $safe->permit_only(qw(:base_core :base_mem :base_loop :base_math :base_orig
                          :load));
    $safe->deny(qw(tie untie bless));
  } else {
    $safe->deny_only(qw(:subprocess :ownprocess :others :dangerous));
  }
  if ($@) {
    chomp($@);
    die "INTERNAL ERROR: cannot load the PerlEnv module: ${@}\n";
  }
}

# Prepare an App::PTP::SafeEnv package with access to the PerlEnv one and
# nothing else.
sub reset_safe_env {
  my ($options) = @_;
  if ($options->{preserve_perl_env} and $App::PTP::SafeEnv::PerlEnv_LOADED) {
    print "Skipping reset of perl environment.\n" if $options->{debug_mode};
    return;
  }
  print "Reseting the perl environment.\n" if $options->{debug_mode};
  # We can't undef the hash, otherwise the code compiled in the eval below no
  # longer refers to the same package (this would work however with a
  # string-eval instead of a block-eval as the code would be compiled and
  # create a new package hash).
  %App::PTP::SafeEnv:: = ();
  eval {
    package App::PTP::SafeEnv;
    App::PTP::PerlEnv->import(':all');
    our $PerlEnv_LOADED = 1;  # For some reason the import does not work
  };
  if ($@) {
    chomp($@);
    die "INTERNAL ERROR: cannot prepare the SafeEnv package: ${@}\n";
  }
}

# Delete the PerlEnv (both the safe and the eval based one). This method is only
# meant to be called from tests.
sub delete_perl_env {
  undef $safe;
  %App::PTP::SafeEnv:: = ();
}

# Should be called for each new file so that the environment seen by the user
# supplied Perl code is empty.
sub prepare_perl_env {
  my ($file_name, $options) = @_; 
  if (ref($file_name)) {
    $f_setter->set('-');
    $F_setter->set('-');
  } else {
    $f_setter->set($file_name);
    $F_setter->set(abs_path($file_name));
  }
  if ($options->{use_safe} > 0) {
    new_safe($options);
  } else {
    reset_safe_env($options);
  }
}

# process($file_name, \@pipeline, \%options, \@content, $missing_final_sep)
# Applies all the stage of the pipeline on the given content (which is modified
# in place).
sub process {
  my ($file_name, $pipeline, $options, $content, $missing_final_separator) = @_;
  if ($options->{debug_mode}) {
    # For long files, we print only the first and last lines.
    my @debug_content = @$content;
    my $omit_msg = sprintf "... (%d lines omitted)", (@$content - 8);
    splice @debug_content, 4, -4, $omit_msg if @$content > 10; 
    if (ref($file_name)) {
      print "Processing $${file_name} with content: ".Dumper(\@debug_content);
    } else {
      print "Processing '${file_name}' with content: ".Dumper(\@debug_content);
    }
    print "Has final separator: ".($missing_final_separator ? 'false' : 'true')."\n";
  }
  prepare_perl_env($file_name, $options);
  @markers  = (0) x scalar(@$content);
  my $markers = \@markers;
  for my $stage (@$pipeline) {
    my ($command, $code, $modes, @args) = @$stage;
    $N_setter->set(scalar(@$content));
    $modes->{missing_final_separator} = $missing_final_separator;
    $modes->{file_name_ref} = \$_[0];  # this is an alias to the passed value.
    if ($options->{debug_mode}) {
      local $Data::Dumper::Indent = 0;
      printf "Executing command: %s(%s).\n", $command,
             join(', ', map { Dumper($_) } @args);
    }
    &$code($content, $markers, $modes, $options, @args);
  }
}

sub base_prepare_re {
  my ($re, $modes) = @_;
  if ($modes->{quote_regex}) {
    $re = quotemeta($re);
  }
  if (not $modes->{case_sensitive}) {
    $re = '(?i)'.$re;
  }
  return $re;
}

# prepare_re('re', \%options)
# Applies the modal option on the given regex.
# This function is not exported.
sub prepare_re {
  my ($re, $modes) = @_;
  $re = base_prepare_re($re, $modes);
  my $r;
  if ($modes->{regex_engine} ne 'perl') {
    # Some play to correctly escape whetever special characters might be in the
    # regex while preserving its semantics. This relies on the fact that the
    # 'Terse' option of Data::Dumper is set in the main program.
    # The regex-engine variable has been validated in the Args module.
    my $str_re = Dumper($re);
    $r = eval "use re::engine::$modes->{regex_engine};
               \$re = $str_re;
               qr/\$re/s ";
    if ($@) {
      chomp($@);
      die "FATAL: Cannot use the specified regex engine: ${@}\n";
    }
  } else {
    $r = qr/$re/s;
  }
  return $r;
}

sub quote_for_re {
  my ($text, $modes) = @_;
  if ($modes->{quote_regex}) {
    return quotemeta($text);
  } else {
    # We quote just the '{' or '}' characters.
    return $text =~ s/(\{|\})/\\$1/gr;
  }
}

sub prepare_re2 {
  my ($re, $modes) = @_;
  $re = quote_for_re($re, $modes);
  if (not $modes->{case_sensitive}) {
    $re = '(?i)'.$re;
  }
  my $use_statement = '';
  if ($modes->{regex_engine} ne 'perl') {
    $use_statement = "use re::engine::$modes->{regex_engine};";
  }
  return ($use_statement, "{${re}}");
}

sub do_grep {
  my ($content, $markers, $modes, $options, $re) = @_;
  my ($use_stmt, $quoted_re) = prepare_re2($re, $modes);
  print "\$re = ${quoted_re}\n" if $options->{debug_mode};
  my $wrapped = get_code_in_safe_env(
      "{; ${use_stmt} undef \$_ unless m ${quoted_re} }", $options, '--grep');
  $. = 0;
  map { $m_setter->set(\$markers->[$.]);
        $n_setter->set($.++);
        $wrapped->() } @$content;
  # This code is duplicated from do_perl:
  for my $i (0 .. $#$content) {
    if (not defined $content->[$i]) {
      undef $markers->[$i];
    } elsif (not defined $markers->[$i]) {
      $markers->[$i] = '';  # We don't want undef here, as we will filter on it.
    }
  }
  @$content = grep { defined } @$content;
  @$markers = grep { defined } @$markers;
}

sub do_substitute {
  my ($content, $markers, $modes, $options, $re, $subst) = @_;
  if ($options->{debug_mode}) {
    print "Before: \$re = ${re}; \$subst = ${subst}\n";
  }
  my ($use_stmt, $quoted_re) = prepare_re2($re, $modes);
  my $quoted_subst = quote_for_re($subst, $modes);
  my $g = $modes->{global_match} ? 'g' : '';
  if ($options->{debug_mode}) {
    print "After: \$re = ${quoted_re}; \$subst = ${quoted_subst}\n";
  }
  my $wrapped = get_code_in_safe_env(
      "; ${use_stmt} s ${quoted_re}{${quoted_subst}}${g}", $options,
      '--substitute');
  $. = 0;
  map { $m_setter->set(\$markers->[$.]);
        $n_setter->set($.++);
        $wrapped->() } @$content;
}

sub warn_or_die_if_needed {
  my ($text, $modes) = @_;
  return 0 unless $@;
  chomp($@);
  if ($modes->{fatal_error}) {
    die "FATAL: ${text}: ${@}\n";
  } else {
    print "WARNING: ${text}: ${@}\n";
  }
  return 1;
}

sub eval_in_safe_env {
  my ($code, $options) = @_;
  if ($options->{debug_mode} > 1) {
    print "Evaluating the following code: ${code}\n";
  }
  if ($options->{use_safe} > 0) {
    return $safe->reval($code);
  } else {
    return eval("package App::PTP::SafeEnv;
                 no strict;
                 no warnings;
                 ${code}");
  }
}

sub get_code_in_safe_env {
  my ($code, $options, $cmd) = @_;
  my $wrapped_code = eval_in_safe_env("sub { ${code} }", $options);
  die "FATAL: Cannot wrap code for ${cmd}: ${@}" if $@;
  return $wrapped_code;
}

sub do_perl {
  my ($content, $markers, $modes, $options, $cmd, $code) = @_;
  $. = 0;
  my $scmd = '-'.($cmd =~ s/^(..)/-$1/r); # --perl or -n.
  my $wrapped_code = get_code_in_safe_env($code, $options, $scmd);
  my @result = map { 
          $m_setter->set(\$markers->[$.]);
          $n_setter->set(++$.);
          my $input = $_;
          # Among other things, this ensures that the code is always executed in
          # a scalar context.
          my $r = eval { $wrapped_code->() };
          # We can't use return as we're not in a sub.
          if (warn_or_die_if_needed("Perl code failed in ${scmd}", $modes)) {
            given ($cmd) {
              1 when 'filter';
              $input when 'n';
              $markers[$.] when 'mark-line';
            }
          } else {
            $r;
          }
        } @$content;

  $n_setter->set(undef);
  $m_setter->set(\undef);

  if ($cmd eq 'perl') {
    # Do nothing with the result.
  } elsif ($cmd eq 'n') {
    @$content = @result;
  } elsif ($cmd eq 'filter') {
    for my $i (0 .. $#$content) {
      if (!$result[$i] xor $modes->{inverse_match}) {
        undef $content->[$i];
      }
    }
  } elsif ($cmd eq 'mark-line') {
    @$markers = @result;
  } else {
    die "FATAL: Invalid command received for perl operation ($cmd).\n";
  }

  for my $i (0 .. $#$content) {
    if (not defined $content->[$i]) {
      undef $markers->[$i];
    } elsif (not defined $markers->[$i]) {
      $markers->[$i] = '';  # We don't want undef here, as we will filter on it.
    }
  }
  @$content = grep { defined } @$content;
  @$markers = grep { defined } @$markers;
}

sub do_execute {
  my ($content, $markers, $modes, $options, $code) = @_;
  eval_in_safe_env($code, $options);
  if ($@) {
    chomp($@);
    die "FATAL: Perl code failed in --execute: ${@}\n";
  }
}

sub do_load {
  my ($content, $markers, $modes, $options, $file) = @_;
  # do can open relative paths, but in that case it looks them up in the @INC
  # directory, which we want to avoid.
  # We don't use abs_path here to not die (just yet) if the file does not exist.
  my $abs_path = rel2abs($file);
  print "Loading file: '$abs_path'\n" if $options->{debug_mode};
  if (not defined eval_in_safe_env("do '${abs_path}';", $options)) {
    if ($@) {
      die "FATAL: Perl code failed in --load: ${@}\n";
    } elsif ($!) {
      die "FATAL: Cannot load file '$file' for --load: $!\n";
    }
  }
}

sub do_sort {
  my ($content, $markers, $modes, $options) = @_;
  if (ref($modes->{comparator}) eq 'CODE') {
    # This branch is no longer used.
    @$content = sort { $modes->{comparator}() } @$content;
  } elsif (ref($modes->{comparator}) eq 'SCALAR') {
    if (${$modes->{comparator}} eq 'default') {
      @$content = sort @$content;
    } elsif (${$modes->{comparator}} eq 'numeric') {
      no warnings "numeric";
      @$content = sort { $a <=> $b } @$content;
    } elsif (${$modes->{comparator}} eq 'locale') {
      use locale;
      @$content = sort { $a cmp $b } @$content;
    } else {
      die sprintf "INTERNAL ERROR: Invalid comparator (%s)\n.", 
                  ${$modes->{comparator}};
    }
  } else {
    die sprintf "INTERNAL ERROR: Invalid comparator type (%s)\n.",
                Dumper($modes->{comparator}) if ref $modes->{comparator};
    my $cmp = $modes->{comparator};
    my $sort = get_code_in_safe_env("sort { $cmp } \@_", $options,
                                    'custom comparator');
    @$content = $sort->(@$content);
  }
  @$markers = (0) x scalar(@$content);
}

sub do_list_op {
  my ($content, $markers, $modes, $options, $sub, $apply_on_markers) = @_;
  @$content = &$sub(@$content);
  if ($apply_on_markers) {
    @$markers = &$sub(@$markers);
  } else {
    @$markers = (0) x scalar(@$content);
  }
}

sub do_tail {
  my ($content, $markers, $modes, $options, $len) = @_;
  $len = 10 unless $len;
  splice @$content, 0, -$len;
  splice @$markers, 0, -$len;
}

sub do_head {
  my ($content, $markers, $modes, $options, $len) = @_;
  $len = 10 unless $len;
  $len = -@$content if $len < -@$content;
  splice @$content, $len;
  splice @$markers, $len;
}

sub do_delete_marked {
  # negative offset if we're deleting a line before the marker.
  my ($content, $markers, $modes, $options, $offset) = @_;
  my $start = min(max(0, -$offset), $#$content);
  my $end = max(min($#$content, $#$content + $offset), $#$content);
  my @markers_temp = @$markers;  # So that we can read it even after an undef.
  for my $i ($start .. $end) {
    if ($markers_temp[$i]) {
      undef $content->[$i + $offset];
      undef $markers->[$i + $offset];
    }
  }
  @$content = grep { defined } @$content;
  @$markers = grep { defined } @$markers;
}

sub do_insert_marked {
  # negative offset if we're inserting a line before the marker.
  my ($content, $markers, $modes, $options, $offset, $line) = @_;
  my @markers_temp = @$markers;
  my @content_temp = @$content;
  my $added = 0;
  my $wrapped;
  if (not $modes->{quote_regex}) {
    $wrapped = get_code_in_safe_env("\"${line}\"", $options,
                                    '--insert-marked');
  }
  for my $i (0 .. $#content_temp) {
    next unless $markers_temp[$i];
    my $r;
    if ($modes->{quote_regex}) {
      $r = $line;
    } else {
      $_ = $content_temp[$i];
      $n_setter->set($i + 1);
      $m_setter->set($markers_temp[$i]);
      $line =~ s/(?:[^\\]|^)((:?\\\\)*")/\\$1/g;
      $r = eval { $wrapped->() };
      next if warn_or_die_if_needed(
          'String interpolation failed in --insert-marked', $modes);
      # it should not be possible for the result to be undef...
    }
    # We never insert at a negative offset or before the previously added line.
    # Offset = 0 means we're inserting after the current line.
    my $target = $i + $offset + 1 + $added;
    $target = $added if $target < $added;
    $target = @$content if $target > @$content;
    ++$added;
    splice @$content, $target, 0, $r;
    splice @$markers, $target, 0, 0;
  }
}

sub do_set_markers {
  my ($content, $markers, $modes, $options, $value) = @_;
  @$markers = ($value)x scalar(@$content);
}

sub do_number_lines {
  my ($content, $markers, $modes, $options) = @_;
  my $line = 0;
  my $n = int(log(@$content) / log(10)) + 1;
  map { $_ = sprintf("%${n}d  %s", ++$line, $_) } @$content;
}

sub do_file_name {
  my ($content, $markers, $modes, $options, $replace_all) = @_;
  my $name;
  if (ref($modes->{file_name_ref}) eq 'SCALAR') {
    $name = ${$modes->{file_name_ref}};
  } elsif (ref($modes->{file_name_ref}) eq 'REF' and
           ref(${$modes->{file_name_ref}}) eq 'SCALAR') {
    $name = $${$modes->{file_name_ref}};
  } else {
    die 'INTERNAL ERROR: Invalid input marker: '.Dumper($modes->{file_name_ref})
        ."\n";
  }
  if ($replace_all) {
    @$content = ($name);
    @$markers = (0);
  } else {
    unshift @$content, $name;
    unshift @$markers, 0;
  }
}

sub do_line_count {
  my ($content, $markers, $modes, $options) = @_;
  @$content = (scalar(@$content));
  @$markers = (0);
}

sub do_cut {
  my ($content, $markers, $modes, $options, $spec) = @_;
  my $re = prepare_re($modes->{input_field}, $modes);
  if ($options->{debug_mode}) {
    print "Examples of the --cut operation:\n";
    my @debug = map {  [split $re] } @$content[0..min(5, $#$content)];
    map { for ((@$_)[@$spec]) { $_ = "-->${_}<--" if $_ } } @debug;
    local $, = $modes->{output_field};
    local $\ = $options->{output_separator};
    map { print @$_ } @debug;
  }
  @$content =
      map {
        join $modes->{output_field}, map { $_ ? $_ : '' } (split $re)[@$spec]
      } @$content;
}

sub do_paste {
  my ($content, $markers, $modes, $options, $file) = @_;
  my ($side_content, undef) = read_side_input($file, $options);
  for my $i (0 .. $#$side_content) {
    $content->[$i] .= $modes->{output_field}.$side_content->[$i];
  }
  for my $i ($#$side_content + 1 .. $#$content) {
    $content->[$i] .= $modes->{output_field};
  }
  if (@$content > @$markers) {
    splice @$markers, scalar(@$markers), 0, (0) x (@$content - @$markers);
  }
}

sub do_pivot {
  my ($content, $markers, $modes, $options, $action) = @_;
  my $m = 0;
  # This is unused by the 'pivot' action, but it's not a huge issue.
  my $re = prepare_re($modes->{input_field}, $modes);
  if ($action eq 'transpose') {
    $m = 0;
    my @lines =
        map { my $r = [split $re]; $m = max($m, scalar(@$r)); $r } @$content;
    @$content =
      map {
          my $c = $_;
          join $modes->{output_field}, map { $_->[$c] // '' } @lines;
      } 0..($m - 1);
  } elsif ($action eq 'pivot') {
    $m = 1;
    @$content = (join $modes->{output_field}, @$content);
  } elsif ($action eq 'anti-pivot') {
    @$content = map { split $re } @$content;
    $m = @$content;
  } else {
    die "INTERNAL ERROR: unknown action for the pivot method: ${action}\n";
  }
  @$markers = (0) x $m;
}

sub do_tee {
  my ($content, $markers, $modes, $options, $file_name) = @_;
  if (not $modes->{quote_regex}) {
    $file_name = eval_in_safe_env("\"${file_name}\"", $options);
    die "FATAL: Cannot eval string for --tee: ${@}" if $@;
  }
  # This missing_final_separator is not really an option, it is added in the
  # modes struct by the 'process' method, specifically for this function.
  write_side_output($file_name, $content, $modes->{missing_final_separator},
                    $options);
}

1;
