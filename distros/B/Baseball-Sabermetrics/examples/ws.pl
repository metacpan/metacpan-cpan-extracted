#!/usr/bin/perl

use lib '/home/victor/cpb2/Sabermetrics/lib';
use Data::Dumper;
use Baseball::Sabermetrics;


my $league = Baseball::Sabermetrics->new( league => 'CPBL', nocache => 0 );

$league->define(

ws => 'att_ws + pitch_ws + def_ws',

att_ws => 'pa > 0 ? $team->team_att_ws * marginal_rc / $team->team_total_marginal_rc : 0',

pitch_ws => 'np > 0 ? $team->team_pitchers_ws * pitcher_ws_weight / $team->team_pitchers_total_ws_weight : 0',

def_ws => 'fgame > 0 ? personal_c_ws + personal_b1_ws + personal_b2_ws + personal_b3_ws + personal_ss_ws + personal_of_ws : 0',

# Projected WS
#team_ws => '(win * 3 + tie * 1.5) * 100 / game',
team_ws => '(win * 3 + tie * 1.5)',

# ignore field effect factor(?)
m_save => '$league->r / $league->ip * ip * 1.52 - ra',

est_att_ip => 'ip + (lose - win) / 2',

m_run => 'r - $league->r / $league->ip * est_att_ip * 0.52',

team_def_ws => 'm_save / (m_run + m_save) * team_ws',

team_att_ws => 'm_run  / (m_run + m_save) * team_ws',


der => '(p_pa - h_allowed - p_so - p_bb - hb) / (p_pa - hr_allowed - p_so - p_bb - hb)',

team_pitchers_ws => sub {
    my $cl1 = $_->der_point;
    my $cl2 = ($_->k_9 + 2.5) / 7 * 200;
    my $cl3 = (($_->league->p_bb + $_->league->hb) / $_->league->ip * $_->ip - $_->p_bb - $_->hb + 200);
    my $cl4 = ($_->league->hr_allowed / $_->league->ip * $_->ip - $_->hr_allowed) * 5 + 200;
    my $cl5 = ($_->league->e + $_->league->pb / 2) / $_->league->ip * $_->ip - ($_->e + $_->pb / 2) + 100;
    my $cl6 = 100;

    ($_->cl1 + $_->cl2 + $_->cl3 + $_->cl4 + 650 + 405 * $_->win / $_->game) / (2 * $_->cl1 + $_->cl2 + $_->cl3 + $_->cl4 + $_->cl5 + $_->cl6 + 1097.5 + 405 * $_->win / $_->game) * $_->team_def_ws;
},


run_per_out => 'r / ip / 3',

outs_made => 'ab - h + dp + sf + cs',

marginal_rc => 'rc - outs_made * $league->run_per_out * 0.52 ',

team_total_marginal_rc => sub {
    my $sum = 0;
    for my $p ($_->batters) {
	$sum += $p->marginal_rc;
    }
    $sum;
},


run_per_game => 'r / ip * 9',

pitcher_zero_base => sub {
    my $A = $_->league->run_per_game * 1.52 - $_->run_per_game;
    my $p = $_->team_fielding_ws / $_->team_def_ws;
    $_->league->run_per_game * 1.52 - ($_->league->run_per_game * 1.52 - $_->run_per_game) * $p;
},

team_fielding_ws => 'team_def_ws - team_pitchers_ws',

pitcher_ws_weight => sub {
    my $cl1 = $_->team->pitcher_zero_base * $_->ip - ($_->er + 0.5 * ($_->ra - $_->er));
    my $cl2 = ($_->win * 3 - $_->lose + $_->sv) / 3;

    my $save_eq_ip = $_->sv * 3; # 中繼成功省略

    my $A = $_->h_allowed + $_->p_bb + $_->hb;
    my $B = (($_->h_allowed - $_->hr_allowed) * 1.255 + $_->hr_allowed * 4) * 0.89 + ($_->p_bb + $_->hb) * 0.56;
    my $C = $_->p_pa;
    my $tmp = $A * $B / $C;
    my $era_in_theory = $tmp >= 2.24 ? $tmp / $_->ip * 9 - 0.56 : $tmp / $_->ip * 9 * 0.75;

    my $cl3 = ($_->team->pitcher_zero_base - $era_in_theory) * $save_eq_ip;

    $cl1 + $cl2 + $cl3;
},

team_pitchers_total_ws_weight => sub {
    my $sum = 0;
    for my $p ($_->pitchers) {
	$sum += $p->pitcher_ws_weight;
    }
    $sum;
},

c_fielding_weight    => '0.19',    b1_fielding_weight => '0.06',
b2_fielding_weight   => '0.16',    b3_fielding_weight => '0.12',
ss_fielding_weight   => '0.18',    of_fielding_weight => '0.29',

team_total_claim_point =>
	'team_c_claim_point + team_b1_claim_point + team_b2_claim_point +
	team_b3_claim_point + team_ss_claim_point + team_of_claim_point',

team_c_claim_point => 'team_pos_claim_point("c")',
team_b1_claim_point => 'team_pos_claim_point("b1")',
team_b2_claim_point => 'team_pos_claim_point("b2")',
team_b3_claim_point => 'team_pos_claim_point("b3")',
team_ss_claim_point => 'team_pos_claim_point("ss")',
team_of_claim_point => 'team_pos_claim_point("of")',

team_pos_claim_point => sub {
    my $pos = shift;
    my $cp = "${pos}_claim_percentage";
    my $weight = "${pos}_fielding_weight";
    exists $_->fielding->{$pos} ? ($_->$cp - 0.2) * $_->$weight : 0;
},

team_c_ws => 'team_fielding_ws * team_c_claim_point / team_total_claim_point',
team_b1_ws => 'team_fielding_ws * team_b1_claim_point / team_total_claim_point',
team_b2_ws => 'team_fielding_ws * team_b2_claim_point / team_total_claim_point',
team_b3_ws => 'team_fielding_ws * team_b3_claim_point / team_total_claim_point',
team_ss_ws => 'team_fielding_ws * team_ss_claim_point / team_total_claim_point',
team_of_ws => 'team_fielding_ws * team_of_claim_point / team_total_claim_point',

c_claim_point => 'po + 2 * a - 8 * e + 6 * f_dp - 4 * pb - 2 * c_sb + 2 * c_cs',
b1_claim_point => 'po + 2 * a - 5 * e',
b2_claim_point => 'po + 2 * a - 5 * e + 2 * rbp("b2") + f_dp',
b3_claim_point => 'po + 2 * a - 5 * e + 2 * rbp("b3")',
ss_claim_point => 'po + 2 * a - 5 * e + 2 * rbp("ss") + f_dp',
of_claim_point => 'po + 4 * a - 5 * e + 2 * rbp("of")',

rbp => sub {
    my ($pos) = @_;
    my $team = $_->team;
    if (not exists $team->fielding->{$pos}) {
	print Dumper($_->fielding);
#print join(' ', $_->name, $pos), $/;
	die;
    }
    my $tmp = $_->po + $_->a - ($team->fielding->{$pos}->po + $team->fielding->{$pos}->a) * $_->fgame / $team->game;
    return $tmp > 0 ? $tmp : 0;
},

team_total_c_claim_point  => 'team_total_pos_claim_point("c")',
team_total_b1_claim_point  => 'team_total_pos_claim_point("b1")',
team_total_b2_claim_point  => 'team_total_pos_claim_point("b2")',
team_total_b3_claim_point  => 'team_total_pos_claim_point("b3")',
team_total_ss_claim_point  => 'team_total_pos_claim_point("ss")',
team_total_of_claim_point  => 'team_total_pos_claim_point("of")',

team_total_pos_claim_point => sub {
    my ($pos) = @_;
    my $total = 0;
    for my $p ($_->players) {
	if (exists $p->fielding->{$pos}) {
	    my $target = "${pos}_claim_point";
	    $total += $p->$target;
	}
    }
    return $total;
},

personal_fielding_ws => sub {
    my ($pos) = @_;
    if (not exists $_->fielding->{$pos}) {
	return 0;
    }
    my $team_pos_ws = "team_${pos}_ws";
    my $player_cp = "${pos}_claim_point";
    my $total_player_cp = "team_total_${pos}_claim_point";
    return $_->team->$team_pos_ws * $_->$player_cp / $_->team->$total_player_cp;
},
    
personal_c_ws => 'personal_fielding_ws("c")',
personal_b1_ws => 'personal_fielding_ws("b1")',
personal_b2_ws => 'personal_fielding_ws("b2")',
personal_b3_ws => 'personal_fielding_ws("b3")',
personal_ss_ws => 'personal_fielding_ws("ss")',
personal_of_ws => 'personal_fielding_ws("of")',

# for team
tlpop => '(po - so) / ($league->po - $league->so)',

cs_per => 'c_cs / (c_cs + c_sb)',

fielders => sub {
    my ($pos) = @_;
    return $_->{fielding}->{$pos};
},

limit => sub {
    my ($val, $max) = @_;
    return $val < 0 ? 0 : $val > $max ? $max : $val;
},

# Catchers' Claim Percentage

#c_claim_percentage => 'c_cs_grade + c_non_so_e_rate_grade + c_bunt_allowed_grade + c_pb_grade',
c_claim_percentage => '(
	limit(c_cs_grade, 50) +
	limit(c_non_so_e_rate_grade, 30) +
	limit(c_bunt_allowed_grade, 10)
) * 10 / 9',

