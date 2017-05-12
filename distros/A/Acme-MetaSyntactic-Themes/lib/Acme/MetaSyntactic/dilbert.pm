package Acme::MetaSyntactic::dilbert;
use strict;
use Acme::MetaSyntactic::List;
our @ISA = qw( Acme::MetaSyntactic::List );
our $VERSION = '1.005';
__PACKAGE__->init();

our %Remote = (
    source  => 'http://www.triviaasylum.com/dilbert/diltriv.html',
    extract => sub {
        return
            grep { $_ ne '' }
            map { s/_+/_/g; s/^_//; $_ }
            map { y!- '"/!____ !; s/\.//g; split ' ', lc }
            $_[0] =~ m!<b>([^<]+)</b>!gm;
    },
);

1;

=encoding iso-8859-1

=head1 NAME

Acme::MetaSyntactic::dilbert - The Dilbert theme

=head1 DESCRIPTION

Characters from the Dilbert daily strip.

The list (with details) is available here:
L<http://www.triviaasylum.com/dilbert/diltriv.html>.

=head1 CONTRIBUTOR

Sébastien Aperghis-Tramoni.

=head1 CHANGES

=over 4

=item *

2014-04-07 - v1.005

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.039.

=item *

2013-06-17 - v1.004

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.033.

=item *

2013-06-03 - v1.003

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.032.

=item *

2013-01-14 - v1.002

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.029.

=item *

2012-09-10 - v1.001

Updated from the source web site in Acme-MetaSyntactic-Themes version 1.018.

=item *

2012-05-07 - v1.000

Updated with new additions since November 2006, and
received its own version number in Acme-MetaSyntactic-Themes version 1.000.

=item *

2006-10-30

Updated from the source web site in Acme-MetaSyntactic version 0.98.

=item *

2006-10-23

Updated from the source web site in Acme-MetaSyntactic version 0.97.


=item *

2006-09-18

Updated from the source web site in Acme-MetaSyntactic version 0.92.

=item *

2006-09-11

Updated from the source web site in Acme-MetaSyntactic version 0.91.

=item *

2006-08-26

Updated from the source web site in Acme-MetaSyntactic version 0.89.

=item *

2006-07-10

Updated from the source web site in Acme-MetaSyntactic version 0.82.

=item *

2006-07-03

Updated from the source web site in Acme-MetaSyntactic version 0.81.

=item *

2006-06-26

Updated from the source web site in Acme-MetaSyntactic version 0.80.

=item *

2006-06-12

Updated from the source web site in Acme-MetaSyntactic version 0.78.

=item *

2006-04-03

Updated from the source web site in Acme-MetaSyntactic version 0.68.

=item *

2006-02-06

Updated from the source web site in Acme-MetaSyntactic version 0.60.

=item *

2006-01-16

Updated from the source web site in Acme-MetaSyntactic version 0.57.

=item *

2005-12-19

Updated from the source web site in Acme-MetaSyntactic version 0.53.

=item *

2005-12-12

Updated from the source web site in Acme-MetaSyntactic version 0.52.

=item *

2005-12-05

Updated from the source web site in Acme-MetaSyntactic version 0.51.

=item *

2005-11-21

Remote list added and theme updated in Acme-MetaSyntactic version 0.49.

=item *

2005-07-04

Updated with a brand new list in Acme-MetaSyntactic version 0.29.

=item *

2005-03-28

Duplicate removed in Acme-MetaSyntactic version 0.15.

=item *

2005-01-14

Introduced in Acme-MetaSyntactic version 0.03.

=back

=head1 SEE ALSO

L<Acme::MetaSyntactic>, L<Acme::MetaSyntactic::List>.

=cut

__DATA__
# names
al alice allen ann anne anne_l_retentive antina asok aunt_helen
avery_wong bad_ed barry becky ben betty beverly big_boss big_ed bill
bob bob_flabeau bob_weaselton bobby bobby_mcnewton bobby_noober boron
bottleneck_bill brad bradley brenda brenda_utthead brent brian bruce
bucky bud buff_bufferman camping_carl carl carlos carol cheryl chuck
cliffy co_op_employee connie cyrus_the_virus dan dave dawn dee_alamo
dilbert doctor_wolfington dogbert donald dorie doug ed eddy edfred edna
edward_lester_mann eileen ellen ernie flossie floyd floyd_remora
fred freshy_q gustav hammerhead_bob harold harry_middlepart helen
holly_hollister incredulous_ed irene irv irv_klepfurd jack janet
jennifer jenny_dworkin jim jimmy jittery_jeff john_smith johnson jose
juan_delegator judy karl kay_and_clem_bovinski ken kronos kudos larry lars
laura lauren laurie les lisa liz lola loopy loud_howard lulu mahoney
mary matt medical_mel mel michael_t_suit mike millard_bullrush milt ming
miss_cerberus miss_mulput miss_pennington mister_catbert mister_goodenrich
mittens mo mom monty mordac mother_nature motivation_fairy mr_death
mr_dork myron nardo neal_snow ned nelson nervous_ed norma norman
parrot_man paul paul_ooshen paul_tergeist peeved_eve peri_noid
pete_peters peter phil phil_de_cube phil_from_heck pigboy plywoodboss
pointy_haired_carl pointy_haired_pete proxis queen_bee_of_marketing
randy ratbert ray rex richard rick robert_roberts roboboss rocky ron
ruebert rufus_t_skwerrel russell sally sam_grooper sharon son_of_a_boss
sophie stan susan sven techno_bill technology_buddha ted ted_griffin
the_boss tim timmy tina toby todd tom too_helpful_guy topper toxic_tom
traylor uncle_albert uncle_max uncle_ned upholsterygeist virginia
waldo wally walter wendel wendy will willy wilson wilt_gandhi winston
world_s_smartest_garbage_man yergi yorgi yugi yvonne zenox zimbu zoltar
tex flashy petricia tim_zumph earl lefty sourpuss wendel_j_stone_iv
vijay exactly_man alan andy
lou mister_serdecisions sandeep
patty smokin_jim betty_the_bulldozer
amber_dextrous stinky_pete
phil_o_dendron
steve
lyin_john
mindy
robbie_the_frightening_hobo
admiral_b_tang_b_tang albert amber angry_jack antimatter_dilbert
awesome_bob beth brendan_and_brandon burt_nount darryl disgruntled_doug
eddie elrod erin gabe graybeard helen_fry henry humphrey ixpu jeff
jenny jesus keith kim logan lying_larry matt_the_temp morgan mort
mutobu_the_impaler nancy neo old_johannsen oobanoobah pete raj rodney
ronald rubbin_robin ruth sarah scott shelly silent_gary sue_boysenberry
tom_jackson trixie victor vlad wolfgang
jb_hopper
stanky_bathurd
wulf
mullah_john_smith
