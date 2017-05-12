package Acme::MetaSyntactic::booze;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::booze - The booze theme (not for teetotalers)

=head1 DESCRIPTION

Types of alcoholic beverages.

=head1 CONTRIBUTOR

Nicholas Clark, after seeing BooK's talk at YAPC::Europe 2005 and amazed
that there was such an obvious omission.

=head1 BUGS

This list is incomplete. I try to drink my way further along, but I forget
where I get to. C<%-)>

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Updated with Chartreuse (incredible omission!), and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-12-05

Updated in Acme-MetaSyntactic version 0.51
(thus closing RT ticket #16256 opened by David Landgren).

=item *

2005-10-24

Introduced in Acme-MetaSyntactic version 0.45.

=item *

2005-09-08

Submitted by Nicholas Clark.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
beer
cider
perry
stout
porter
lager
wine
gin
rum
vodka
whisky
whiskey
port
sherry
absinthe
ale
mead
brandy
champagne
ouzo
martini
vermouth
suze
tequila
amaretto
drambuie
chartreuse
