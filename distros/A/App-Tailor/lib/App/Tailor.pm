package App::Tailor;
# ABSTRACT: easily tailor terminal output to meet your needs
$App::Tailor::VERSION = '0.02';


use strict;
use warnings;

use Term::ANSIColor qw(color RESET);

use parent 'Exporter';

our @EXPORT = qw(
  ignore
  modify
  colorize
  tail
  itail
  reset_rules
);

use constant IGNORE   => 1;
use constant MODIFY   => 2;
use constant COLORIZE => 3;

our @RULES;
our $RESET = RESET;
our $DEBUG;

sub debug (&) {
  if ($DEBUG || $ENV{APP_TAILOR_DEBUG}) {
    my $msg = $_[0]->() || return;
    warn __PACKAGE__.": $msg\n";
  }
}

sub reset_rules () {
  undef @RULES;
}

sub itail (;$) {
  my $fh = shift || *STDIN;
  my $closed;

  return sub{
    return if $closed;

    LINE: until ($closed) {
      my $line = <$fh>;

      unless (defined $line) {
        $closed = 1;
        return;
      }

      chomp $line;

      debug{ "Input=[[$line]]" };

      for (@RULES) {
        $line = apply_rule($line, $_);

        unless (defined $line) {
          next LINE;
        }
      }

      return $line."\n";
    }

    debug{ 'end of input' };
  };
}

sub tail (;$$) {
  my $in   = shift || *STDIN;
  my $out  = shift || *STDOUT;
  my $iter = itail $in;
  while ( defined( my $line = $iter->() ) ) {
    print $out $line;
  }
}

sub apply_rule {
  my ($line, $rule) = @_;
  my ($type, @rule) = @$rule;

  debug{
    my $label = $type == IGNORE   ? 'ignore'
              : $type == MODIFY   ? 'modify'
              : $type == COLORIZE ? 'colorize'
                                  : $type;

    "applying rule <$label>: [@rule]";
  };

  if ($type == IGNORE) {
    my ($regex) = @rule;
    return if $line =~ /$regex/;
  }
  elsif ($type == MODIFY) {
    my ($regex, $replace) = @rule;

    if ($line =~ /$regex/) {
      if (ref $replace eq 'CODE') {
        $line =~ s/$regex/
          local $_ = $line;
          $replace->($line);
        /xe;
      }
      else {
        eval "\$line =~ s/$regex/$replace/";
      }
    }
  }
  elsif ($type == COLORIZE) {
    my ($regex, $color) = @rule;
    $line =~ s/($regex)/$color$1$RESET/;
  }

  return $line;
}

sub ignore ($) {
  my ($regex) = @_;
  push @RULES, [IGNORE, $regex];
}

sub modify ($$) {
  my ($regex, $replacement) = @_;
  push @RULES, [MODIFY, $regex, $replacement];
}

sub colorize ($@) {
  my ($regex, @colors) = @_;
  my $color = color @colors;
  push @RULES, [COLORIZE, $regex, $color];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Tailor - easily tailor terminal output to meet your needs

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  #-------------------------------------------------------------------------------
  # file: my-filter.pl
  #-------------------------------------------------------------------------------
  use App::Tailor;
  use JSON::XS qw(decode_json);

  # ignore lines containing /ping
  ignore qr/\/ping/;

  # parse JSON-encoded lines
  modify qr/^{/ => sub{
    my $data = decode_json $_;
    my $msg  = $data->{message};
    my $ts   = $data->{timestamp};
    my $pri  = $data->{priority};
    return "[$ts] [$pri] $msg";
  };

  # make error lines white on red
  colorize qr/\[ERROR\]/ => qw(white on_red);

  # tail STDIN
  tail;

  #-------------------------------------------------------------------------------
  # using your filter
  #-------------------------------------------------------------------------------
  $ tail /var/log/some-log-file | my-filter.pl

=head1 DESCRIPTION

There are a number of programs available to filter, colorize, and modify
streaming output. Generating exactly the desired output often requires
pipe-chaining many calls to grep, cut, cols, jq, et al, or using an inflexible
config file or files, often in tandem with a long chain of piped commands.

C<App::Tailor> makes it easier to do this by making it trivial to write quick
scripts to filter, alter, and colorize output exactly as needed.

=head1 EXPORTS

=head2 ignore

Accepts a regex which, when matched, will cause a line of input to be ignored.

  ignore qr/foo/;       # ignore any line containing 'foo'
  ignore qr/foo(?=bar)  # ignore any line containing 'foo' followed by 'bar'

Ignored rules are applied to each line of input B<FIRST>.

=head2 modify

Accepts a regex which, when matched, will cause a the first capture in the
input to by modified. If the second argument is a string, it will replace the
first capture in the matching regex. If the second argument is a function, it
will be called on the first capture's matching text and its return value will
replace the captured text in the line's output. For convenience, C<$_> is
assigned to the value of the captured text.

If multiple matching rules exist, they are applied in the order in which they
were defined.

  modify qr/foo/ => sub{ uc $_ };   # foo => FOO
  modify qr/FOO/ => 'FOOL';         # FOO => 'FOOL';

Modifier rules are applied to each line of input B<SECOND>.

=head2 colorize

Accepts a regex which, when matched, will cause the entire match to be
colorized using ANSI color escapes. The second argument is a list of color
labels to be applied. See L<Term::ANSIColor/Function-Interface> for acceptable
labels.

  # "foo" has fg:red, bg:white
  colorize qr/foo/ => qw(red on_white);

  # "foo" when followed by "bar" will become painful to look at;
  # "bar" itself is not colorized.
  colorize qr/foo(?=bar) => qw(bright_white on_bright_magenta);

Colorizing rules are applied to each line of input B<LAST>.

=head2 tail

Tails an input stream. By default, reads from C<STDIN> and prints to C<STDOUT>,
applying any rules defined with L</ignore>, L</modify>, and L</colorize> to the
emitted output.

Input and output streams may be overridden by passing positional parameters,
both of which are optional:

  tail $in, $out;

=head2 itail

Returns a function which reads from an input stream and returns lines of text
after applying any rules defined with L</ignore>, L</modify>, and L</colorize>
to the emitted output. Returns C<undef> when the input stream is closed.

As with L</tail>, the default input stream (C<STDIN>) may be overridden.

  my $tailor = itail $fh;

  while (defined(my $line = $tailor->())) {
    print $line;
  }

=head2 reset_rules

Clears all defined rules, resetting filtering state to initial load state.

=head1 DEBUGGING

To help with troubleshooting scripts built with C<App::Tailor>, verbose logging
may be enabled by setting the environment variable C<APP_TAILOR_DEBUG> to a
true value or by setting the value of C<$App::Tailor::DEBUG> to a true value
directly.

=head1 AUTHOR

Jeff Ober <sysread@fastmail.fm>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
