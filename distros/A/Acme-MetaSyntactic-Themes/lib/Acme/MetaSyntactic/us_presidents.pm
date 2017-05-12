package Acme::MetaSyntactic::us_presidents;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.000';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.whitehouse.gov/history/presidents/index.html',
    extract => sub {
        return
            map { y'- .'_'; s/_+/_/g; s/\b(.)/uc $1/eg; $_ }
            grep { !/^(?:BEGIN|END)$/ }
            $_[0] =~ /"Portrait of ([^"]+)"/g;
    }
);

1;

=head1 NAME

Acme::MetaSyntactic::us_presidents - The presidents of the USA theme

=head1 DESCRIPTION

Presidents of the USA.

This list is based on the official White House list, available at:
L<http://www.whitehouse.gov/history/presidents/index.html>.

=head1 CONTRIBUTOR

Abigail

=head1 CHANGES

=over 4

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
Chester_Arthur
Dwight_Eisenhower
Franklin_D_Roosevelt
Franklin_Pierce
George_H_W_Bush
George_W_Bush
George_Washington
Gerald_Ford
Grover_Cleveland
Harry_S_Truman
Herbert_Hoover
James_Buchanan
James_Garfield
James_Madison
James_Monroe
James_Polk
Jimmy_Carter
John_Adams
John_Kennedy
John_Quincy_Adams
John_Tyler
Lyndon_Johnson
Martin_Van_Buren
Millard_Fillmore
Richard_Nixon
Ronald_Reagan
Rutherford_Hayes
Theodore_Roosevelt
Thomas_Jefferson
Ulysses_Grant
Warren_Harding
William_Clinton
William_Henry_Harrison
William_Howard_Taft
William_McKinley
Woodrow_Wilson
Zachary_Taylor
