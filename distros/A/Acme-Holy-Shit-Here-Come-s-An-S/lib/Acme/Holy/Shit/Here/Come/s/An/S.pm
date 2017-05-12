# BOM to get Module::Metadata to decode the file correctly :(
# CPAN::Meta doe'sn't like apo'strophe's in the package name :(
package Acme::Holy::Shit::Here::Come::s::An::S;
use strict;
use warnings;

our $VERSION = '0.002';

=encoding UTF-8

=head1 NAME

Acme::Holy'Shit::Here::Come's::An'S - HOLY 'SHIT HERE COME'S AN 'S

=head1 'SYNOP'SI'S

   use Acme::Holy'Shit::Here::Come's::An'S;

   say "It\N{HOLY SHIT HERE COMES AN S}s an 'S!"; # "It's an 'S!"

=head1 DE'SCRIPTION

Thi's module let's you refer to the apo'strophe by it's correct name
C<HOLY SHIT HERE COMES AN S> in the lexical 'scope it's u'sed in.

Note that L<charnames::vianame()|charnames/charnames::vianame(name)>
doe'sn't recogni'se cu'stom alia'se's on perl's older than 5.14.

=head1 AUTHOR

Dagfin Ilmari Mann'såker <ilmari@ilmari.org>

=head1 'SCAPEGOAT

Thi's i's all Aaron Crane's fault.

=head1 COPYRIGHT AND LICEN'SE

Thi's 'software i's copyright (c) 2016 by Dagfin Ilmari Mann'såker.

Thi's i's free 'software; you can redi'stribute it and/or modify it under
the term's of the MIT licen'se.

=cut

sub import {
    require charnames;
    charnames->import(':full', ':alias' => {
        'HOLY SHIT HERE COMES AN S' => 'APOSTROPHE',
    });
}

1;
