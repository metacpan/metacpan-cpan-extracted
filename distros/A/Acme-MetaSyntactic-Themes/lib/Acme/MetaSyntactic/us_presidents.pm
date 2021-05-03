package Acme::MetaSyntactic::us_presidents;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.001';
__PACKAGE__->init();

our %Remote = (
    source  => 'https://www.whitehouse.gov/1600/Presidents',
    extract => sub {
        return
            map { s/(?:,| the [1-9]).*//; y'- .'_'; s/_+/_/g; s/_+\z//; s/\b(.)/uc $1/eg; $_ }
	    #grep { !/^(?:BEGIN|END)$/ }
	    #$_[0] =~ /"Portrait of ([^"]+)"/g;
	    $_[0] =~ m{<h3 class="acctext--con grid-item__title h4alt">\s*([^<]+?)\s*</h3>}g;
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::us_presidents - The presidents of the USA theme

=head1 DESCRIPTION

Presidents of the USA.

This list is based on the official White House list, available at:
L<https://www.whitehouse.gov/1600/Presidents>.

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

=item *

2021-04-30 - v1.002

Updated with the new US president since 2017
in Acme-MetaSyntactic-Themes version 1.055.

=item *

2017-06-12 - v1.001

Updated with the new US president since 2012
in Acme-MetaSyntactic-Themes version 1.050.

=item *

2012-05-07 - v1.000

Updated with the new US president since 2008, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-01-16

Updated (correction of a typo) by Abigail again
in Acme-MetaSyntactic version 0.57.

=item *

Introduced in Acme-MetaSyntactic version 0.52, published on December 12, 2005.

=item *

2005-10-20

Submitted by Abigail.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
Abraham_Lincoln
Andrew_Jackson
Andrew_Johnson
Barack_Obama
Benjamin_Harrison
Calvin_Coolidge
Chester_A_Arthur
Donald_Trump
Dwight_D_Eisenhower
Franklin_D_Roosevelt
Franklin_Pierce
George_H_W_Bush
George_Washington
George_W_Bush
Gerald_R_Ford
Grover_Cleveland
Harry_S_Truman
Herbert_Hoover
James_Buchanan
James_Carter
James_Garfield
James_K_Polk
James_Madison
James_Monroe
John_Adams
John_F_Kennedy
John_Quincy_Adams
John_Tyler
Joseph_R_Biden_Jr
Lyndon_B_Johnson
Martin_Van_Buren
Millard_Fillmore
Richard_M_Nixon
Ronald_Reagan
Rutherford_B_Hayes
Theodore_Roosevelt
Thomas_Jefferson
Ulysses_S_Grant
Warren_G_Harding
William_Henry_Harrison
William_Howard_Taft
William_J_Clinton
William_McKinley
Woodrow_Wilson
Zachary_Taylor
