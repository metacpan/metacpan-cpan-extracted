package Baseball::Sabermetrics::League::CPB2;

use Convert::Binary::C;
use Encode qw/ encode decode /;

use strict;

sub new
{
    my ($class, %config) = @_;
    my $league = {};
    my $c = Convert::Binary::C->new(ByteOrder => 'LittleEndian')
	->parse(join '', <DATA>);

    my $file = $config{file};
    $file ||= '_LEAGUE';
    open FILE, '<', $file or die "$file: $!";
    binmode FILE, ':byte';

    my $teams = $league->{teams} = {};
    my $players = $league->{players} = {};

    my $bin;
    read FILE, $bin, 1024 or die;
    for (0..5) {
	read FILE, $bin, (256 * 25) or die;
	my $t = $c->unpack('Team', $bin);
	my $name = (qw/ elephants lions dragons bears eagles tigers /)[$_];
	$teams->{$name} = $t;
    }

    while (read FILE, $bin, 256) {
	die if length $bin != 256;
	my $p = $c->unpack('Player', $bin);
	next if $p->{team} > 5; # XXX unregistered player

	$p->{name} = decode "big5", pack 'C[6]', @{$p->{name}};
	$p->{name} =~ s/ //g;
	$p->{name} = encode "utf8", $p->{name};

	$p->{team} = $teams->{(qw/ elephants lions dragons bears eagles tigers /)[$p->{team}]};

	$p->{'2b'} = $p->{b2}; delete $p->{b2};
	$p->{'3b'} = $p->{b3}; delete $p->{b3};
	$p->{'1b'} = $p->{h} - $p->{'2b'} - $p->{'3b'} - $p->{hr};

	$p->{ip} /= 3;

	$p->{team}->{players}->{$p->{name}} = $p;
    }
    close FILE;

    return $league;
}

1;

__DATA__
struct Player {
    unsigned char name[7];
    unsigned char number;
    unsigned char team;
    unsigned short salary;
    unsigned char year, month, day;
    unsigned char stamina;
    unsigned char rest;
    unsigned char control;
    unsigned char speed;
    unsigned char ball1, bball2, ball3, ball6, ball9, ball8, ball7, ball4;
    unsigned char photo;
    unsigned char pad0;
    unsigned char growth;
    unsigned char power;
    unsigned char place;
    unsigned char country_pitchposture;

    unsigned char orientation_hitposture;
    unsigned char skin_hair;
    unsigned char glove_bat;
    unsigned char bunt_run;
    unsigned char judge_defence;
    unsigned char throw_hitrectangle;
    unsigned char pitchertype;
    unsigned char battertype;
    unsigned char feature_level;
    unsigned char goodat;
    unsigned char hr_show, rbi_show, sb_show, win_show, lose_show, save_show;
    short ba_show, era_show;
    int pad2[5];
    short pad3;
    unsigned char bat_def, bat_att;
    int pad4;
    short pad5;
    short id;

    short pitch_game;
    short _gs, gs;
    short _cg, cg;
    short _sho, sho;
    short _win, win;
    short _lose, lose;
    short _save, save;
    short _ip, ip;
    short _np, np;
    short _p_pa, p_pa;
    short _h_allowed, h_allowed;
    short _r_allowed, ra;
    short _setup, setup;
    short _hr_allowed, hr_allowed;
    short _p_bb, p_bb;
    short _p_so, p_so;
    short _er, er;

    short _g, g;
    short _pa, pa;
    short _ab, ab;
    short _rbi, rbi;
    short _r, r;
    short _h, h;
    short _b2, b2;
    short _b3, b3;
    short _hr, hr;
    short _tb, tb;
    short _dp, dp;
    short _sh, sh;
    short _sf, sf;
    short _bb, bb;
    short _hbp, hbp;
    short _so, so;
    short _sb, sb;
    short _cs, cs;
    short _e, e;
    short _def, def;
    short _c_cs, c_cs;
    short _sba, sba;
    short _rbi_ab, rbi_ab;
    short _rbi_h, rbi_h;
    short _rbi_hr, rbi_hr;
    short _rbi_rbi, rbi_rbi;
};

struct Team {
    short date;
    short pad1;
    unsigned int fund;
    int pad2[12];
    unsigned short win, total_win;
    unsigned short lose, total_lose;
    unsigned short tie, total_tie;
    unsigned short game, total_game;
    int pad3[46];

    char pad4[256 * 24];
};
