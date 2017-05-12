package Acme::emcA;

use 5.004;
use strict qw[vars subs];
use vars '$VERSION';

$VERSION = '0.10E0';

open 0 or print "Can't reverse '$0'\n" and exit;
( my $code = join "", <0> ) =~ s/.*?^(\s*);?use\s+Acme::emcA\s*(?: esu)?;\n//sm;
my $max = 10 + length $1;
local $SIG{__WARN__} = \&is_forward;
do { eval forward($code); exit } if is_backward($code);
open 0, ">$0" or print "Can't reverse '$0'\n" and exit;
$max  = 10;
$code = backward($code);
$code =
    ( " " x ( $max - 10 ) )
  . ";use Acme::emcA esu;\n"
  . ( " " x ( $max * 2 ) ) . "\n"
  . $code;
print {0} $code . ( join( "\n", reverse split( /\n/, $code ) ) ), "\n" and exit;

sub forward {
    join( "\n",
        map substr( $_, $max ),
        ( split "\n", substr( $_[0], 0, length( $_[0] ) / 2 ) ) );
}

sub is_forward { $_[0] !~ /^ {20,}$/m }
sub is_backward { $_[0] =~ s/\n?.*$// if $_[0] =~ /^ {20,}$/m }

sub backward {
    @_ = split "\n", $_[0];
    length > $max && ( $max = length ) for @_;
    return join "\n", map sprintf( "%${max}s", scalar reverse $_ ) . $_, @_, '';
}

1;

__END__

=head1 NAME

Acme::emcA - Acme::emcA

=head1 VERSION

This document describes version 0.10E0 of Acme::emcA, released
December 24, 2007.

=head1 SYNOPSIS

    use Acme::emcA;
    print "Hello, World";

=head1 DESCRIPTION

The first time you run a program under C<use Acme::emcA>, the module takes
your source file and makes an mirror image of it at both row- and column-
level.  The code continues to work exactly as it did before, but now it looks
like this:

		;use Acme::emcA esu;

    ;"!dlroW ,olleH" tnirpprint "Hello, World!";

    ;"!dlroW ,olleH" tnirpprint "Hello, World!";

		;use Acme::emcA esu;

=head1 DIAGNOSTICS

=over 4

=item C<Can't reverse "%s">

Acme::emcA could not access the source file to modify it.

=head1 SEE ALSO

L<Acme::Palindrome> - Code and documentation nearly taken verbatim from it.

=head1 COPYRIGHT

Copyright 2003, 2005, 2007 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

This software is released under the MIT license cited below.

=head2 The "MIT" License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=cut