non_so_error_per => 'e / (po + a + e - p_so)',

c_cs_grade => '25 + (cs_per - $league->cs_per) * 150',
c_non_so_e_rate_grade => '30 - 15 * non_so_error_per / $league->non_so_error_per',
c_bunt_allowed_grade => '0', # CPBL doesn't have this record
c_pb_grade => '5 + ($league->pb * tlpop - pb) / 5',

# 1st Basemans' Claim Percentage
b1_claim_percentage => '
	limit(b1_def_change_grade, 40) +
	limit(b1_e_ratio_grade, 30) +
	limit(b1_arm_grade, 20) +
	limit(err_of_b3ss_grade, 10)',

runners_on_b1 => '(h_allowed - hr_allowed) * (b1 / (h_allowed - hr_allowed)) + bb + hbp - wp - bk - pb',

est_x => 'fielders("b1")->po - 0.7 * fielders("p")->a - 0.86 * fielders("b2")->a - 0.78 * fielders("b3")->a - 0.78 * fielders("ss")->a + 0.115 * runners_on_b1 - 0.0575 * bip',

est_y => '0.1 * bip - fielders("b1")->a',

_b1_unassisted_po => 'est_x * 2 / 3 + est_y * 1 / 3',

b1_def_change_grade => '20 + (
    (_b1_unassisted_po + fielders("b1")->a + 0.0285 * lhp) - 
    ($league->_b1_unassisted_po + $league->fielders("b1")->a) * tlpop ) / 5',

