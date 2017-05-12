package DBIx::TextIndex::StopList::cz;

use strict;
use warnings;

# array of stoplisted words for the DBIx::TextIndex module
# all words must be in lower case and WITHOUT DIACRITICS

our @words = qw(
a
aniz
ano
at
az
bude
budu
by
bych
bychom
byl
byla
bylo
bysme
co
do
i
ja
je
jeho
jeji
jejich
jejim
jemu
ji
jim
jsem
jsi
jsou
k
kam
komu
ma
maji
mam
mela
mel
meli
mit
me
mi
moci
mohl
moje
mu
musel
muset
nac
nam
nas
nase
nasich
nasim
nasemu
ne
nem
nich
o
od
on
ona
ono
presto
pro
proc
proto
protoze
s
se
snad
te
tebe
tem
ti
tebe
ty
u
v
vam
vas
vase
vasich
vasim
vasemu
vedel
vedeli
vedet
vi
vim
vis
za
ze
z
);

1;
__END__

=head1 NAME

DBIx::TextIndex::StopList::cz - Czech-language stop list


=head1 SYNOPSIS

 require DBIx::TextIndex::StopList::cz;


=head1 DESCRIPTION

Contains a default list of Czech-language stop words

Used internally by L<DBIx::TextIndex>.


=head1 INTERFACE

None.


=head1 AUTHOR

Daniel Koch, dkoch@cpan.org.

Contributed by Tomas Styblo, tripie@cpan.org


=head1 COPYRIGHT

Copyright 1997-2007 by Daniel Koch.
All rights reserved.


=head1 LICENSE

This package is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, i.e., under the terms of the "Artistic
License" or the "GNU General Public License".


=head1 DISCLAIMER

This package is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut
