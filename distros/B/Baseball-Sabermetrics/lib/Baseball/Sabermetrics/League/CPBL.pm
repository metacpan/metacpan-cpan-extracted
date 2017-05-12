package Baseball::Sabermetrics::League::CPBL;

use LWP::UserAgent;
use HTML::TableExtract;
use Encode qw/ encode decode /;
use Data::Serializer;
use constant CACHEFILE => 'cachefile';

use strict;

sub new
{
    my ($class, %config) = @_;
    my $data = Data::Serializer->new();

    if (-f CACHEFILE && !$config{nocache}) {
	my $mtime = (stat CACHEFILE)[9];
	# just a heuristic for speeding up
	if ($config{usecache} || time - $mtime < 6 * 3600) {
	    print STDERR "cache hit\n";
	    return $data->retrieve(CACHEFILE);
	}
    }

    my $league = {};
    my $teams = $league->{teams} = {};

    $teams->{bulls} = { code => 'B02', name => 'bulls', company => "興農" };
    $teams->{cobras} = { code => 'G01', name => 'cobras', company => "誠泰" };
    $teams->{elephants} = { code => 'E01', name => 'elephants', company => "兄弟" };
    $teams->{whales} = { code => 'W01', name => 'whales', company => "中信" };
    $teams->{lions} = { code => 'L01', name => 'lions', company => "統一" };
    $teams->{bears} = { code => 'A02', name => 'bears', company => "La New" };

    extract_score($league, "http://www.cpbl.com.tw/Score/FightScore.aspx");

    for my $team (values %$teams) {
	print "Fetching records of team $team->{name}\n";

	my $code = $team->{code};
	$team->{players} = {};

	extract_record(
		$team,
		"http://www.cpbl.com.tw/teams/Team_Pitcher.aspx?Tno=$code",
		[qw/ name p_game gs _ _ win lose tie sv bs hld _ cg sho /]);
	extract_record(
		$team,
		"http://www.cpbl.com.tw/teams/Team_Pitcher.aspx?Tno=$code&page=2",
		[qw/ name ip p_pa np h_allowed hr_allowed sh_allowed sf_allowed p_bb p_ibb hb p_so wp bk ra er /]);

	extract_record(
		$team,
		"http://www.cpbl.com.tw/teams/Team_Hitter.aspx?Tno=$code",
		[qw/ name game pa ab rbi r h 1b 2b 3b hr tb dp /]);
	extract_record(
		$team,
		"http://www.cpbl.com.tw/teams/Team_Hitter.aspx?Tno=$code&page=2",
		[qw/ name sh sf 4ball ibb bb so sb cs /]);

	# fgame stards for fielding games
	extract_fielding($team, "http://www.cpbl.com.tw/teams/Team_defend.aspx?Tno=$code");


	# fix something up
	for my $p (values %{$team->{players}}) {
	    $p->{ip} = int($p->{ip}) + ($p->{ip} - int $p->{ip}) * 10 / 3
		if exists $p->{ip};

	    if (exists $p->{'4ball'}) {
		#$p->{hbp} = $p->{bb} - $p->{ibb} - $p->{'4ball'};
		# XXX I'm not sure whether ibb is counted in bb in cpbl.com.tw
		$p->{hbp} = $p->{bb} - $p->{'4ball'};
		delete $p->{'4ball'};
	    }
	    else {
		# XXX I'm not sure whether ibb is counted in bb in cpbl.com.tw
		#$p->{p_bb} = $p->{p_bb} + $p->{p_ibb};
	    }
	}
    }

    $data->store($league, CACHEFILE);

    $league;
}

sub get_content
{
    my $url = shift;
    my $page = LWP::UserAgent->new();
    my $ua = $page->get($url);
    if (not $ua->is_success) {
	die "failed to fetch url $url";
    }
    return $ua->content;
}

sub get_table_in_html
{
    my ($page, $attribs) = @_;

    my $t;
    if (exists $attribs->{cpb2_choose_table}) {
	$t = $attribs->{cpb2_choose_table};
	delete $attribs->{cpb2_choose_table};
    }
    else {
	$t = 0;
    }

    my $te = HTML::TableExtract->new(attribs => $attribs);
    $te->parse($page =~ /^http/ ? get_content($page) : $page);

    my @tables = $te->tables;
    die "No table is found" unless @tables;
    return $tables[$t];
}

