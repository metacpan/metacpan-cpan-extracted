package Acme::MetaSyntactic::quantum;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.001';
__PACKAGE__->init();
1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::quantum - The Quantum Mechanics theme

=head1 DESCRIPTION

This theme provides the English names of the particles from 
the standard model of quantum mechanics, plus a few composite 
particles (hadrons and mesons). 

Trivia: the tau lepton was discovered in 1975 by Martin I<Perl> and a
team of 30 physicists at the Stanford Positron-Electron Asymmetric Ring.
(See L<http://www.pbs.org/wgbh/nova/elegant/part-nf.html>)

=head1 CONTRIBUTOR

Sébastien Aperghis-Tramoni.

=head1 CHANGES

=over 4

=item *

2012-05-14 - v1.001

Updated with an C<=encoding> pod command
in Acme-MetaSyntactic-Themes version 1.001.

=item *

2012-05-07 - v1.000

Received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2005-05-16

Introduced in Acme-MetaSyntactic version 0.22.

=item *

2005-03-14

List proposed by Sébastien Aperghis-Tramoni.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
proton neutron delta lambda sigma xi
b_meson d_meson eta eta_prime j_psi kaon omega phi pion rho upsilon
electron positron electron_neutrino up down
muon muon_neutrino strange charm
tau tau_neutrino bottom top
photon z_zero w_plus w_minus gluon graviton higgs
selectron electron_sneutrino up_squark down_squark
muon_slepton muon_sneutrino strange_squark charm_squark
tau_slepton tau_sneutrino bottom_squark top_squark
photino neutralino zino w_plus_wino w_minus_wino
gluino gravitino higgsino
