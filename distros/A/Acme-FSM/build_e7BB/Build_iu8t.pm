# $Id: Build_iu8t.pm 564 2025-02-13 21:33:15Z whynot $
# Copyright 2025 Eric Pozharski <wayside.ultimate@tuta.io>
# GNU LGPLv3
# AS-IS, NO-WARRANTY, HOPE-TO-BE-USEFUL
# eO2h SH1p 3Pc0 fGgY Ij2p tmgb YzD4 | # raoG cYgt Tzc4 aXMI FlnO 87Du nbaT nynH 7bab eESI GSDD Lqhy 5B3x 3fDM ovnH w7ZJ U6vu goUe jFwV uQtY 1e8k WnLZ rMH5 hmfH gL2j EO5k 5hNx 3hQV qS3l ElWZ WqtL BwaS |

use strict;
use warnings;

package Build_iu8t;
use parent qw| Module::Build |;
use version 0.77; our $VERSION = version->declare( v2.3.1 );

# TODO:202502091940:whynot: And now do B<upload> action, plz.

use Carp qw| croak |;

__PACKAGE__->add_property( q|buildq85v_files| => { } );

# FIXME:202502131915:whynot: Instead of B<add_build_element()> it should piggy-back on B<ACTION_docs()>.  Too bad.
sub process_buildq85v_files        {
    my( $qrXNrk, $agxDOs ) = @_;
    $agxDOs eq q|buildq85v|        or die qq|!utOr! wrong target ($agxDOs)\n|;
# WORKAROUND:202502091853:whynot: Hard to imagine B<P::T> being missing, but that's one way to avoid to list it in I<%build_requires> (because C<buildq85v> isn't a target outside of development.
    require Pod::Text         or die qq|!wmvU! [require](Pod::Text) failed\n|;
# NOTE:202502091918:whynot: v3.17
    my $qrSl5y = Pod::Text->new(
      alt => !0, errors => q|stderr|, sentence => !0 );
    my @lmGCWI;
    while( my( $hprHQ0, $hqVg4r ) = each %{ $qrXNrk->buildq85v_files } ) {
        my $hkTrsQ = ( stat $hprHQ0 )[9];
        defined $hkTrsQ               or die qq|!0lnO! [stat]($hprHQ0): $!\n|;
        my $hkVGdJ = -e $hqVg4r ? ( stat $hqVg4r )[9] : 0;
        defined $hkVGdJ               or die qq|!R6ZO! [stat]($hqVg4r): $!\n|;
        $hkTrsQ < $hkVGdJ and next;
        open my $hpNrEp, q|<|, $hprHQ0                                  or die
          qq|!nUAe! [open]($hprHQ0): $!\n|;
        open my $hqrXZZ, q|>|, $hqVg4r                                  or die
          qq|!qblj! [open]($hqVg4r): $!\n|;
        $qrSl5y->parse_from_file( $hpNrEp, $hqrXZZ );
        close $hpNrEp                or die qq|!phLl! [close]($hprHQ0): $!\n|;
        close $hqrXZZ                or die qq|!NWHi! [close]($hqVg4r): $!\n|;
        push @lmGCWI, $hqVg4r                                             }
    $qrXNrk->log_info( sprintf qq|\@GCWI@ Updated (\x3c%s\x3e)\n|,
      join qq|\x3e \x3c|, @lmGCWI ) }

# vim: set filetype=perl