bip => 'pa - bb - hr - so',

b1_e_ratio_grade => '30 - 15 * fielders("b1")->e_ratio / $league->fielders("b1")->e_ratio',

b1_arm_grade => '10 + (
	(fielders("b1")->a + fielders("ss")->f_dp / 2 - fielders("p")->po - fielders("b2")->f_dp / 2 + 0.015 * lhp) -
	($league->fielders("b1")->a + $league->fielders("ss")->f_dp / 2 - $league->fielders("p")->po - $league->fielders("b2")->f_dp / 2) ) / 5',

err_of_b3ss_grade => '10 - 5 * (fielders("b3")->e + fielders("ss")->e) / (($league->fielders("b3")->e + $league->fielders("ss")->e) * tlpop)',

# 2nd Basemans' Claim Percentage
b2_claim_percentage => '
	limit(b2_dp_grade, 40) +
	limit(b2_a_grade, 30) +
	limit(b2_e_ratio_grade, 20) +
	limit(b2_po_grade, 10)',

b2_dp_grade => '20 + (f_dp - expected_dp) / 3',
b2_a_grade => sub {
    my $A = $_->fielders('b2')->a - $_->fielders('b2')->f_dp;
    my $B = ($_->league->fielders('b2')->a - $_->league->fielders('b2')->f_dp) * $_->tlpop - $_->lhp / 35;
    return 15 + ($A - $B) / 6;
},

