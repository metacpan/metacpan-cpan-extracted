# -*- encoding: utf-8; indent-tabs-mode: nil -*-


use 5.38.0;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;

class Arithmetic::PaperAndPencil::Char 0.01;

field $char :param ;
field $underline = 0;
field $strike    = 0;
field $read      = 0;
field $write     = 0;

method pseudo_html {
  my $result = $char;
  if ($write) {
  $result = "<write>$result</write>";
  }
  elsif ($read) {
    # "elsif", because only one of (read|write) will be rendered, and write is more important than read
    $result = "<read>$result</read>";
  }
  if ($strike) {
    $result = "<strike>$result</strike>";
  }
  if ($underline) {
    $result = "<underline>$result</underline>";
  }
  return $result;
}
method set_char     ($c) { $char      = $c; }
method set_underline($n) { $underline = $n; }
method set_strike(   $n) { $strike    = $n; }
method set_read(     $n) { $read      = $n; }
method set_write(    $n) { $write     = $n; }
method char      { $char      }
method underline { $underline }
method strike    { $strike    }
method read      { $read      }
method write     { $write     }

sub space_char     { return Arithmetic::PaperAndPencil::Char->new(char => ' ' ); }
sub pipe_char      { return Arithmetic::PaperAndPencil::Char->new(char => '|' ); }
sub slash_char     { return Arithmetic::PaperAndPencil::Char->new(char => '/' ); }
sub backslash_char { return Arithmetic::PaperAndPencil::Char->new(char => '\\'); }

'π'; # End of Arithmetic::PaperAndPencil::Char

=head1 NAME

Arithmetic::PaperAndPencil::Char - individual characters when rendering an arithmetic operation

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Char> is a  class storing the characters
when rendering  an arithmetic operation. Beside  the character itself,
it stores  information about  the decoration  of the  char: underline,
strike, etc.

=head1 EXPORT

None. The I<xxx>C<_char> functions must be fully qualified when called.

=head1 SUBROUTINES/METHODS

=head2 pseudo_html

Renders the char with its attributes (underline, etc).

=head1 AUTHOR

Jean Forget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


