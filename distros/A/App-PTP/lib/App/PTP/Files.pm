# This module provides functions to read the input files and to write the
# resulting output.

package App::PTP::Files;

use 5.022;
use strict;
use warnings;

use Data::Dumper;
use Exporter 'import';

# Every public function used by the main code is exported by default.
our @EXPORT = 
    qw(init_global_output close_global_output read_input write_output);
our @EXPORT_OK = qw(write_side_output read_side_input write_handle);

# The reference to this variable is used in the input list to specify that the
# standard input should be read.
our $stdin_marker = '<STDIN>';

# The reference to this variable is used in the input list to specify that all
# the inputs have been merged.
our $merged_marker = '<merged input>';

my $global_output_fh;

# $stdout is where the default (non-debug) output of the program should go. It
# will always be STDOUT, except during the tests.
sub init_global_output {
  my ($options, $stdout) = @_;
  if ($options->{output}) {
    if ($options->{debug_mode}) {
      print "All output is going to: $options->{output}\n";
    }
    my $mode = $options->{append} ? '>>' : '>';
    open ($global_output_fh, "${mode}:encoding($options->{output_encoding})",
          $options->{output})
      or die "Cannot open output file '$options->{output}': $!.\n";
  } elsif (not $options->{in_place}) {
    print "All output is going to STDOUT.\n" if $options->{debug_mode};
    $global_output_fh = $stdout;
  }
  # We're setting the correct binmode for STDOUT here, because it can be used
  # when in_place is true, but also if the --tee command is used.
  binmode($stdout, ":encoding($options->{output_encoding})");
}

sub close_global_output {
  my ($options) = @_;
  if ($options->{output}) {
    close $global_output_fh
        or die "Cannot close output file '$options->{output}': $!.\n";
  }
}

# read_handle(handle)
# Reads the content of the given handle and returns an array ref containing two
# elements. The first one is an array-ref with all the lines of the file and the
# second one is a variable indicating if the last line of the file had a final
# separator.
# This method uses the value of the `$intput_separator` global option.
sub read_handle {
  my ($handle, $options) = @_;
  local $/ = undef; # enable slurp mode;
  my $content = <$handle>;
  if (not defined $content) {
    if ($@) {
      chomp($@);
      die "FATAL: Cannot read input: $@\n";
    }
    # Theoretically this should not happen. But, on 5.22 this seems to happens
    # if the input file is empty.
    $content = '';
  }
  my @content;
  if ($options->{preserve_eol}) {
    @content = $content =~ /\G(.*?(?n:$options->{input_separator}))/gcms;
  } else {
    @content = $content =~ /\G(.*?)(?n:$options->{input_separator})/gcms;
  }
  my $missing_final_separator = 0;
  if ((pos($content) // 0) < length($content)) {
    $missing_final_separator = 1;
    print "The last line has no separator.\n" if $options->{debug_mode};
    push @content, substr($content, pos($content) // 0);
  }
  return (\@content, $missing_final_separator);
}

# read_file(path)
# Opens the given file, applies the correct read option, and calls read_handle.
sub read_file {
  my ($path, $options) = @_;
  print "Reading file: ${path}\n" if $options->{debug_mode};
  open (my $fh, "<:encoding($options->{input_encoding})", $path)
    or die "Cannot open file '$path': $!.\n";
  my @data = read_handle($fh, $options);
  close($fh) or die "Cannot close the file '$path': $!.\n";
  return @data;
}

# read_stdin()
# Applies the correct read option to STDIN and calls read_handle(STDIN).
sub read_stdin {
  my ($options, $stdin) = @_;
  print "Reading STDIN\n" if $options->{debug_mode};
  binmode($stdin, ":encoding($options->{input_encoding})");
  return read_handle($stdin, $options);
}

# read_input($input, $options, \*STDIN)
# Checks whether the input is the $stdin_marker or a file name and calls the
# matching method to read it, the third argument is the file-handle to read
# when $input is the $stdin_marker (usually STDIN except in tests).
sub read_input {
  my ($input, $options, $stdin) = @_;
  if (ref($input)) {
    if ($input == \$stdin_marker) {
      return read_stdin($options, $stdin);
    } else {
      die "Should not happen (".Dumper($input).")\n";
    }
  }
  return read_file($input, $options);
}

# write_content($handle, \@content, $missing_final_separator, \%options)
sub write_handle {
  my ($handle, $content, $missing_final_separator, $options) = @_;
  return unless @$content;
  local $, = $options->{output_separator};
  local $\ = $options->{output_separator}
      if $options->{fix_final_separator} || !$missing_final_separator;
  print $handle @$content;
}

# write_file($output_file_name, \@content, $missing_final_separator, append,
#            \%options)
sub write_file {
  my ($file_name, $content, $missing_final_separator, $append, $options) = @_;
  my $m = $append ? '>>' : '>';
  print "Outputing result to: ${m}${file_name}\n" if $options->{debug_mode};
  open (my $out_fh, "${m}:encoding($options->{output_encoding})", $file_name)
    or die "Cannot open output file '${file_name}': $!.\n";
  write_handle($out_fh, $content, $missing_final_separator, $options);
  close $out_fh or die "Cannot close output file '${file_name}': $!.\n";
}

# write_file($input_file_name, \@content, $missing_final_separator, \%options)
sub write_output {
  my ($file_name, $content, $missing_final_separator, $options) = @_;
  if ($options->{in_place}) {
    write_file($file_name, $content, $missing_final_separator, 0, $options);
  } else {
    write_handle($global_output_fh, $content, $missing_final_separator,
                 $options);
  }
}

# These two methodes are used by commands which read or write to side input/
# output files. The difference is that they expect a '-' in the given filename
# instead of the #stdin_marker, when referring to the standard input (or
# output).
my %known_side_output;
sub write_side_output {
  my ($file_name, $content, $missing_final_separator, $options) = @_;
  print "Outputing side result to: ${file_name}\n" if $options->{debug_mode};
  if ($file_name eq '-') {
    write_handle(\*STDOUT, $content, $missing_final_separator, $options);
  } else {
    write_file($file_name, $content, $missing_final_separator,
               $known_side_output{$file_name}++, $options);
  }
}

# Returns (\@content, $missing_final_separator).
sub read_side_input {
  my ($input, $options) = @_;
  if ($input eq '-') {
    return read_stdin($options);
  } else {
    return read_file($input, $options);
  }
}

1;
