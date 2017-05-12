package Acme::MetaSyntactic::pumpkings;
use strict;
use Acme::MetaSyntactic::MultiList;
our @ISA = qw( Acme::MetaSyntactic::MultiList );
our $VERSION = '1.000';
__PACKAGE__->init();
1;

=head1 NAME

Acme::MetaSyntactic::pumpkings - The pumpkings theme

=head1 DESCRIPTION

This is the list of the Perl Pumpkings, as listed in perlhist(1).

The names are the pumpkings PAUSE id (except for C<NI-S>, which was
changed to C<NI_S>).

=head1 CONTRIBUTOR

Rafael Garcia-Suarez.

=head1 CHANGES

=over 4

=item *

2012-05-07 - v1.000

Updated with new pumpkings since 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-05-15

Turned into a multilist (separate lists for different versions of Perl)
by Abigail in Acme-MetaSyntactic version 0.74.

=item *

2005-03-21

Introduced in Acme-MetaSyntactic version 0.14.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::MultiList>.

=cut

__DATA__
# default
perl5
# names perl0
lwall
# names perl1
lwall mschwern rclamp
# names perl2
lwall
# names perl3
lwall
# names perl4
lwall andyd
# names perl5
lwall andyd tomc cbail ni_s chips timb micb gsar gbarr
jhi hvds rgarcia nwclark lbrocard jesse rjbs
dapm mstrout shay miyagawa bingos dagolden flora zefram
avar stevan drolsky corion abigail
