package App::JsonLogUtils;
# ABSTRACT: Command line utilities for dealing with JSON-formatted log files
$App::JsonLogUtils::VERSION = '0.02';


use strict;
use warnings;

use Fcntl             qw(:seek);
use Iterator::Simple  qw(iterator iter igrep imap ichain);
use JSON::XS          qw(decode_json encode_json);
use Time::HiRes       qw(sleep);
use Term::SimpleColor;

use parent 'Exporter';

our @EXPORT_OK = qw(
  lines
  tail
  json_log
  json_cols
  json_cut
  json_grep
);


#-------------------------------------------------------------------------------
# Internal utilities
#-------------------------------------------------------------------------------
sub log_warn { warn red,    @_, default, "\n" }
sub log_info { warn yellow, @_, default, "\n" }

sub _open {
  my $path = shift || return;
  return $path if ref $path;

  open my $fh, '<', $path or do{
    log_warn $!;
    return;
  };

  return $fh;
}



sub lines ($) {
  my $path = shift;
  my $fh   = _open $path || return;
  imap{ chomp $_; $_ } iter $fh;
}



sub tail ($) {
  my $path = shift;
  my $fh   = _open $path || return;
  my $pos  = 0;
  my $stop = 0;

  seek $fh, 0, SEEK_END;
  $pos = tell $fh;

  $SIG{INT} = sub{
    log_info 'Stopped';
    $stop = 1;
  };

  iterator{
    LINE:do{
      # Check for control-c
      if ($stop) {
        undef $SIG{INT};
        return;
      }

      # Check for file truncation
      my $eof = eof $fh;
      my $cur = tell $fh;

      seek $fh, 0, SEEK_END;
      my $end = tell $fh;

      if ($end < $cur) {
        log_info 'File truncated';
        $pos = $end;
      }
      else {
        $pos = $cur;
      }

      seek $fh, $pos, SEEK_SET;
      <$fh> if $eof;

      # Return next line
      if (defined(my $line = <$fh>)) {
        chomp $line;
        return $line;
      }

      # Reset position
      seek $fh, $pos, SEEK_SET;

      # Reset EOF condition on handle and wait for new input
      seek $fh, 0, SEEK_CUR;
      sleep 0.2;

      # Try again
      goto LINE;
    };
  };
}



sub json_log ($) {
  my $lines = shift;

  iterator{
    while (defined(my $line = <$lines>)) {
      if (!$line) {
        log_info 'empty line';
        next;
      }

      my $obj = eval{ decode_json $line };

      if ($@) {
        log_warn "invalid JSON: $line";
        next;
      }

      return [$obj, $line];
    }

    return;
  };
}



sub json_cols ($$$) {
  my ($cols, $sep, $lines) = @_;
  my @cols = ref $cols ? @$cols : split /\s+/, $cols;
  my $head = iter [ join($sep, @cols) ];
  my $rows = imap{
    my $obj = $_->[0];
    return join($sep, map{ $obj->{$_} || '' } @cols);
  } json_log $lines;
  ichain $head, $rows;
}



sub json_cut ($$$) {
  my ($fields, $inverse, $lines) = @_;
  my @fields = ref $fields ? @$fields : split /\s+/, $fields;

  if ($inverse) {
    imap{
      foreach my $field (@fields) {
        delete $_->[0]{$field};
      }

      $_->[0];
    } json_log $lines;
  }
  else {
    imap{
      my %filtered;
      foreach my $field (@fields) {
        $filtered{$field} = $_->[0]{$field};
      }

      \%filtered;
    } json_log $lines;
  }
}



