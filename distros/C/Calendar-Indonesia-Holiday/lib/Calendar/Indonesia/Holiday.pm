package Calendar::Indonesia::Holiday;

our $DATE = '2017-07-31'; # DATE
our $VERSION = '0.31'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';
#use Log::ger;

use DateTime;
use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Perinci::Sub::Util qw(err gen_modified_sub);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_id_holidays
                       enum_id_workdays
                       count_id_workdays
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'List Indonesian public holidays',
};

my @fixed_holidays = (
    my $newyear = {
        day        =>  1, month =>  1,
        ind_name   => "Tahun Baru",
        eng_name   => "New Year",
        tags       => [qw/international/],
    },
    my $indep = {
        day        => 17, month =>  8,
        ind_name   => "Proklamasi",
        eng_name   => "Declaration Of Independence",
        tags       => [qw/national/],
    },
    my $christmas = {
        day        => 25, month => 12,
        ind_name   => "Natal",
        eng_name   => "Christmas",
        tags       => [qw/international religious religion=christianity/],
    },
    my $labord = {
        day         => 1, month => 5,
        year_start  => 2014,
        ind_name    => "Hari Buruh",
        eng_name    => "Labor Day",
        tags        => [qw/international/],
        decree_date => "2013-04-29",
        decree_note => "Labor day becomes national holiday since 2014, ".
            "decreed by president",
    },
    my $pancasilad = {
        day         => 1, month => 6,
        year_start  => 2017,
        ind_name    => "Hari Lahir Pancasila",
        eng_name    => "Pancasila Day",
        tags       => [qw/national/],
        decree_date => "2016-06-01",
        decree_note => "Pancasila day becomes national holiday since 2017, ".
            "decreed by president (Keppres 24/2016)",
        # ref: http://www.kemendagri.go.id/media/documents/2016/08/03/k/e/keppres_no.24_th_2016.pdf
    },
);

sub _add_original_date {
    my ($r, $opts) = @_;
    if ($opts->{original_date}) {
        $r->{ind_name} .= " (diperingati $opts->{original_date})";
        $r->{eng_name} .= " (commemorated on $opts->{original_date})";
    }
}

sub _h_chnewyear {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Tahun Baru Imlek".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    $r->{eng_name}    = "Chinese New Year".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/international calendar=lunar/];
    ($r);
}

sub _h_mawlid {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Maulid Nabi Muhammad";
    $r->{eng_name}    = "Mawlid";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [qw/Maulud/];
    $r->{eng_aliases} = ["Mawlid An-Nabi"];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=islam calendar=lunar/];
    ($r);
}

sub _h_nyepi {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Nyepi".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    $r->{eng_name}    = "Nyepi".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = ["Tahun Baru Saka"];
    $r->{eng_aliases} = ["Bali New Year", "Bali Day Of Silence"];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=hinduism calendar=saka/];
    ($r);
}

sub _h_goodfri {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Jum'at Agung";
    $r->{eng_name}    = "Good Friday";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = ["Wafat Isa Al-Masih"];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=christianity/];
    ($r);
}

sub _h_vesakha {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Waisyak".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    $r->{eng_name}    = "Vesakha".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
    $r->{eng_aliases} = ["Vesak"];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=buddhism/];
    ($r);
}

sub _h_ascension {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Kenaikan Isa Al-Masih";
    $r->{eng_name}    = "Ascension Day";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=christianity/];
    ($r);
}

sub _h_isramiraj {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Isra Miraj";
    $r->{eng_name}    = "Isra And Miraj";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=islam calendar=lunar/];
    ($r);
}

sub _h_eidulf {
    my ($r, $opts) = @_;
    $opts //= {};
    my $ind_name0     = "Idul Fitri".
        ($opts->{hyear} ? " $opts->{hyear}H":"");
    my $eng_name0     = "Eid Ul-Fitr".
        ($opts->{hyear} ? " $opts->{hyear}H":"");
    $r->{ind_name}    = $ind_name0.($opts->{day} ? ", Hari $opts->{day}":"");
    $r->{eng_name}    = $eng_name0.($opts->{day} ? ", Day $opts->{day}":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = ["Lebaran"];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=islam calendar=lunar/];
    ($r);
}

sub _h_eidula {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Idul Adha";
    $r->{eng_name}    = "Eid Al-Adha";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = ["Idul Kurban"];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/religious religion=islam calendar=lunar/];
    ($r);
}

sub _h_hijra {
    my ($r, $opts) = @_;
    $opts //= {};
    $r->{ind_name}    = "Tahun Baru Hijriyah".
        ($opts->{hyear} ? " $opts->{hyear}H":"");
    $r->{eng_name}    = "Hijra".
        ($opts->{hyear} ? " $opts->{hyear}H":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = ["1 Muharam"];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/calendar=lunar/];
    ($r);
}

sub _h_lelection {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Pemilu Legislatif (Pileg)";
    $r->{eng_name}    = "Legislative Election";
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/political/];

    for (qw(decree_date decree_note)) {
        $r->{$_} = $opts->{$_} if defined $opts->{$_};
    }
    ($r);
}

sub _h_pelection {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Pemilu Presiden (Pilpres)";
    $r->{eng_name}    = "Presidential Election";
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/political/];

    for (qw(decree_date decree_note)) {
        $r->{$_} = $opts->{$_} if defined $opts->{$_};
    }
    ($r);
}

sub _h_jrelection {
    my ($r, $opts) = @_;
    $r->{ind_name}    = "Pilkada Serentak";
    $r->{eng_name}    = "Joint Regional Election";
    $r->{is_holiday}  = 1;
    $r->{tags}        = [qw/political/];

    for (qw(decree_date decree_note)) {
        $r->{$_} = $opts->{$_} if defined $opts->{$_};
    }
    ($r);
}