sub extract_table_record
{
    my ($page, $attribs, $hash, $n_dummy, $keys) = @_;
    my $table = get_table_in_html($page, $attribs);
    my @rows = $table->rows;

    shift @rows for (1 .. $n_dummy);

    my $i = 0;
    while ($keys->[$i] eq '_') {
	++$i;
    }

    for my $p_row (@rows) {
	my @col = @$p_row;
	$col[$i] =~ s/\s//g unless $keys->[$i] eq 'company';
	$hash->{$col[$i]} = {} unless exists $hash->{$col[$i]};
	my $h = $hash->{$col[$i]};

	for ($i + 1 ..@$keys - 1) {
	    my $key = $keys->[$_];
	    if ($key eq '_') {
		next;
	    }
	    $h->{$key} = $col[$_];
	}
    }
}

sub extract_score
{
    my ($league, $url) = @_;
    my $hash = {};
    extract_table_record($url, { class => 'Report_Table_score', cpb2_choose_table => 2 }, $hash, 2,
	    [qw/ company game score /]);
    for my $key (keys %$hash) {
	my $name = $key;
	$name =~ s/\d\.//;
	my $team = $hash->{$key};
	my ($t) = grep { $_->{company} eq $name } values %{$league->{teams}};
	$t->{game} = $team->{game};
	($t->{win}, $t->{tie}, $t->{lose}) = ($team->{score} =~ /(\d+)勝(\d+)和(\d+)敗/);
    }
}

sub extract_record
{
    my ($team, $url, $cols) = @_;
    extract_table_record($url, { class => 'Report_Table' }, $team->{players}, 2, $cols);
}

sub fix_cpbls_bug
{
    my ($team, $ids) = @_;
    my $content = get_content("http://www.cpbl.com.tw/teams/Team_Hitter.aspx?Tno=$team->{code}");
    my %hash = @$ids;
    my %hash2 = $content =~ m!href="\.\./personal_Rec/pbat_personal\.aspx\?Pno=([^"]+)">([^<]+)<!gs;
    my %hash3 = (%hash, %hash2);
    @$ids = %hash3;
}

sub extract_fielding
{
    my ($team, $url) = @_;

    my $content = get_content($url);
    my @ids = $content =~ m!href="\.\./personal_Rec/pbat_personal\.aspx\?Pno=([^"]+)">([^<]+)<!gs;
    fix_cpbls_bug($team, \@ids);

    while (@ids) {
	my $id = shift @ids;
	my $name = shift @ids;
	$name =~ s/\s//g;
	my $p = $team->{players}->{$name};
	my $year = 2006;
	my $hash = {};
	extract_table_record("http://www.cpbl.com.tw/personal_Rec/pbat_personal.aspx?Pno=$id", { class => 'Report_Table_pdf' }, $hash, 1,
		[qw/ year _ fgame tc po a e f_dp tp pb c_cs c_sb _ /]);
	my $h = $hash->{$year - 1989};
	next unless $h;
	while (my ($key, $value) = each %$h) {
	    $p->{$key} = $value;
	}

	$hash = {};
	extract_table_record("http://www.cpbl.com.tw/personal_Rec/pdf_detail.aspx?pbyear=$year&Pno=$id", { class => 'Report_Table_pdf' }, $hash, 1,
		[qw/ _ pos fgame tc po a e f_dp tp pb c_cs c_sb _ /]);

	while (my ($key, $value) = each %$hash) {
	    my %posname = ( '投手' => 'p', '捕手' => 'c', '一壘' => 'b1', '二壘' => 'b2', '三壘' => 'b3', '游擊' => 'ss', '左外野' => 'lf', '中外野' => 'cf', '右外野' => 'rf' );
	    $p->{fielding}->{$posname{$key}} = $value;
	}

	$content = get_content("http://www.cpbl.com.tw/personal_Rec/pbat_personal.aspx?Pno=$id");
	$content =~ m!投 打：<span id="lbl_bpcustom">(.+)</span>!;
	my $type = $1;
	$p->{bio} = {};
	if ($type =~ /開弓/) {
	    $p->{bio}->{bats} = "switch";
	    $p->{bio}->{throws} = $type =~ /左投/ ? 'left' : 'right';
	}
	elsif ($type =~ /(.+)打(.+)投/) {
	    $p->{bio}->{bats} = $1 eq "左" ? 'left' : 'right';
	    $p->{bio}->{throws} = $2 eq "左" ? 'left' : 'right';
	}
	else {
	    die "unrecognized format: $type";
	}
    }
}

1;