sub json_grep ($$$) {
  my ($patterns, $inverse, $lines) = @_;
  return igrep{
    my $obj = $_->[0];

    foreach my $field (keys %$patterns) {
      foreach my $pattern (@{$patterns->{$field}}) {
        return unless $inverse
          ? $obj->{$field} !~ $pattern
          : $obj->{$field} =~ $pattern;
      }
    }

    return 1;
  }
  json_log $lines;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JsonLogUtils - Command line utilities for dealing with JSON-formatted log files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  # From the command line
  tail -f /path/to/log/file.log \
    | jgrep -m message="some pattern" \
    | jcut -f "timestamp priority message" \
    | cols -c "timestamp priority message" -s '|' \
    | column -t -s '|'


  # From code
  use App::JsonLogUtils qw(tail json_log);

  my $log = json_log tail '/path/to/file.log';

  while (my $entry = <$log>) {
    my ($json, $line) = @$entry;
    ...
  }


  # Grepping JSON logs
  use App::JsonLogUtils qw(lines json_log);
  use Iterator::Simple qw(igrep imap);

  my $entries = igrep{ $_->{foo} =~ /bar/ } # filter objects
                imap{ $_->[0] }             # select the object
                json_log                    # parse
                lines '/path/to/file.log';  # read

=head1 DESCRIPTION

Writing logs in JSON, one object per line, makes them very easily machine
readable. Wonderful. Unfortunately, it also makes it unfuriating to deal with
them using the standard unix command line tools. This package provides a few
tools to salve the burn.

=head1 COMMAND LINE TOOLS

=head2 L<jgrep>

Greps patterns in individual object fields.

=head2 L<jcut>

Filter the fields included in objects.

=head2 L<jcols>

Display fields in a format suitable for C<column>.

=head2 L<jshell>

An interactive shell for monitoring JSON log files.

=head1 EXPORTABLE ROUTINES

If desired, the iterators used to implement the tools above are optionally
exported by the main module.

=head1 lines

Accepts a file path or opened file handle and returns an iterator which yields
the chomped lines from the file.

  my $log = lines '/path/to/file.log';

  while (my $line = <$log>) {
    ...
  }

=head1 tail

Accepts a file path or opened file handle and returns an iterator while yields
chomped lines from the file as they are appended, starting from the end of the
file. Lines already written to the file when this routine is first called are
ignored (that is, there is no equivalent to C<tail -c 10> at this time).

  my $log = tail '/path/to/file.log';

  while (my $line = <$log>) { # sleeps until lines appended to file
    ...
  }

=head1 json_log

Accepts a file iterator (see L</tail> and L</lines>) and returns an iterator
yielding an array ref holding two items, a hash ref of the parsed JSON log
entry, and the original log entry string. Empty lines are skipped with a
warning. JSON decoding errors are ignored with a warning.

  my $lines = json_log tail '/path/to/file.log';

  while (my $entry = <$lines>) {
    my ($object, $line) = @_;
    ...
  }

=head2 json_cols

Accepts a list of fields (as a space-separared string or array ref of strings),
a string separator, and an iterator over JSON object strings, and returns a new
iterator. The returned iterator will first yield a string of column names
joined by the separator string. Subsequent calls will iterate over the JSON
object strings, return the value of each of the selected fields joined by the
separator string.

  # File $input
  {"a": 1, "b": 2, "c": 3}
  {"a": 4, "b": 5, "c": 6}
  {"a": 7, "b": 8, "c": 9}

  # Select columns a and c, separated by a pipe
  my $cols = json_cols "a c", "|" , lines $input;

  # ...yields the following strings:
  "a|c"
  "1|3"
  "4|6"
  "7|9"

=head2 json_cut

Accepts a space-separated string or array ref of C<$fields>, boolean
C<$inverse>, and an iterator of JSON log lines. Returns an iterator yielding
objects containing only the fields selected in C<$fields>. If C<$inverse> is
true, instead yields objects containing only the fields I<not> contained in
C<$fields>.

Give the same input as the L<previous example|/json_cols>:

  my $cut = json_cut "a c", 0, lines $input;

  # ...yields the following hash refs:
  {a => 1, c => 3}
  {a => 4, c => 6}
  {a => 7, c => 9}

  # Inverted
  my $cut = json_cut "a c", 1, lines $input;

  # ...yields:
  {b => 2}
  {b => 5}
  {b => 8}

=head2 json_grep

Accepts a hash ref where keys are field names and values are arrays of
regular expressions, a boolean C<$inverse>, and an iterator of JSON object
strings. Returns an iterator yielding array refs of the parsed JSON object
hash and the original string (just like L</json_log>). Only those entries
for which all fields' patterns match are returned. If C<$inverse> is set,
the logic is negated and only those entries for which all patterns test
false are returned.

  # File $input
  {"foo": "bar"}
  {"foo": "baz"}
  {"foo": "bat"}
  {"foo": "BAR"}

  # Code
  my $entries = json_grep { foo => [qw/bar/i, qr/baz/] }, 0, lines $input;

  # ...yields the following:
  [ {foo => "bar"}, '{"foo": "bar"}' ]
  [ {foo => "baz"}, '{"foo": "baz"}' ]
  [ {foo => "BAR"}, '{"foo": "BAR"}' ]

=head1 FUTURE PLANS

None, but will happily consider requests and patches.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