sub _jointlv {
    my ($r, $opts) = @_;
    $opts //= {};
    my $h = $opts->{holiday};
    $r->{ind_name}        = "Cuti Bersama".
        ($h ? " (".($h->{ind_name0} // $h->{ind_name}).")": "");
    $r->{eng_name}        = "Joint Leave".
        ($h ? " (".($h->{eng_name0} // $h->{eng_name}).")": "");
    $r->{ind_aliases}     = [];
    $r->{eng_aliases}     = [];
    $r->{is_joint_leave}  = 1;
    $r->{tags}            = [];
    ($r);
}

# can operate on a single holiday or multiple ones
sub _make_tentative {
    for my $arg (@_) {
        push @{ $arg->{tags} }, 'tentative' unless $arg->{tags} ~~ 'tentative';
    }
    @_;
}

sub _make_jl_tentative {
    my ($holidays) = @_;
    for (@$holidays) {
        _make_tentative($_) if $_->{is_joint_leave};
    }
    $holidays;
}

sub _expand_dm {
    $_[0] =~ m!(\d+)[-/](\d+)! or die "Bug: bad dm syntax $_[0]";
    return (day => $1+0, month => $2+0);
}

my %year_holidays;

# decreed ?
{
    my $eidulf2002;
    $year_holidays{2002} = [
        _h_chnewyear ({_expand_dm("12-02")}, {hyear=>2553}),
        _h_eidula    ({_expand_dm("23-02")}, {hyear=>1422}),
        _h_hijra     ({_expand_dm("15-03")}, {hyear=>1423}),
        _h_goodfri   ({_expand_dm("29-03")}),
        _h_nyepi     ({_expand_dm("13-04")}, {hyear=>1924}),
        _h_ascension ({_expand_dm("09-05")}),
        _h_mawlid    ({_expand_dm("25-05")}, {hyear=>1423, original_date=>'2003-05-14'}),
        _h_vesakha   ({_expand_dm("26-05")}, {hyear=>2546}),
        _h_isramiraj ({_expand_dm("04-10")}),
        ($eidulf2002 =
        _h_eidulf    ({_expand_dm("06-12")}, {hyear=>1424, day=>1})),
        _h_eidulf    ({_expand_dm("07-12")}, {hyear=>1424, day=>2}),

        _jointlv     ({_expand_dm("05-12")}, {holiday=>$eidulf2002}),
        _jointlv     ({_expand_dm("09-12")}, {holiday=>$eidulf2002}),
        _jointlv     ({_expand_dm("10-12")}, {holiday=>$eidulf2002}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed nov 25, 2002
{
    my $eidulf2003;
    $year_holidays{2003} = [
        _h_chnewyear ({_expand_dm("01-02")}, {hyear=>2554}),
        _h_eidula    ({_expand_dm("12-02")}, {hyear=>1423}),
        _h_hijra     ({_expand_dm("03-03")}, {hyear=>1424, original_date=>'2003-03-04'}),
        _h_nyepi     ({_expand_dm("02-04")}, {hyear=>1925}),
        _h_goodfri   ({_expand_dm("18-04")}),
        _h_mawlid    ({_expand_dm("15-05")}, {original_date=>'2003-05-14'}),
        _h_vesakha   ({_expand_dm("16-05")}, {hyear=>2547}),
        _h_ascension ({_expand_dm("30-05")}, {original_date=>'2003-05-29'}),
        _h_isramiraj ({_expand_dm("22-09")}, {original_date=>'2003-09-24'}),
        ($eidulf2003 =
        _h_eidulf    ({_expand_dm("25-11")}, {hyear=>1425, day=>1})),
        _h_eidulf    ({_expand_dm("26-11")}, {hyear=>1425, day=>2}),

        _jointlv     ({_expand_dm("24-11")}, {holiday=>$eidulf2003}),
        _jointlv     ({_expand_dm("27-11")}, {holiday=>$eidulf2003}),
        _jointlv     ({_expand_dm("28-11")}, {holiday=>$eidulf2003}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
    my $indep2003 = clone($indep); $indep2003->{day} = 18;
    _add_original_date($indep2003, {original_date=>'2003-08-17'});
}

# decreed jul 17, 2003
{
    my $eidulf2004;
    $year_holidays{2004} = [
        _h_chnewyear ({_expand_dm("22-01")}, {hyear=>2555}),
        _h_eidula    ({_expand_dm("02-02")}, {hyear=>1424, original_date=>'2004-02-01'}),
        _h_hijra     ({_expand_dm("23-02")}, {hyear=>1425, original_date=>'2004-02-01'}),
        _h_nyepi     ({_expand_dm("22-03")}, {hyear=>1926}),
        _h_goodfri   ({_expand_dm("09-04")}),
        _h_mawlid    ({_expand_dm("03-05")}, {original_date=>'2004-05-02'}),
        _h_ascension ({_expand_dm("20-05")}),
        _h_vesakha   ({_expand_dm("03-06")}, {hyear=>2548}),
        _h_isramiraj ({_expand_dm("13-09")}, {original_date=>'2004-09-12'}),
        ($eidulf2004 =
        _h_eidulf    ({_expand_dm("14-11")}, {hyear=>1425, day=>1})),
        _h_eidulf    ({_expand_dm("15-11")}, {hyear=>1425, day=>2}),
        _h_eidulf    ({_expand_dm("16-11")}, {hyear=>1425, day=>3}),

        _jointlv     ({_expand_dm("17-11")}, {holiday=>$eidulf2004}),
        _jointlv     ({_expand_dm("18-11")}, {holiday=>$eidulf2004}),
        _jointlv     ({_expand_dm("19-11")}, {holiday=>$eidulf2004}),
    ];
}

# decreed jul ??, 2004
{
    my $eidulf2005;
    $year_holidays{2005} = [
        _h_eidula    ({_expand_dm("21-01")}, {hyear=>1425}),
        _h_chnewyear ({_expand_dm("09-02")}, {hyear=>2556}),
        _h_hijra     ({_expand_dm("10-02")}, {hyear=>1426}),
        _h_nyepi     ({_expand_dm("11-03")}, {hyear=>1927}),
        _h_goodfri   ({_expand_dm("25-03")}),
        _h_mawlid    ({_expand_dm("22-04")}, {original_date=>'2005-21-04'}),
        _h_ascension ({_expand_dm("05-05")}),
        _h_vesakha   ({_expand_dm("24-05")}, {hyear=>2549}),
        _h_isramiraj ({_expand_dm("02-09")}, {original_date=>'2005-09-01'}),
        ($eidulf2005 =
        _h_eidulf    ({_expand_dm("03-11")}, {hyear=>1426, day=>1})),
        _h_eidulf    ({_expand_dm("04-11")}, {hyear=>1426, day=>2}),

        _jointlv     ({_expand_dm("02-11")}, {holiday=>$eidulf2005}),
        _jointlv     ({_expand_dm("05-11")}, {holiday=>$eidulf2005}),
        _jointlv     ({_expand_dm("07-11")}, {holiday=>$eidulf2005}),
        _jointlv     ({_expand_dm("08-11")}, {holiday=>$eidulf2005}),
    ];
}

# decreed mar 22, 2006 (?)
{
    my $nyepi2006;
    my $ascension2006;
    my $eidulf2006;
    $year_holidays{2006} = [
        _h_eidula    ({_expand_dm("10-01")}, {hyear=>1426}),
        _h_hijra     ({_expand_dm("31-01")}, {hyear=>1427}),
        _h_chnewyear ({_expand_dm("29-01")}, {hyear=>2557}),
        ($nyepi2006 =
        _h_nyepi     ({_expand_dm("30-03")}, {hyear=>1928})),
        _h_mawlid    ({_expand_dm("10-04")}),
        _h_goodfri   ({_expand_dm("14-04")}),
        _h_vesakha   ({_expand_dm("13-05")}, {hyear=>2550}),
        ($ascension2006 =
        _h_ascension ({_expand_dm("25-05")})),
        _h_isramiraj ({_expand_dm("21-08")}),
        ($eidulf2006 =
        _h_eidulf    ({_expand_dm("24-10")}, {hyear=>1427, day=>1})),
        _h_eidulf    ({_expand_dm("25-10")}, {hyear=>1427, day=>2}),
        _h_eidula    ({_expand_dm("31-12")}, {hyear=>1427}),

        _jointlv     ({_expand_dm("31-03")}, {holiday=>$nyepi2006}),
        _jointlv     ({_expand_dm("26-05")}, {holiday=>$ascension2006}),
        _jointlv     ({_expand_dm("18-08")}, {holiday=>$indep}),
        _jointlv     ({_expand_dm("23-10")}, {holiday=>$eidulf2006}),
        _jointlv     ({_expand_dm("26-10")}, {holiday=>$eidulf2006}),
        _jointlv     ({_expand_dm("27-10")}, {holiday=>$eidulf2006}),
    ];
}

# decreed jul 24, 2006
{
    my $ascension2007;
    my $eidulf2007;
    $year_holidays{2007} = [
        _h_hijra     ({_expand_dm("20-01")}, {hyear=>1428}),
        _h_chnewyear ({_expand_dm("18-02")}, {hyear=>2558}),
        _h_nyepi     ({_expand_dm("19-03")}, {hyear=>1929}),
        _h_mawlid    ({_expand_dm("31-03")}),
        _h_goodfri   ({_expand_dm("06-04")}),
        ($ascension2007 =
        _h_ascension ({_expand_dm("17-05")})),
        _h_vesakha   ({_expand_dm("01-06")}, {hyear=>2551}),
        _h_isramiraj ({_expand_dm("11-08")}),
        ($eidulf2007 =
        _h_eidulf    ({_expand_dm("13-10")}, {hyear=>1428, day=>1})),
        _h_eidulf    ({_expand_dm("14-10")}, {hyear=>1428, day=>2}),
        _h_eidula    ({_expand_dm("20-12")}, {hyear=>1428}),

        _jointlv     ({_expand_dm("18-05")}, {holiday=>$ascension2007}),
        _jointlv     ({_expand_dm("12-10")}, {holiday=>$eidulf2007}),
        _jointlv     ({_expand_dm("15-10")}, {holiday=>$eidulf2007}),
        _jointlv     ({_expand_dm("16-10")}, {holiday=>$eidulf2007}),
        _jointlv     ({_expand_dm("21-12")}, {holiday=>$christmas}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed feb 5, 2008 (?)
{
    my $hijra2008a;
    my $eidulf2008;
    $year_holidays{2008} = [
        ($hijra2008a =
        _h_hijra     ({_expand_dm("10-01")}, {hyear=>1429})),
        _h_chnewyear ({_expand_dm("07-02")}, {hyear=>2559}),
        _h_nyepi     ({_expand_dm("07-03")}, {hyear=>1930}),
        _h_mawlid    ({_expand_dm("20-03")}),
        _h_goodfri   ({_expand_dm("21-03")}),
        _h_ascension ({_expand_dm("01-05")}),
        _h_vesakha   ({_expand_dm("20-05")}, {hyear=>2552}),
        _h_isramiraj ({_expand_dm("30-07")}),
        ($eidulf2008 =
        _h_eidulf    ({_expand_dm("01-10")}, {hyear=>1429, day=>1})),
        _h_eidulf    ({_expand_dm("02-10")}, {hyear=>1429, day=>2}),
        _h_eidula    ({_expand_dm("08-12")}),
        _h_hijra     ({_expand_dm("29-12")}, {hyear=>1430}),

        _jointlv     ({_expand_dm("11-01")}, {holiday=>$hijra2008a}),
        _jointlv     ({_expand_dm("29-09")}, {holiday=>$eidulf2008}),
        _jointlv     ({_expand_dm("30-09")}, {holiday=>$eidulf2008}),
        _jointlv     ({_expand_dm("03-10")}, {holiday=>$eidulf2008}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed juni 9, 2008
{
    my $eidulf2009;
    $year_holidays{2009} = [
        _h_chnewyear ({_expand_dm("26-01")}, {hyear=>2560}),
        _h_mawlid    ({_expand_dm("09-03")}),
        _h_nyepi     ({_expand_dm("26-03")}, {hyear=>1931}),
        _h_lelection ({_expand_dm("09-04")}, {}),
        _h_goodfri   ({_expand_dm("10-04")}),
        _h_vesakha   ({_expand_dm("09-05")}, {hyear=>2553}),
        _h_ascension ({_expand_dm("21-05")}),
        _h_pelection ({_expand_dm("08-07")}, {}),
        _h_isramiraj ({_expand_dm("20-07")}),
        ($eidulf2009 =
        _h_eidulf    ({_expand_dm("21-09")}, {hyear=>1430, day=>1})),
        _h_eidulf    ({_expand_dm("22-09")}, {hyear=>1430, day=>2}),
        _h_eidula    ({_expand_dm("27-11")}),
        _h_hijra     ({_expand_dm("18-12")}, {hyear=>1431}),

        _jointlv     ({_expand_dm("02-01")}, {holiday=>$newyear}),
        _jointlv     ({_expand_dm("18-09")}, {holiday=>$eidulf2009}),
        _jointlv     ({_expand_dm("23-09")}, {holiday=>$eidulf2009}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed aug 7, 2009
{
    my $eidulf2010;
    $year_holidays{2010} = [
        _h_chnewyear ({_expand_dm("14-02")}, {hyear=>2561}),
        _h_mawlid    ({_expand_dm("26-02")}),
        _h_nyepi     ({_expand_dm("16-03")}, {hyear=>1932}),
        _h_goodfri   ({_expand_dm("02-04")}),
        _h_vesakha   ({_expand_dm("28-05")}, {hyear=>2554}),
        _h_ascension ({_expand_dm("02-06")}),
        _h_isramiraj ({_expand_dm("10-07")}),
        ($eidulf2010 =
        _h_eidulf    ({_expand_dm("10-09")}, {hyear=>1431, day=>1})),
        _h_eidulf    ({_expand_dm("11-09")}, {hyear=>1431, day=>2}),
        _h_eidula    ({_expand_dm("17-11")}),
        _h_hijra     ({_expand_dm("07-12")}, {hyear=>1432}),

        _jointlv     ({_expand_dm("09-09")}, {holiday=>$eidulf2010}),
        _jointlv     ({_expand_dm("13-09")}, {holiday=>$eidulf2010}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed jun 15, 2010
{
    my $eidulf2011;
    $year_holidays{2011} = [
        _h_chnewyear ({_expand_dm("03-02")}, {hyear=>2562}),
        _h_mawlid    ({_expand_dm("16-02")}),
        _h_nyepi     ({_expand_dm("05-03")}, {hyear=>1933}),
        _h_goodfri   ({_expand_dm("22-04")}),
        _h_vesakha   ({_expand_dm("17-05")}, {hyear=>2555}),
        _h_ascension ({_expand_dm("02-06")}),
        _h_isramiraj ({_expand_dm("29-06")}),
        ($eidulf2011 =
        _h_eidulf    ({_expand_dm("30-08")}, {hyear=>1432, day=>1})),
        _h_eidulf    ({_expand_dm("31-08")}, {hyear=>1432, day=>2}),
        _h_eidula    ({_expand_dm("07-11")}),
        _h_hijra     ({_expand_dm("27-11")}, {hyear=>1433}),

        _jointlv     ({_expand_dm("29-08")}, {holiday=>$eidulf2011}),
        _jointlv     ({_expand_dm("01-09")}, {holiday=>$eidulf2011}),
        _jointlv     ({_expand_dm("02-09")}, {holiday=>$eidulf2011}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed may 16, 2011
{
    my $eidulf2012;
    $year_holidays{2012} = [
        _h_chnewyear ({_expand_dm("23-01")}, {hyear=>2563}),
        _h_mawlid    ({_expand_dm("04-02")}),
        _h_nyepi     ({_expand_dm("23-03")}, {hyear=>1934}),
        _h_goodfri   ({_expand_dm("06-04")}),
        _h_vesakha   ({_expand_dm("06-05")}, {hyear=>2556}),
        _h_ascension ({_expand_dm("17-05")}),
        _h_isramiraj ({_expand_dm("16-06")}),
        ($eidulf2012 =
        _h_eidulf    ({_expand_dm("19-08")}, {hyear=>1433, day=>1})),
        _h_eidulf    ({_expand_dm("20-08")}, {hyear=>1433, day=>2}),
        _h_eidula    ({_expand_dm("26-10")}),
        _h_hijra     ({_expand_dm("15-11")}, {hyear=>1434}),

        _jointlv     ({_expand_dm("21-08")}, {holiday=>$eidulf2012}),
        _jointlv     ({_expand_dm("22-08")}, {holiday=>$eidulf2012}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed jul 19, 2012
{
    my $eidulf2013;
    my $eidula2013;
    $year_holidays{2013} = [
        _h_mawlid    ({_expand_dm("24-01")}),
        _h_chnewyear ({_expand_dm("10-02")}, {hyear=>2564}),
        _h_nyepi     ({_expand_dm("12-03")}, {hyear=>1935}),
        _h_goodfri   ({_expand_dm("29-03")}),
        _h_ascension ({_expand_dm("09-05")}),
        _h_vesakha   ({_expand_dm("25-05")}, {hyear=>2557}),
        _h_isramiraj ({_expand_dm("06-06")}),
        ($eidulf2013 =
        _h_eidulf    ({_expand_dm("08-08")}, {hyear=>1434, day=>1})),
        _h_eidulf    ({_expand_dm("09-08")}, {hyear=>1434, day=>2}),
        ($eidula2013 =
        _h_eidula    ({_expand_dm("15-10")})),
        _h_hijra     ({_expand_dm("05-11")}, {hyear=>1435}),

        _jointlv     ({_expand_dm("05-08")}, {holiday=>$eidulf2013}),
        _jointlv     ({_expand_dm("06-08")}, {holiday=>$eidulf2013}),
        _jointlv     ({_expand_dm("07-08")}, {holiday=>$eidulf2013}),
        _jointlv     ({_expand_dm("14-10")}, {holiday=>$eidula2013}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed aug 21, 2013
#
# Surat Keputusan Bersama MenPAN dan RB, Menteri Tenaga Kerja dan Transmigrasi,
# dan Menteri Agama, Rabu (21/8/2013).
#
# ref:
# - http://www.menpan.go.id/berita-terkini/1713-tahun-2014-libur-nasional-dan-cuti-bersama-19-hari
# - http://nasional.kompas.com/read/2013/08/21/1314422/2014.Ada.19.Hari.Libur.Nasional.dan.Cuti.Bersama
# - http://www.kaskus.co.id/thread/52145f5359cb175740000007/jadwal-hari-libur-nasional-amp-cuti-bersama-tahun-2014-resmi--download-kalender/
{
    my $eidulf2014;
    my $eidula2014;
    $year_holidays{2014} = [
        _h_mawlid    ({_expand_dm("14-01")}),
        _h_chnewyear ({_expand_dm("31-01")}, {hyear=>2565}),
        _h_nyepi     ({_expand_dm("31-03")}, {hyear=>1936}),
        _h_lelection ({_expand_dm("09-04")}, {decree_date=>'2014-04-03', decree_note=>"Keppres 14/2014"}),
        _h_goodfri   ({_expand_dm("18-04")}),
        _h_vesakha   ({_expand_dm("15-05")}, {hyear=>2558}),
        _h_isramiraj ({_expand_dm("27-05")}),
        _h_ascension ({_expand_dm("29-05")}),

        # sudah ditetapkan KPU tapi belum ada keppres
        _h_pelection ({_expand_dm("09-07")}, {}),

        ($eidulf2014 =
        _h_eidulf    ({_expand_dm("28-07")}, {hyear=>1435, day=>1})),
        _h_eidulf    ({_expand_dm("29-07")}, {hyear=>1435, day=>2}),
        ($eidula2014 =
        _h_eidula    ({_expand_dm("05-10")}, {hyear=>1435})),
        _h_hijra     ({_expand_dm("25-10")}, {hyear=>1436}),

        _jointlv     ({_expand_dm("30-07")}, {holiday=>$eidulf2014}),
        _jointlv     ({_expand_dm("31-07")}, {holiday=>$eidulf2014}),
        _jointlv     ({_expand_dm("01-08")}, {holiday=>$eidulf2014}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed may 7, 2014
#
# Surat Keputusan Bersama Libur Nasional dan Cuti Bersama
#
# ref:
# - http://nasional.kompas.com/read/2014/05/07/1805155/Hari.Libur.dan.Cuti.Bersama.2015.Banyak.Long.Weekend.dan.Harpitnas.3
{
    my $eidulf2015;
    $year_holidays{2015} = [
        _h_mawlid    ({_expand_dm("03-01")}),
        _h_chnewyear ({_expand_dm("19-02")}, {hyear=>2566}),
        _h_nyepi     ({_expand_dm("21-03")}, {hyear=>1937}),
        _h_goodfri   ({_expand_dm("03-04")}),
        _h_ascension ({_expand_dm("14-05")}),
        _h_isramiraj ({_expand_dm("16-05")}),
        _h_vesakha   ({_expand_dm("02-06")}, {hyear=>2559}),

        ($eidulf2015 =
        _h_eidulf    ({_expand_dm("17-07")}, {hyear=>1436, day=>1})),
        _h_eidulf    ({_expand_dm("18-07")}, {hyear=>1436, day=>2}),
        _h_eidula    ({_expand_dm("24-09")}, {hyear=>1436}),
        _h_hijra     ({_expand_dm("14-10")}, {hyear=>1437}),
        _h_jrelection({_expand_dm("09-12")}, {decree_date => "2015-11-23"}),

        _jointlv     ({_expand_dm("16-07")}, {holiday=>$eidulf2015}),
        _jointlv     ({_expand_dm("20-07")}, {holiday=>$eidulf2015}),
        _jointlv     ({_expand_dm("21-07")}, {holiday=>$eidulf2015}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed jun 25, 2015
#
# ref:
# - http://id.wikipedia.org/wiki/2016#Hari_libur_nasional_di_Indonesia
# - http://www.merdeka.com/peristiwa/ini-daftar-hari-libur-nasional-dan-cuti-bersama-2016.html
{
    my $eidulf2016;
    $year_holidays{2016} = [
        _h_chnewyear ({_expand_dm("08-02")}, {hyear=>2567}),
        _h_nyepi     ({_expand_dm("09-03")}, {hyear=>1938}),
        _h_goodfri   ({_expand_dm("25-03")}),
        _h_ascension ({_expand_dm("05-05")}),
        _h_isramiraj ({_expand_dm("06-05")}),
        _h_vesakha   ({_expand_dm("22-05")}, {hyear=>2560}),
        ($eidulf2016 =
        _h_eidulf    ({_expand_dm("06-07")}, {hyear=>1437, day=>1})),
        _h_eidulf    ({_expand_dm("07-07")}, {hyear=>1437, day=>2}),
        _h_eidula    ({_expand_dm("12-09")}, {hyear=>1437}),
        _h_hijra     ({_expand_dm("02-10")}, {hyear=>1438}),
        _h_mawlid    ({_expand_dm("12-12")}),

        _jointlv     ({_expand_dm("04-07")}, {holiday=>$eidulf2016}),
        _jointlv     ({_expand_dm("05-07")}, {holiday=>$eidulf2016}),
        _jointlv     ({_expand_dm("08-07")}, {holiday=>$eidulf2016}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    ];
}

# decreed apr 14, 2016
#
# ref:
# - https://id.wikipedia.org/wiki/2017#Hari_libur_nasional_di_Indonesia
# - http://www.kemenkopmk.go.id/artikel/penetapan-hari-libur-nasional-dan-cuti-bersama-tahun-2017
{
    my $eidulf2017;
    $year_holidays{2017} = [
        _h_chnewyear ({_expand_dm("28-01")}, {hyear=>2568}),
        _h_nyepi     ({_expand_dm("28-03")}, {hyear=>1939}),
        _h_goodfri   ({_expand_dm("14-04")}),
        _h_isramiraj ({_expand_dm("24-04")}, {hyear=>1438}),
        _h_vesakha   ({_expand_dm("11-05")}, {hyear=>2561}),
        _h_ascension ({_expand_dm("25-05")}),
        ($eidulf2017 =
        _h_eidulf    ({_expand_dm("25-06")}, {hyear=>1438, day=>1})),
        _h_eidulf    ({_expand_dm("26-06")}, {hyear=>1438, day=>2}),
        _h_eidula    ({_expand_dm("01-09")}, {hyear=>1438}),
        _h_hijra     ({_expand_dm("21-09")}, {hyear=>1439}),
        _h_mawlid    ({_expand_dm("01-12")}, {hyear=>1439}),

        _jointlv     ({_expand_dm("23-06")}, {holiday=>$eidulf2017}), # ref: Keppres 18/2017 (2017-06-15)
        _jointlv     ({_expand_dm("27-06")}, {holiday=>$eidulf2017}),
        _jointlv     ({_expand_dm("28-06")}, {holiday=>$eidulf2017}),
        _jointlv     ({_expand_dm("29-06")}, {holiday=>$eidulf2017}),
        _jointlv     ({_expand_dm("30-06")}, {holiday=>$eidulf2017}),
    ];
}

# draft
#
# ref:
# - https://id.wikipedia.org/wiki/2018
# - https://www.kemenkopmk.go.id/artikel/rakor-skb-3-menteri-tentang-hari-libur-nasional-dan-cuti-bersama-2018 (mar 13, 2017)
{
    my $eidulf2018;
    $year_holidays{2018} = [
        # - new year
        _h_chnewyear ({_expand_dm("16-02")}, {hyear=>2569}),
        _h_nyepi     ({_expand_dm("18-03")}, {hyear=>1940}),
        _h_goodfri   ({_expand_dm("30-03")}),
        _h_isramiraj ({_expand_dm("13-04")}, {hyear=>1439}),

        # - labor day
        _h_ascension ({_expand_dm("10-05")}),
        _h_vesakha   ({_expand_dm("29-05")}, {hyear=>2562}),
        # - pancasila day
        ($eidulf2018 =
        _h_eidulf    ({_expand_dm("15-06")}, {hyear=>1439, day=>1})),

        _h_eidulf    ({_expand_dm("16-06")}, {hyear=>1439, day=>2}),
        # - independence day
        _h_eidula    ({_expand_dm("22-08")}, {hyear=>1439}),
        _h_hijra     ({_expand_dm("12-09")}, {hyear=>1440}),
        _h_mawlid    ({_expand_dm("20-11")}, {hyear=>1440}),

        # - christmas

        # note: this is currently just a wild guess because i'm having
        # difficulty finding sources
        _make_tentative(
            _jointlv     ({_expand_dm("14-06")}, {holiday=>$eidulf2018}),
            _jointlv     ({_expand_dm("18-06")}, {holiday=>$eidulf2018}),
            _jointlv     ({_expand_dm("19-06")}, {holiday=>$eidulf2018}),
            _jointlv     ({_expand_dm("20-06")}, {holiday=>$eidulf2018}),
            _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
        ),
    ];
}


my @years     = sort keys %year_holidays;
our $min_year = $years[0];
our $max_year = $years[-1];
our $max_joint_leave_year;
for my $y (reverse @years) {
    if (grep {$_->{is_joint_leave}} @{$year_holidays{$y}}) {
        $max_joint_leave_year = $y;
        last;
    }
}

my @holidays;
for my $year ($min_year .. $max_year) {
    my @hf;
    for my $h0 (@fixed_holidays) {
        next if $h0->{year_start} && $year < $h0->{year_start};
        next if $h0->{year_en}    && $year > $h0->{year_end};
        my $h = clone $h0;
        push @{$h->{tags}}, "fixed-date";
        $h->{is_holiday}     = 1;
        $h->{is_joint_leave} = 0;
        push @hf, $h;
    }

    my @hy;
    for my $h0 (@{$year_holidays{$year}}) {
        my $h = clone $h0;
        $h->{is_holiday}     //= 0;
        $h->{is_joint_leave} //= 0;
        delete $h->{ind_name0};
        delete $h->{eng_name0};
        push @hy, $h;
    }

    for my $h (@hf, @hy) {
        $h->{year} = $year;
        my $dt = DateTime->new(year=>$year, month=>$h->{month}, day=>$h->{day});
        $h->{date} = $dt->ymd;
        $h->{dow}  = $dt->day_of_week;
    }

    push @holidays, (sort {$a->{date} cmp $b->{date}} @hf, @hy);
}

my $res = gen_read_table_func(
    name => 'list_id_holidays',
    table_data => \@holidays,
    table_spec => {
        fields => {
            date => {
                schema     => 'date*',
                pos        => 0,
                searchable => 0,
            },
            day => {
                schema     => 'int*',
                pos        => 1,
            },
            month => {
                schema     => 'int*',
                pos        => 2,
            },
            year => {
                schema     => 'int*',
                pos        => 3,
            },
            dow => {
                schema => 'int*',
                summary    => 'Day of week (1-7, Monday is 1)',
                pos        => 4,
            },
            eng_name => {
                schema     => 'str*',
                summary    => 'English name',
                pos        => 5,
                filterable => 0,
                sortable   => 0,
            },
            ind_name => {
                schema     => 'str*',
                summary    => 'Indonesian name',
                pos        => 6,
                filterable => 0,
                sortable   => 0,
            },
            eng_aliases => {
                schema     => ['array*'=>{of=>'str*'}],
                summary    => 'English other names, if any',
                pos        => 7,
                filterable => 0,
                sortable   => 0,
            },
            ind_aliases => {
                schema     => ['array*'=>{of=>'str*'}],
                summary    => 'Indonesian other names, if any',
                pos        => 8,
                filterable => 0,
                sortable   => 0,
            },
            is_holiday => {
                schema     => 'bool*',
                pos        => 9,
            },
            is_joint_leave => {
                schema     => 'bool*',
                summary    => 'Whether this date is a joint leave day '.
                    '("cuti bersama")',
                pos        => 10,
            },
            decree_date => {
                schema     => 'str',
                pos        => 11,
                sortable   => 1,
            },
            decree_note => {
                schema     => 'str',
                pos        => 12,
                sortable   => 0,
            },
            note => {
                schema     => 'str',
                pos        => 13,
                sortable   => 0,
            },
            tags => {
                schema     => 'array*',
                pos        => 14,
                sortable   => 0,
            },
        },
        pk => 'date',
    },
    langs => ['en_US', 'id_ID'],
);

die "BUG: Can't generate func: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

$SPEC{list_id_holidays}{args}{year}{pos}  = 0;
$SPEC{list_id_holidays}{args}{month}{pos} = 1;

my $AVAILABLE_YEARS =
    "Contains data from years $min_year to $max_year (joint leave days until\n".
    "$max_joint_leave_year).";

    my $meta = $res->[2]{meta};
$meta->{summary} = "List Indonesian holidays in calendar";
$meta->{description} = <<"_";

List holidays and joint leave days ("cuti bersama").

$AVAILABLE_YEARS

_

sub _check_date_arg {
    my ($date) = @_;
    if (ref($date) && $date->isa('DateTime')) {
        return $date;
    } elsif ($date =~ /\A(\d{4})-(\d{2})-(\d{2})\z/) {
        return DateTime->new(year=>$1, month=>$2, day=>$3);
    } else {
        return;
    }
}

$SPEC{enum_id_workdays} = {
    v => 1.1,
    summary => 'Enumerate working days for a certain period',
    description => <<"_",

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

$AVAILABLE_YEARS

_
    args => {
        start_date => {
            summary => 'Starting date',
            schema  => 'str*',
            description => <<'_',

Defaults to start of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

_
        },
        end_date => {
            summary => 'End date',
            schema  => 'str*',
            description => <<'_',

Defaults to end of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

_
        },
        work_saturdays => {
            schema  => ['bool' => {default=>0}],
            summary => 'If set to 1, Saturday is a working day',
        },
        observe_joint_leaves => {
            summary => 'If set to 0, do not observe joint leave as holidays',
            schema  => ['bool' => {default => 1}],
        },
    },
};
sub enum_id_workdays {
    my %args = @_;

    # XXX args
    my $now = DateTime->now;
    my $som = DateTime->new(year => $now->year, month => $now->month, day => 1);
    my $eom = $som->clone->add(months=>1)->subtract(days=>1);
    my $start_date = _check_date_arg($args{start_date} // $som) or
        return [400, "Invalid start_date, must be string 'YYYY-MM-DD' ".
                    "or DateTime object"];
    my $end_date   = _check_date_arg($args{end_date} // $eom) or
        return [400, "Invalid end_date, must be string 'YYYY-MM-DD' ".
                    "or DateTime object"];
    for ($start_date, $end_date) {
        return [400, "Sorry, no data for year earlier than $min_year available"]
            if $_->year < $min_year;
        return [400, "Sorry, no data for year newer than $max_year available"]
            if $_->year > $max_year;
    }
    my $work_saturdays = $args{work_saturdays} // 0;
    my $observe_joint_leaves = $args{observe_joint_leaves} // 1;

    my @args;
    push @args, "year.min"=>$start_date->year;
    push @args, "year.max"=>$end_date->year;
    push @args, (is_holiday=>1) if !$observe_joint_leaves;
    my $res = list_id_holidays(@args);
    return err(500, "Can't list holidays", $res)
        unless $res->[0] == 200;
    #use Data::Dump; dd $res;

    my @wd;
    my $dt = $start_date->clone->subtract(days=>1);
    while (1) {
        $dt->add(days=>1);
        next if $dt->day_of_week == 7;
        next if $dt->day_of_week == 6 && !$work_saturdays;
        last if DateTime->compare($dt, $end_date) > 0;
        my $ymd = $dt->ymd;
        next if $ymd ~~ @{$res->[2]};
        push @wd, $ymd;
    }

    [200, "OK", \@wd];
}

gen_modified_sub(
    output_name => 'count_id_workdays',
    summary     => "Count working days for a certain period",

    base_name   => 'enum_id_workdays',
    output_code => sub {
        my $res = enum_id_workdays(@_);
        return $res unless $res->[0] == 200;
        $res->[2] = @{$res->[2]};
        $res;
    },
);

$SPEC{list_id_workdays} = {
    v => 1.1,
    summary => '',
    args => {
        year       => {schema=>'int*'},
        month      => {schema=>['int*', between=>[1, 12]]},
        start_date => {schema=>'str*'},
        end_date   => {schema=>'str*'},
    },
};
sub list_id_workdays {
    my %args = @_;

    my %fargs;
    my $y = $args{year};
    my $m = $args{month};
    if ($y) {
        if ($m) {
            $fargs{start_date} = DateTime->new(year=>$y, month=>$m, day=>1);
            $m++; if ($m == 13) { $m=1; $y++ }
            $fargs{end_date} = DateTime->new(year=>$y, month=>$m, day=>1)
                ->subtract(days => 1);
        } else {
            $fargs{start_date} = DateTime->new(year=>$y, month=>1, day=>1);
            $fargs{end_date} = DateTime->new(year=>$y+1, month=>1, day=>1)
                ->subtract(days => 1);
        }
    }

    if ($args{start_date}) {
        $fargs{start_date} = $fargs{start_date};
    }
    if ($args{end_date}) {
        $fargs{end_date} = $fargs{end_date};
    }

    Calendar::Indonesia::Holiday::enum_id_workdays(%fargs);
}

1;
# ABSTRACT: List Indonesian public holidays

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Indonesia::Holiday - List Indonesian public holidays

=head1 VERSION

This document describes version 0.31 of Calendar::Indonesia::Holiday (from Perl distribution Calendar-Indonesia-Holiday), released on 2017-07-31.

=head1 SYNOPSIS

 use Calendar::Indonesia::Holiday qw(
     list_id_holidays
     enum_id_workdays
     count_id_workdays
 );

This lists Indonesian holidays for the year 2011, without the joint leave days
("cuti bersama"), showing only the dates:

 my $res = list_id_holidays(year => 2011, is_joint_leave=>0);

Sample result:

 [200, "OK", [
   '2011-01-01',
   '2011-02-03',
   '2011-02-16',
   '2011-03-05',
   '2011-04-22',
   '2011-05-17',
   '2011-06-02',
   '2011-06-29',
   '2011-08-17',
   '2011-08-31',
   '2011-09-01',
   '2011-11-07',
   '2011-11-27',
   '2011-12-25',
 ]];

This lists religious Indonesian holidays, showing full details:

 my $res = list_id_holidays(year => 2011,
                            "tags.has" => ['religious'], detail=>1);

Sample result:

 [200, "OK", [
   {date        => '2011-02-16',
    day         => 16,
    month       => 2,
    year        => 2011,
    ind_name    => 'Maulid Nabi Muhammad',
    eng_name    => 'Mawlid',
    eng_aliases => ['Mawlid An-Nabi'],
    ind_aliases => ['Maulud'],
    is_holiday  => 1,
    tags        => [qw/religious religion=islam calendar=lunar/],
   },
   ...
 ]];

This checks whether 2011-02-16 is a holiday:

 my $res = list_id_holidays(date => '2011-02-16');
 print "2011-02-16 is a holiday\n" if @{$res->[2]};

This enumerate working days for a certain period:

 my $res = enum_id_workdays(year=>2011, month=>7);

Idem, but returns a number instead. year/month defaults to current
year/month:

 my $res = count_id_workdays();

=head1 DESCRIPTION

This module provides functions to list Indonesian holidays.

There is a command-line script interface for this module: L<list-id-holidays>.

=head1 FUNCTIONS


=head2 count_id_workdays

Usage:

 count_id_workdays(%args) -> [status, msg, result, meta]

Count working days for a certain period.

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

Contains data from years 2002 to 2018 (joint leave days until
2018).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<end_date> => I<str>

End date.

Defaults to end of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

=item * B<observe_joint_leaves> => I<bool> (default: 1)

If set to 0, do not observe joint leave as holidays.

=item * B<start_date> => I<str>

Starting date.

Defaults to start of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

=item * B<work_saturdays> => I<bool> (default: 0)

If set to 1, Saturday is a working day.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 enum_id_workdays

Usage:

 enum_id_workdays(%args) -> [status, msg, result, meta]

Enumerate working days for a certain period.

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

Contains data from years 2002 to 2018 (joint leave days until
2018).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<end_date> => I<str>

End date.

Defaults to end of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

=item * B<observe_joint_leaves> => I<bool> (default: 1)

If set to 0, do not observe joint leave as holidays.

=item * B<start_date> => I<str>

Starting date.

Defaults to start of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

=item * B<work_saturdays> => I<bool> (default: 0)

If set to 1, Saturday is a working day.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_id_holidays

Usage:

 list_id_holidays(%args) -> [status, msg, result, meta]

List Indonesian holidays in calendar.

List holidays and joint leave days ("cuti bersama").

Contains data from years 2002 to 2018 (joint leave days until
2018).

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<date>

Only return records where the 'date' field equals specified value.

=item * B<date.in> => I<array[date]>

Only return records where the 'date' field is in the specified values.

=item * B<date.is> => I<date>

Only return records where the 'date' field equals specified value.

=item * B<date.isnt> => I<date>

Only return records where the 'date' field does not equal specified value.

=item * B<date.max> => I<date>

Only return records where the 'date' field is less than or equal to specified value.

=item * B<date.min> => I<date>

Only return records where the 'date' field is greater than or equal to specified value.

=item * B<date.not_in> => I<array[date]>

Only return records where the 'date' field is not in the specified values.

=item * B<date.xmax> => I<date>

Only return records where the 'date' field is less than specified value.

=item * B<date.xmin> => I<date>

Only return records where the 'date' field is greater than specified value.

=item * B<day> => I<int>

Only return records where the 'day' field equals specified value.

=item * B<day.in> => I<array[int]>

Only return records where the 'day' field is in the specified values.

=item * B<day.is> => I<int>

Only return records where the 'day' field equals specified value.

=item * B<day.isnt> => I<int>

Only return records where the 'day' field does not equal specified value.

=item * B<day.max> => I<int>

Only return records where the 'day' field is less than or equal to specified value.

=item * B<day.min> => I<int>

Only return records where the 'day' field is greater than or equal to specified value.

=item * B<day.not_in> => I<array[int]>

Only return records where the 'day' field is not in the specified values.

=item * B<day.xmax> => I<int>

Only return records where the 'day' field is less than specified value.

=item * B<day.xmin> => I<int>

Only return records where the 'day' field is greater than specified value.

=item * B<decree_date> => I<str>

Only return records where the 'decree_date' field equals specified value.

=item * B<decree_date.contains> => I<str>

Only return records where the 'decree_date' field contains specified text.

=item * B<decree_date.in> => I<array[str]>

Only return records where the 'decree_date' field is in the specified values.

=item * B<decree_date.is> => I<str>

Only return records where the 'decree_date' field equals specified value.

=item * B<decree_date.isnt> => I<str>

Only return records where the 'decree_date' field does not equal specified value.

=item * B<decree_date.max> => I<str>

Only return records where the 'decree_date' field is less than or equal to specified value.

=item * B<decree_date.min> => I<str>

Only return records where the 'decree_date' field is greater than or equal to specified value.

=item * B<decree_date.not_contains> => I<str>

Only return records where the 'decree_date' field does not contain specified text.

=item * B<decree_date.not_in> => I<array[str]>

Only return records where the 'decree_date' field is not in the specified values.

=item * B<decree_date.xmax> => I<str>

Only return records where the 'decree_date' field is less than specified value.

=item * B<decree_date.xmin> => I<str>

Only return records where the 'decree_date' field is greater than specified value.

=item * B<decree_note> => I<str>

Only return records where the 'decree_note' field equals specified value.

=item * B<decree_note.contains> => I<str>

Only return records where the 'decree_note' field contains specified text.

=item * B<decree_note.in> => I<array[str]>

Only return records where the 'decree_note' field is in the specified values.

=item * B<decree_note.is> => I<str>

Only return records where the 'decree_note' field equals specified value.

=item * B<decree_note.isnt> => I<str>

Only return records where the 'decree_note' field does not equal specified value.

=item * B<decree_note.max> => I<str>

Only return records where the 'decree_note' field is less than or equal to specified value.

=item * B<decree_note.min> => I<str>

Only return records where the 'decree_note' field is greater than or equal to specified value.

=item * B<decree_note.not_contains> => I<str>

Only return records where the 'decree_note' field does not contain specified text.

=item * B<decree_note.not_in> => I<array[str]>

Only return records where the 'decree_note' field is not in the specified values.

=item * B<decree_note.xmax> => I<str>

Only return records where the 'decree_note' field is less than specified value.

=item * B<decree_note.xmin> => I<str>

Only return records where the 'decree_note' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<dow> => I<int>

Only return records where the 'dow' field equals specified value.

=item * B<dow.in> => I<array[int]>

Only return records where the 'dow' field is in the specified values.

=item * B<dow.is> => I<int>

Only return records where the 'dow' field equals specified value.

=item * B<dow.isnt> => I<int>

Only return records where the 'dow' field does not equal specified value.

=item * B<dow.max> => I<int>

Only return records where the 'dow' field is less than or equal to specified value.

=item * B<dow.min> => I<int>

Only return records where the 'dow' field is greater than or equal to specified value.

=item * B<dow.not_in> => I<array[int]>

Only return records where the 'dow' field is not in the specified values.

=item * B<dow.xmax> => I<int>

Only return records where the 'dow' field is less than specified value.

=item * B<dow.xmin> => I<int>

Only return records where the 'dow' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<is_holiday> => I<bool>

Only return records where the 'is_holiday' field equals specified value.

=item * B<is_holiday.is> => I<bool>

Only return records where the 'is_holiday' field equals specified value.

=item * B<is_holiday.isnt> => I<bool>

Only return records where the 'is_holiday' field does not equal specified value.

=item * B<is_joint_leave> => I<bool>

Only return records where the 'is_joint_leave' field equals specified value.

=item * B<is_joint_leave.is> => I<bool>

Only return records where the 'is_joint_leave' field equals specified value.

=item * B<is_joint_leave.isnt> => I<bool>

Only return records where the 'is_joint_leave' field does not equal specified value.

=item * B<month> => I<int>

Only return records where the 'month' field equals specified value.

=item * B<month.in> => I<array[int]>

Only return records where the 'month' field is in the specified values.

=item * B<month.is> => I<int>

Only return records where the 'month' field equals specified value.

=item * B<month.isnt> => I<int>

Only return records where the 'month' field does not equal specified value.

=item * B<month.max> => I<int>

Only return records where the 'month' field is less than or equal to specified value.

=item * B<month.min> => I<int>

Only return records where the 'month' field is greater than or equal to specified value.

=item * B<month.not_in> => I<array[int]>

Only return records where the 'month' field is not in the specified values.

=item * B<month.xmax> => I<int>

Only return records where the 'month' field is less than specified value.

=item * B<month.xmin> => I<int>

Only return records where the 'month' field is greater than specified value.

=item * B<note> => I<str>

Only return records where the 'note' field equals specified value.

=item * B<note.contains> => I<str>

Only return records where the 'note' field contains specified text.

=item * B<note.in> => I<array[str]>

Only return records where the 'note' field is in the specified values.

=item * B<note.is> => I<str>

Only return records where the 'note' field equals specified value.

=item * B<note.isnt> => I<str>

Only return records where the 'note' field does not equal specified value.

=item * B<note.max> => I<str>

Only return records where the 'note' field is less than or equal to specified value.

=item * B<note.min> => I<str>

Only return records where the 'note' field is greater than or equal to specified value.

=item * B<note.not_contains> => I<str>

Only return records where the 'note' field does not contain specified text.

=item * B<note.not_in> => I<array[str]>

Only return records where the 'note' field is not in the specified values.

=item * B<note.xmax> => I<str>

Only return records where the 'note' field is less than specified value.

=item * B<note.xmin> => I<str>

Only return records where the 'note' field is greater than specified value.

=item * B<query> => I<str>

Search.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<tags> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.has> => I<array[str]>

Only return records where the 'tags' field is an array/list which contains specified value.

=item * B<tags.is> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.isnt> => I<array>

Only return records where the 'tags' field does not equal specified value.

=item * B<tags.lacks> => I<array[str]>

Only return records where the 'tags' field is an array/list which does not contain specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=item * B<year> => I<int>

Only return records where the 'year' field equals specified value.

=item * B<year.in> => I<array[int]>

Only return records where the 'year' field is in the specified values.

=item * B<year.is> => I<int>

Only return records where the 'year' field equals specified value.

=item * B<year.isnt> => I<int>

Only return records where the 'year' field does not equal specified value.

=item * B<year.max> => I<int>

Only return records where the 'year' field is less than or equal to specified value.

=item * B<year.min> => I<int>

Only return records where the 'year' field is greater than or equal to specified value.

=item * B<year.not_in> => I<array[int]>

Only return records where the 'year' field is not in the specified values.

=item * B<year.xmax> => I<int>

Only return records where the 'year' field is less than specified value.

=item * B<year.xmin> => I<int>

Only return records where the 'year' field is greater than specified value.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_id_workdays

Usage:

 list_id_workdays(%args) -> [status, msg, result, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<end_date> => I<str>

=item * B<month> => I<int>

=item * B<start_date> => I<str>

=item * B<year> => I<int>

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (result) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 FAQ

=head2 What is "joint leave"?

Workers are normally granted 12 days of paid leave per year. They are free to
spend it on whichever days they want. The joint leave ("cuti bersama") is a
government program of recent years (since 2002) to recommend that some of these
leave days be spent together nationally on certain days, especially during
Lebaran (Eid Ul-Fitr). It is not mandated, but many do follow it anyway, e.g.
government civil workers, banks, etc. I am marking joint leave days with
is_joint_leave=1 and is_holiday=0, while the holidays themselves with
is_holiday=1, so you can differentiate/select both/either one.

=head2 Holidays before 2002?

Will be provided if there is demand and data source.

=head2 Holidays after (current year)+1?

Some religious holidays, especially Vesakha, are not determined yet. Joint leave
days are also usually decreed by the government in May/June of the preceding
year.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Indonesia-Holiday>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Calendar-Indonesia-Holiday>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Indonesia-Holiday>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

This API will also be available on GudangAPI, http://gudangapi.com/

Aside from national holidays, some provinces declare their own (e.g. governor
election day for East Java province, etc).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