b2_e_ratio_grade => '24 - 14 * fielders("b2")->e_ratio / $league->fielders("b2")->e_ratio',

b2_po_grade => '
    5 + (fielders("b2")->po - (
    (po - p_so) * (fielders("b2")->po / (po - p_so)) + (p_bb / ip - $league->p_bb / $league->ip) / 13 + lhp / 32
    )) / 12',

league_lhp_ip => sub {
    my $ip = 0;
    for my $p ($_->league->left_handed_pitchers) {
	$ip += $p->ip;	
    }
    return $ip;
},

league_lhp_so => sub {
    my $so = 0;
    for my $p ($_->league->left_handed_pitchers) {
	$so += $p->p_so;	
    }
    return $so;
},

team_lhp_ip => sub {
    my $ip = 0;
    for my $p ($_->left_handed_pitchers) {
	$ip += $p->ip;	
    }
    return $ip;
},

team_lhp_so => sub {
    my $so = 0;
    for my $p ($_->left_handed_pitchers) {
	$so += $p->p_so;	
    }
    return $so;
},

lhp => '(league_lhp_ip * 3 - league_lhp_so) / ($league->ip * 3 - $league->p_so) * (ip * 3 - p_so) - (team_lhp_ip * 3 - team_lhp_so)',

expected_dp => sub {
    my $league = $_->league;
    my $X = $league->{'b1'} / ($league->h - $league->hr);
    # 中職沒有被犧牲短打的紀錄
    # 可以選擇忽略這項或是用 (聯盟SH-團隊打擊SH)/(隊伍數-1) 來代替
    my $Y = $X * ($_->h - $_->hr) + $_->bb + $_->hbp - $_->sh - $_->wp - $_->bk - $_->pb;
    my $Z = $league->{'b1'} + $league->bb + $league->hbp - $league->sh - $league->wp - $league->bk - $league->pb;
    my $W = $league->f_dp / $Z;
    return $Y * $W * ($_->a / $_->ip) / ($league->a / $league->ip);
},
sh => '0',

e_ratio => '1 - fpct',

# 3nd Basemans' Claim Percentage
b3_claim_percentage => '(
	limit(b3_a_grade, 50) +
	limit(b3_e_ratio_grade, 30) +
	limit(b3_dp_grade, 10)
) * 10 / 9',

b3_a_grade => '25 + (fielders("b3")->a - (
	    a * ($league->fielders("b3")->a / $league->a)
	)) / 4',

b3_e_ratio_grade => '15 + (
	((fielders("b3")->a + fielders("b3")->po) / league_b3_fpct - (fielders("b3")->a + fielders("b3")->po)) -
	fielders("b3")->e
	) / 2',

b3_dp_grade => '5 + (fielders("b3")->f_dp - expected_dp * ($league->fielders("b3")->f_dp / $league->f_dp)) / 2',

league_b3_fpct => '$league->fielders("b3")->fpct',

# Shortstops' Claim Percentage
ss_claim_percentage => '
	limit(ss_a_grade, 40) +
	limit(ss_dp_grade, 30) +
	limit(ss_e_ratio_grade, 20) +
	limit(ss_po_grade, 10)',

