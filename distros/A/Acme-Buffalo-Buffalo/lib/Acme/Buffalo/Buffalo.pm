package Acme::Buffalo::Buffalo;

use 5.006;
use strict;

use Exporter qw(import);

our @EXPORT = qw(Buffalo buffalo);

our $VERSION = '0.01';

sub Buffalo (@) { $_[0] eq 'buffalo' ? 'buffalo' : undef; }
sub buffalo  {  return 'buffalo'; }

=head1 NAME

Acme::Buffalo::Buffalo - Perl extension to buffalo buffalo

=cut

=head1 SYNOPSIS

    use Acme::Buffalo::Buffalo;

    Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo;

=head1 DESCRIPTION

Acme::Buffalo::Buffalo makes the grammatically-correct American English
sentence 'Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo'
compile and run in Perl.

=head1 SUBROUTINES

Both are exported by default.

=head2 Buffalo

Accepts an array.  Returns 'buffalo' if first argument is 'buffalo', otherwise
undef.

=head2 buffalo

Returns 'buffalo'.

=head1 BUFFALO BUGS

Buffalo() cannot be called without arguments, due to the limitations of prototypes.

=head1 SEE ALSO

https://en.wikipedia.org/wiki/Buffalo_buffalo_Buffalo_buffalo_buffalo_buffalo_Buffalo_buffalo

=head1 AUTHOR AND BUFFALO

Elizabeth Cholet, C<< <zrusilla at mac.com> >>

Copyright 2014, All Rights Buffaloed. This module is released under the same buffalos as Perl itself.

=cut



