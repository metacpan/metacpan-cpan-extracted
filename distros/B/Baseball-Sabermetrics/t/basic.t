#!perl

use Test::More qw/ no_plan /;

use lib '/home/victor/cpb2/Sabermetrics/lib';

BEGIN { use_ok('Baseball::Sabermetrics'); }

my $league = Baseball::Sabermetrics->new(data => {
    teams => {
	Cardinals => {
#	    win => 10, lose => 5, tie => 0,
	    players => {
		'Albert Pujols' => {
		    name => 'Albert Pujols', ab => 591, r => 129,
		    h => 195, '2b' => 38, '3b' => 2, hr => 41, rbi => 117,
		    tb => 360, bb => 97, so => 65, sb => 16, cs => 2,
		    sf => 3, sh => 0, hbp => 9, ibb => 27, dp => 19, pa => 700,
		}
	    },
	},
	Yankees => {
	    players => {
		'Chien-Ming Wang' => {
		    win => 8, lose => 5, game => 18, ip => 116.333333333,
		    h_allowed => 113, r_allowed => 58, er => 52,
		    hr_allowed => 9, hb => 6, p_bb => 32, p_so => 47,
		    ibb => 3, go => 220, ao => 77,
		}
	    }
	},
	faketeam => {
	    players => {
		'batter1' => { pa => 100, ab => 80, h => 25, so => 18, bb => 18, hbp => 1, sf => 1, tb => 40, },
		'batter2' => { pa => 100, ab => 85, h => 20, so => 8, bb => 20, hbp => 2, sf => 3, tb => 40, },
		'batter3' => { pa => 100, ab => 75, h => 20, so => 20, bb => 15, hbp => 2, sf => 1, tb => 30, },
		'batter4' => { pa => 100, ab => 85, h => 22, so => 10, bb => 10, hbp => 2, sf => 3, tb => 40, },
		'batter5' => { pa => 100, ab => 87, h => 24, so => 15, bb => 20, hbp => 1, sf => 0, tb => 45, },
	    }
	}
    },
});

my $p = $league->players('Albert Pujols');
is(round($p->ba, 3),  0.330, 'BA');
is(round($p->obp, 3), 0.430, 'OBP');
is(round($p->slg, 3), 0.609, 'SLG');
is(round($p->ops, 3), 1.039, 'OPS');

$league->define( wpct => 'win / (win + lose)' );

my $w = $league->players('Chien-Ming Wang');
is(round($w->era, 2), 4.02, 'ERA');
#is($w->go_ao, 3.08, 'GO/AO');
is(round($w->whip, 2), 1.25, 'WHIP');
is(round($w->wpct, 3), 0.615, 'WPCT');
is(round($w->k_bb, 2), 1.47, 'K/BB');
is(round($w->k_9, 2), 3.64, 'K/9');
is(round($w->bb_9, 2), 2.48, 'BB/9');

my $ft = $league->teams('faketeam');
$ft->report_batters(qw/ name ba obp slg isop /);
is(($ft->top('players', 1, 'ba'))[0]->name, 'batter1', 'top BA');
is(($ft->top('players', 1, 'obp'))[0]->name, 'batter5', 'top OBP');
is(($ft->top('players', 1, 'slg'))[0]->name, 'batter5', 'top SLG');
is(($ft->top('players', 1, 'isop'))[0]->name, 'batter5', 'top ISOP');

sub round
{
    my $d;
    ($_, $d) = @_;
    if (s/(\d+\.\d{$d})(\d)\d*/$1/) {
	print "$_\n";
	$_ += 0.1 ** $d if $2 >= 5;
    }
    return $_;
}