ss_a_grade => '20 + (
	(fielders("ss")->a) -
	(a * $league->fielders("ss")->a / $league->a + lhp / 100)
    ) / 4',

ss_dp_grade => '15 + (f_dp - expected_dp) / 4',

ss_e_ratio_grade => '20 - 10 * fielders("ss")->e_ratio / $league->fielders("ss")->e_ratio',

ss_po_grade => '
    5 + (fielders("ss")->po -
    ((po - p_so) * (fielders("ss")->po / (po - p_so)) + (p_bb / ip - $league->p_bb / $league->ip) / 14 + lhp / 64)
    ) / 15',


# Outfielders' Claim Percentage

of_claim_percentage => '
	limit(of_po_grade, 40) +
	limit(of_der_grade, 40) +
	limit(of_a_and_po_grade, 10) +
	limit(of_e_ration_grade, 10)',

por => 'fielders("of")->po / (po - p_so - a)',
der_point => '100 + (der - $league->der) * 2500',

of_po_grade => '20 + (por - $league->por) * 100',
of_der_grade => 'der_point * 0.24 - 9',
of_a_and_po_grade => '5 + (
	($league->fielders("of")->a + $league->fielders("of")->f_dp) * tlpop -
	(fielders("of")->a + fielders("of")->f_dp)
) / 5',
of_e_ration_grade => '10 - 5 * fielders("of")->e_ratio / $league->fielders("of")->e_ratio',

);

# TODO
sub rounded_personal_fielding_ws {
    my $total_ws = 0;
    for my $pos (keys %{$_->fielding}) {
	next if $pos eq 'p';
	for my $p ($_->team->players) {
	    next unless exists $p->fielding->{$pos};
	    my $str = "personal_${pos}_ws";
	    $total_ws += int($p->$str);
	}
    }
    $total_ws;
#    my $remain_ws = $_->team->
}

print "step 1 & 2 (projected ws)\n";
$league->report_teams qw/ name game win tie lose team_ws team_att_ws team_def_ws /;

print "\nstep 3 & 5\n";
$_->print qw/ name att_ws pitch_ws / for $league->players;

print "\nstep 4\n";
$league->report_teams qw/ name team_pitchers_ws team_fielding_ws /;

print "\nstep 6\n";
$league->report_teams qw/ name team_c_ws team_b1_ws team_b2_ws team_b3_ws team_ss_ws team_of_ws /;

print "\nstep 7 & 8\n";
$_->print qw/ name def_ws personal_c_ws personal_b1_ws personal_b2_ws personal_b3_ws personal_ss_ws personal_of_ws / for $league->players;

print "\n\n\n";

print '-' x 60, "\n";

print "           W  L  T   WS      DEF WS%\n";
for my $t ($league->teams) {
    printf "%-10s %d %d %d   %.2f  %.2f%%\n", $t->name, $t->win, $t->lose, $t->tie, $t->team_ws, $t->team_def_ws / $t->team_ws * 100;
}
print "\n";

#print Dumper($league->teams('bears')->players('黃龍義'));

#warn "## ".$league->teams('cobras')->team_total_ss_claim_point, $/;

print "TEAM\tmRunScored\tmRunCreated 投手零價值標準\n";
$_->print qw/ name m_save m_run pitcher_zero_base / for $league->teams;
print "\n";

print "TEAM\tNAME\tBAT\tPITCH\tFIELD\tTOTAL\t投手ws比重\n";
$_->print qw/ team name att_ws pitch_ws def_ws ws pitcher_ws_weight / for $league->pitchers;
print "\n";


#$_->print qw/ name c_claim_percentage b1_claim_percentage b2_claim_percentage b3_claim_percentage ss_claim_percentage of_claim_percentage / for $league->teams;


#print Dumper($league->teams('bears'));

for ($league->batters) {
    if (keys %{$_->fielding} == 0) {
	$_->print qw/ name /;
    }
}
