package Acme::MetaSyntactic::state_flowers;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::state_flowers - The US State Flowers theme

=head1 DESCRIPTION

Each US state has a state flower. This theme uses all of them. Note however
that while there are 50 US states, there are only 43 entries in this theme.
This is not a bug - there are 7 pairs of states that have a common state
flower. Which leaves 43 different flowers.

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2012-05-07

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-09-04

Introduced in Acme-MetaSyntactic version 0.90.

=item *

2005-11-01

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
American_Dogwood Apple_Blossom Bitterroot Black_Eyed_Susan
Bluebonnet California_Poppy Camellia Cherokee_Rose Coast_Rhododendron
Forget_Me_Not Goldenrod Hawaiian_Hibiscus Hawthorn Indian_Paintbrush
Iris Magnolia Mayflower Mock_Orange Mountain_Laurel Oklahoma_Rose
Orange_Blossom Oregon_Grape Pasque_Flower Peach_Blossom
Peony Pink_and_White_Lady_s_Slipper Purple_Lilac Purple_Violet
Red_Clover Rhododendron Rocky_Mountain_Columbine Rose Sagebrush
Saguaro_Cactus_blossom Scarlet_Carnation Sego_Lily Sunflower Violet
White_Pine_Cone_and_Tassel Wild_Prairie_Rose Wood_Violet Yellow_Jessamine
Yucca_Flower
