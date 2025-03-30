package Calendar::Indonesia::Holiday;

use 5.010001;
use strict;
use warnings;
#use Log::ger;

use DateTime;
use Function::Fallback::CoreOrPP qw(clone);
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);
use Perinci::Sub::Util qw(err gen_modified_sub);

require Exporter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2025-03-29'; # DATE
our $DIST = 'Calendar-Indonesia-Holiday'; # DIST
our $VERSION = '0.353'; # VERSION

our @ISA = qw(Exporter);
our @EXPORT_OK = (
    'list_idn_holidays',
    'list_idn_workdays',
    'count_idn_workdays',
    'is_idn_holiday',
    'is_idn_workday',
);

our %SPEC;

our %argspecs_date_or_day_month_year = (
    day        => {schema=>['int*', between=>[1,31]]},
    month      => {schema=>['int*', between=>[1, 12]]},
    year       => {schema=>'int*'},
    date       => {schema=>'str*', pos=>0},
);

our %argsrels_date_or_day_month_year = (
    choose_all => [qw/day month year/],
    req_one => [qw/day date/],
);

$SPEC{':package'} = {
    v => 1.1,
    summary => 'List Indonesian public holidays',
};

my @fixed_holidays = (
    my $newyear = {
        day        =>  1, month =>  1,
        ind_name   => sub {
            my $opts = shift;
            "Tahun Baru " . $opts->{year} . " Masehi";
        },
        eng_name   => "New Year",
        tags       => [qw/international/],
        fixed_date => 1,
    },
    my $indep = {
        day        => 17, month =>  8,
        ind_name   => "Proklamasi",
        eng_name   => "Declaration Of Independence",
        tags       => [qw/national/],
        fixed_date => 1,
    },
    my $christmas = {
        day        => 25, month => 12,
        ind_name   => "Natal",
        eng_name   => "Christmas",
        tags       => [qw/international religious religion=christianity/],
        fixed_date => 1,
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
        fixed_date  => 1,
    },
    my $pancasilad = {
        day         => 1, month => 6,
        year_start  => 2017,
        ind_name    => "Hari Lahir Pancasila",
        eng_name    => "Pancasila Day",
        tags        => [qw/national/],
        decree_date => "2016-06-01",
        decree_note => "Pancasila day becomes national holiday since 2017, ".
            "decreed by president (Keppres 24/2016)",
        # ref: http://www.kemendagri.go.id/media/documents/2016/08/03/k/e/keppres_no.24_th_2016.pdf
        fixed_date  => 1,
    },
);

sub _add_original_date {
    my ($r, $opts) = @_;
    if ($opts->{original_date}) {
        $r->{ind_name} .= " (diperingati $opts->{original_date})";
        $r->{eng_name} .= " (commemorated on $opts->{original_date})";
    }
}

our $year;

sub _h_chnewyear {
    my ($r, $opts) = @_;
    $opts //= {};
    $r->{ind_name}    = "Tahun Baru Imlek".
        ($opts->{hyear} ? " $opts->{hyear}" . ($year && $year >= 2024 ? " Kongzili" : ""):"");
    $r->{eng_name}    = "Chinese New Year".
        ($opts->{hyear} ? " $opts->{hyear}":"");
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
    $r->{eng_aliases} = [];
    $r->{is_holiday}  = 1;
    $r->{year_start}  = 2003; # decreed in 2002 by megawati soekarnoputri
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

# since 2024
sub _h_easter {
    my ($r, $opts) = @_;
    $opts //= {};
    $r->{ind_name}    = $year && $year >= 2025 ?
        "Kebangkitan Yesus Kristus (Paskah)" : "Hari Paskah";
    $r->{eng_name}    = "Easter";
    _add_original_date($r, $opts);
    $r->{ind_aliases} = [];
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
    $opts //= {};
    $r->{ind_name}    = $year && $year >= 2024 ?
        "Kenaikan Yesus Kristus" : "Kenaikan Isa Al-Masih";
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
    $r->{ind_name}    = $ind_name0.($opts->{day} ? " (Hari $opts->{day})":"");
    $r->{eng_name}    = $eng_name0.($opts->{day} ? " (Day $opts->{day})":"");
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
        push @{ $arg->{tags} }, 'tentative' unless grep { $_ eq 'tentative' } @{ $arg->{tags} };
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

sub _uniquify_holidays {
    my @holidays = @_;

    my %seen; # key=mm-dd (e.g. 12-25), val=[hol1, hol2, ...]
    for my $h (@holidays) {
        my $k = sprintf "%02d-%02d", $h->{month}, $h->{day};
        $seen{$k} //= [];
        push @{ $seen{$k} }, $h;
    }

    for my $k (keys %seen) {
        if (@{ $seen{$k} } == 1) {
            $seen{$k} = $seen{$k}[0];
        } else {
            my $h_mult = {
                multiple => 1,
                ind_name => join(", ", map {$_->{ind_name}} @{ $seen{$k} }),
                eng_name => join(", ", map {$_->{eng_name}} @{ $seen{$k} }),
                holidays => $seen{$k},
            };
            # join all the tags
            my @tags;
            for my $h (@{ $seen{$k} }) {
                next unless $h->{tags};
                for my $t (@{ $h->{tags} }) {
                    push @tags, $t unless grep { $_ eq $t } @tags;
                }
            }
            $h_mult->{tags} = \@tags;
            # join all the properties
          PROP:
            for my $prop (keys %{ $seen{$k}[0] }) {
                next if exists $h_mult->{$prop};
                my %vals;
                for my $h (@{ $seen{$k} }) {
                    next PROP unless defined $h->{$prop};
                    $vals{ $h->{$prop} }++;
                }
                next if keys(%vals) > 1;
                $h_mult->{$prop} = $seen{$k}[0]{$prop};
            }
            $seen{$k} = $h_mult;
        }
    }

    map { $seen{$_} } sort keys %seen;
}

sub _get_date_day_month_year {
    my $args = shift;

    my ($y, $m, $d, $date);
    if (defined $args->{date}) {
        $args->{date} =~ /\A(\d{4})-(\d{1,2})-(\d{1,2})\z/
            or return [400, "Invalid date syntax, please use 'YYYY-MM-DD' format"];
        ($y, $m, $d) = ($1, $2, $3);
    } else {
        ($y = $args->{year}) && ($m = $args->{month}) && ($d = $args->{day})
            or return [400, "Please specify day/month/year or date"];
    }
    $date = sprintf "%04d-%02d-%02d", $y, $m, $d;
    [200, "OK", [$date, $y, $m, $d]];
}

our %year_holidays;

# decreed ?
# source: https://id.wikipedia.org/wiki/1990
{
    $year_holidays{1990} = [
        _h_isramiraj ({_expand_dm("23-02")}, {hyear=>1410}),
        _h_nyepi     ({_expand_dm("27-03")}, {hyear=>1912}),
        _h_goodfri   ({_expand_dm("13-04")}),
        _h_eidulf    ({_expand_dm("26-04")}, {hyear=>1410, day=>1}),
        _h_eidulf    ({_expand_dm("27-04")}, {hyear=>1410, day=>2}),
        _h_vesakha   ({_expand_dm("10-05")}, {hyear=>2534}),
        _h_ascension ({_expand_dm("24-05")}),
        _h_eidula    ({_expand_dm("03-07")}, {hyear=>1410}),
        _h_hijra     ({_expand_dm("23-07")}, {hyear=>1411}),
        _h_mawlid    ({_expand_dm("01-10")}, {hyear=>1411}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1991
{
    $year_holidays{1991} = [
        _h_isramiraj ({_expand_dm("12-02")}, {hyear=>1411}),
        _h_nyepi     ({_expand_dm("17-03")}, {hyear=>1913}),
        _h_goodfri   ({_expand_dm("29-03")}),
        _h_eidulf    ({_expand_dm("16-04")}, {hyear=>1411, day=>1}),
        _h_eidulf    ({_expand_dm("17-04")}, {hyear=>1411, day=>2}),
        _h_ascension ({_expand_dm("09-05")}),
        _h_vesakha   ({_expand_dm("28-05")}, {hyear=>2535}),
        _h_eidula    ({_expand_dm("23-06")}, {hyear=>1411}),
        _h_hijra     ({_expand_dm("13-07")}, {hyear=>1412}),
        _h_mawlid    ({_expand_dm("21-09")}, {hyear=>1412}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1992
{
    $year_holidays{1992} = [
        _h_isramiraj ({_expand_dm("01-02")}, {hyear=>1412}),
        _h_nyepi     ({_expand_dm("05-03")}, {hyear=>1914}),
        _h_eidulf    ({_expand_dm("05-04")}, {hyear=>1412, day=>1}),
        _h_eidulf    ({_expand_dm("06-04")}, {hyear=>1412, day=>2}),
        _h_goodfri   ({_expand_dm("17-04")}),
        _h_vesakha   ({_expand_dm("16-05")}, {hyear=>2536}),
        _h_ascension ({_expand_dm("28-05")}),
        _h_lelection ({_expand_dm("09-06")}, {}),
        _h_eidula    ({_expand_dm("11-06")}, {hyear=>1412}),
        _h_hijra     ({_expand_dm("02-07")}, {hyear=>1413}),
        _h_mawlid    ({_expand_dm("09-09")}, {hyear=>1413}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1993
{
    $year_holidays{1993} = [
        _h_isramiraj ({_expand_dm("20-01")}, {hyear=>1413}),
        _h_nyepi     ({_expand_dm("24-03")}, {hyear=>1915}),
        _h_eidulf    ({_expand_dm("25-03")}, {hyear=>1413, day=>1}),
        _h_eidulf    ({_expand_dm("26-03")}, {hyear=>1413, day=>2}),
        _h_goodfri   ({_expand_dm("09-04")}),
        _h_vesakha   ({_expand_dm("06-05")}, {hyear=>2537}),
        _h_ascension ({_expand_dm("20-05")}),
        _h_eidula    ({_expand_dm("01-06")}, {hyear=>1413}),
        _h_hijra     ({_expand_dm("21-06")}, {hyear=>1414}),
        _h_mawlid    ({_expand_dm("30-08")}, {hyear=>1414}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1994
{
    $year_holidays{1994} = [
        _h_isramiraj ({_expand_dm("10-01")}, {hyear=>1414}),
        _h_eidulf    ({_expand_dm("14-03")}, {hyear=>1414, day=>1}),
        _h_eidulf    ({_expand_dm("15-03")}, {hyear=>1414, day=>2}),
        _h_goodfri   ({_expand_dm("01-04")}),
        _h_nyepi     ({_expand_dm("12-04")}, {hyear=>1916}),
        _h_ascension ({_expand_dm("12-05")}),
        _h_eidula    ({_expand_dm("21-05")}, {hyear=>1414}),
        _h_vesakha   ({_expand_dm("25-05")}, {hyear=>2538}),
        _h_hijra     ({_expand_dm("11-06")}, {hyear=>1415}),
        _h_mawlid    ({_expand_dm("20-08")}, {hyear=>1415}),
        _h_isramiraj ({_expand_dm("30-12")}, {hyear=>1415}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1995
{
    $year_holidays{1995} = [
        _h_eidulf    ({_expand_dm("03-03")}, {hyear=>1415, day=>1}),
        _h_eidulf    ({_expand_dm("04-03")}, {hyear=>1415, day=>2}),
        _h_nyepi     ({_expand_dm("01-04")}, {hyear=>1917}),
        _h_goodfri   ({_expand_dm("14-04")}),
        _h_eidula    ({_expand_dm("10-05")}, {hyear=>1415}),
        _h_vesakha   ({_expand_dm("15-05")}, {hyear=>2539}),
        _h_ascension ({_expand_dm("25-05")}),
        _h_hijra     ({_expand_dm("31-05")}, {hyear=>1416}),
        _h_mawlid    ({_expand_dm("09-08")}, {hyear=>1416}),
        _h_isramiraj ({_expand_dm("20-12")}, {hyear=>1416}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1996
{
    $year_holidays{1996} = [
        _h_eidulf    ({_expand_dm("20-02")}, {hyear=>1416, day=>1}),
        _h_eidulf    ({_expand_dm("21-02")}, {hyear=>1416, day=>2}),
        _h_nyepi     ({_expand_dm("21-03")}, {hyear=>1918}),
        _h_goodfri   ({_expand_dm("05-04")}),
        _h_eidula    ({_expand_dm("28-04")}, {hyear=>1416}),
        _h_ascension ({_expand_dm("16-05")}),
        _h_hijra     ({_expand_dm("19-05")}, {hyear=>1417}),
        _h_vesakha   ({_expand_dm("02-06")}, {hyear=>2540}),
        _h_mawlid    ({_expand_dm("28-07")}, {hyear=>1417}),
        _h_isramiraj ({_expand_dm("08-12")}, {hyear=>1417}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1997
{
    $year_holidays{1997} = [
        _h_eidulf    ({_expand_dm("09-02")}, {hyear=>1417, day=>1}),
        _h_eidulf    ({_expand_dm("10-02")}, {hyear=>1417, day=>2}),
        _h_goodfri   ({_expand_dm("28-03")}),
        _h_nyepi     ({_expand_dm("09-04")}, {hyear=>1919}),
        _h_eidula    ({_expand_dm("18-04")}, {hyear=>1417}),
        _h_hijra     ({_expand_dm("08-05")}, {hyear=>1418}), # coincide
        _h_ascension ({_expand_dm("08-05")}),                # coincide
        _h_vesakha   ({_expand_dm("22-05")}, {hyear=>2541}),
        _h_lelection ({_expand_dm("29-05")}, {}),
        _h_mawlid    ({_expand_dm("17-07")}, {hyear=>1418}),
        _h_isramiraj ({_expand_dm("28-11")}, {hyear=>1418}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1998
{
    $year_holidays{1998} = [
        _h_eidulf    ({_expand_dm("30-01")}, {hyear=>1418, day=>1}),
        _h_eidulf    ({_expand_dm("31-01")}, {hyear=>1418, day=>2}),
        _h_nyepi     ({_expand_dm("29-03")}, {hyear=>1920}),
        _h_eidula    ({_expand_dm("07-04")}, {hyear=>1418}),
        _h_goodfri   ({_expand_dm("10-04")}),
        _h_hijra     ({_expand_dm("28-04")}, {hyear=>1419}),
        _h_vesakha   ({_expand_dm("11-05")}, {hyear=>2542}),
        _h_ascension ({_expand_dm("21-05")}),
        _h_mawlid    ({_expand_dm("06-07")}, {hyear=>1419}),
        _h_isramiraj ({_expand_dm("17-11")}, {hyear=>1419}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/1999
{
    $year_holidays{1999} = [
        _h_eidulf    ({_expand_dm("19-01")}, {hyear=>1419, day=>1}),
        _h_eidulf    ({_expand_dm("20-01")}, {hyear=>1419, day=>2}),
        _h_nyepi     ({_expand_dm("18-03")}, {hyear=>1921}),
        _h_eidula    ({_expand_dm("28-03")}, {hyear=>1419}),
        _h_goodfri   ({_expand_dm("02-04")}),
        _h_hijra     ({_expand_dm("17-04")}, {hyear=>1420}),
        _h_ascension ({_expand_dm("13-05")}),
        _h_vesakha   ({_expand_dm("30-05")}, {hyear=>2543}),
        _h_lelection ({_expand_dm("07-06")}, {}),
        _h_mawlid    ({_expand_dm("26-06")}, {hyear=>1420}),
        _h_isramiraj ({_expand_dm("06-11")}, {hyear=>1420}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/2000
{
    $year_holidays{2000} = [
        _h_eidulf    ({_expand_dm("08-01")}, {hyear=>1420, day=>1}),
        _h_eidulf    ({_expand_dm("09-01")}, {hyear=>1420, day=>2}),
        _h_eidula    ({_expand_dm("16-03")}, {hyear=>1420}),
        _h_nyepi     ({_expand_dm("04-04")}, {hyear=>1922}),
        _h_hijra     ({_expand_dm("06-04")}, {hyear=>1421}),
        _h_goodfri   ({_expand_dm("21-04")}),
        _h_vesakha   ({_expand_dm("18-05")}, {hyear=>2544}),
        _h_ascension ({_expand_dm("01-06")}),
        _h_mawlid    ({_expand_dm("15-06")}, {hyear=>1421}),
        _h_isramiraj ({_expand_dm("25-10")}, {hyear=>1421}),
        _h_eidulf    ({_expand_dm("16-12")}, {hyear=>1422, day=>1}),
        _h_eidulf    ({_expand_dm("17-12")}, {hyear=>1422, day=>2}),
    ];
}

# decreed ?
# source: https://id.wikipedia.org/wiki/2001
{
    $year_holidays{2001} = [
        _h_eidula    ({_expand_dm("05-03")}, {hyear=>1421}),
        _h_nyepi     ({_expand_dm("25-03")}, {hyear=>1923}),
        _h_hijra     ({_expand_dm("26-03")}, {hyear=>1422}),
        _h_goodfri   ({_expand_dm("13-04")}),
        _h_vesakha   ({_expand_dm("07-05")}, {hyear=>2545}),
        _h_ascension ({_expand_dm("24-05")}),
        _h_mawlid    ({_expand_dm("04-06")}, {hyear=>1422}),
        _h_isramiraj ({_expand_dm("15-10")}, {hyear=>1422}),
        _h_eidulf    ({_expand_dm("16-12")}, {hyear=>1422, day=>1}),
        _h_eidulf    ({_expand_dm("17-12")}, {hyear=>1422, day=>2}),
    ];
}

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
        _h_isramiraj ({_expand_dm("04-10")}, {hyear=>1423}),
        ($eidulf2002 =
        _h_eidulf    ({_expand_dm("06-12")}, {hyear=>1423, day=>1})),
        _h_eidulf    ({_expand_dm("07-12")}, {hyear=>1423, day=>2}),

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
        _h_eidulf    ({_expand_dm("25-11")}, {hyear=>1424, day=>1})),
        _h_eidulf    ({_expand_dm("26-11")}, {hyear=>1424, day=>2}),

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
        _h_lelection ({_expand_dm("05-04")}, {}),
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

# decreed oct 3, 2017
#
# ref:
# - https://id.wikipedia.org/wiki/2018
# - https://www.kemenkopmk.go.id/artikel/rakor-skb-3-menteri-tentang-hari-libur-nasional-dan-cuti-bersama-2018 (mar 13, 2017)
# - http://news.liputan6.com/read/3116580/pemerintah-tetapkan-hari-libur-nasional-dan-cuti-bersama-2018
{
    my $eidulf2018;
    $year_holidays{2018} = [
        # - new year
        _h_chnewyear ({_expand_dm("16-02")}, {hyear=>2569}),
        _h_nyepi     ({_expand_dm("17-03")}, {hyear=>1940}),
        _h_goodfri   ({_expand_dm("30-03")}),
        _h_isramiraj ({_expand_dm("14-04")}, {hyear=>1439}),

        # - labor day
        _h_ascension ({_expand_dm("10-05")}),
        _h_vesakha   ({_expand_dm("29-05")}, {hyear=>2562}),
        # - pancasila day
        ($eidulf2018 =
        _h_eidulf    ({_expand_dm("15-06")}, {hyear=>1439, day=>1})),

        _h_eidulf    ({_expand_dm("16-06")}, {hyear=>1439, day=>2}),
        _h_jrelection({_expand_dm("27-06")}, {decree_date=>"2018-06-25"}),
        # - independence day
        _h_eidula    ({_expand_dm("22-08")}, {hyear=>1439}),
        _h_hijra     ({_expand_dm("11-09")}, {hyear=>1440}),
        _h_mawlid    ({_expand_dm("20-11")}, {hyear=>1440}),

        # - christmas

        _jointlv     ({_expand_dm("11-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("12-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("13-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("14-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("18-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("19-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("20-06")}, {holiday=>$eidulf2018}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed nov 13, 2018
#
# ref:
# - https://jpp.go.id/humaniora/sosial-budaya/327328-pemerintah-resmi-menetapkan-hari-libur-nasional-2019
{
    my $eidulf2019;
    $year_holidays{2019} = [
        # - new year
        _h_chnewyear ({_expand_dm("05-02")}, {hyear=>2570}),
        _h_nyepi     ({_expand_dm("07-03")}, {hyear=>1941}),
        _h_isramiraj ({_expand_dm("03-04")}, {hyear=>1440}),
        _h_lelection ({_expand_dm("17-04")}),
        _h_goodfri   ({_expand_dm("19-04")}),
        # - labor day
        _h_vesakha   ({_expand_dm("19-05")}, {hyear=>2563}),
        _h_ascension ({_expand_dm("30-05")}),
        # - pancasila day
        ($eidulf2019 =
        _h_eidulf    ({_expand_dm("05-06")}, {hyear=>1440, day=>1})),
        _h_eidulf    ({_expand_dm("06-06")}, {hyear=>1440, day=>2}),
        _h_eidula    ({_expand_dm("11-08")}, {hyear=>1440}),
        # - independence day
        _h_hijra     ({_expand_dm("01-09")}, {hyear=>1441}),
        _h_mawlid    ({_expand_dm("09-11")}, {hyear=>1441}),
        # - christmas

        _jointlv     ({_expand_dm("03-06")}, {holiday=>$eidulf2019}),
        _jointlv     ({_expand_dm("04-06")}, {holiday=>$eidulf2019}),
        _jointlv     ({_expand_dm("07-06")}, {holiday=>$eidulf2019}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
    ];
}

# decreed aug 28, 2019 (SKB ministry of religion, ministry of employment, ministry of state apparatus empowerment 728/2019, 213/2019, 01/2019)
# revised mar  9, 2020 (SKB 174/2020, 01/2020, 01/2020)
# revised apr  9, 2020 (SKB 391/2020, 02/2020, 02/2020)
# revised may 20, 2020 (SKB 440/2020, 03/2020, 03/2020)
# revised dec  1, 2020 (SKB 744/2020, 05/2020, 06/2020)
#
# ref:
# - https://www.kemenkopmk.go.id/sites/default/files/artikel/2020-04/SKB%20Perubahan%20Kedua%20Libnas%20%26%20Cutber%202020.pdf
# - https://www.kemenkopmk.go.id/sites/default/files/pengumuman/2020-12/SKB%203%20Menteri%20tentang%20Perubahan%20ke-4%20Libnas%20%26%20Cutber%202020_0.pdf

{
    my $hijra2020;
    my $eidula2020;
    my $eidulf2020;
    my $mawlid2020;
    $year_holidays{2020} = [
        # - new year
        _h_chnewyear ({_expand_dm("25-01")}, {hyear=>2571}),
        _h_isramiraj ({_expand_dm("22-03")}, {hyear=>1441}),
        _h_nyepi     ({_expand_dm("25-03")}, {hyear=>1942}),
        _h_goodfri   ({_expand_dm("10-04")}),
        # - labor day
        _h_vesakha   ({_expand_dm("07-05")}, {hyear=>2564}),
        _h_ascension ({_expand_dm("21-05")}),
        _h_eidulf    ({_expand_dm("24-05")}, {hyear=>1441, day=>1}),
        ($eidulf2020 = _h_eidulf({_expand_dm("25-05")}, {hyear=>1441, day=>2})),
        # - pancasila day
        ($eidula2020 = _h_eidula ({_expand_dm("31-07")}, {hyear=>1441})),
        # - independence day
        ($hijra2020 = _h_hijra     ({_expand_dm("20-08")}, {hyear=>1442})),
        ($mawlid2020 = _h_mawlid({_expand_dm("29-10")}, {hyear=>1442})),
        _h_jrelection({_expand_dm("09-12")}, {decree_date => "2015-11-27"}), # keppres 20/2020 (2020-11-27), surat edaran menaker m/14/hk.04/xii/2020 (2020-12-07)
        # - christmas
    ];

    push @{ $year_holidays{2020} }, (
        _jointlv     ({_expand_dm("21-08")}, {holiday=>$hijra2020}),
        _jointlv     ({_expand_dm("28-10")}, {holiday=>$mawlid2020}),
        _jointlv     ({_expand_dm("30-10")}, {holiday=>$mawlid2020}),
        _jointlv     ({_expand_dm("24-12")}, {holiday=>$christmas}),
        _jointlv     ({_expand_dm("31-12")}, {holiday=>$eidulf2020}),
    );
}

# decreed sep 10, 2020 (SKB No 642/2020, 4/2020, 4/2020)
#
# ref:
# - https://www.menpan.go.id/site/berita-terkini/libur-nasional-dan-cuti-bersama-tahun-2021-sebanyak-23-hari
# - https://www.kemenkopmk.go.id/sites/default/files/artikel/2020-09/SKB%20Cuti%20Bersama%20Tahun%202021.pdf
#
# revised feb 22, 2021: joint leave days reduced from 7 days to 2 days (SKB No. 281/2021, No. 1/2021, No. 1/2021)
# ref:
# - https://www.menpan.go.id/site/berita-terkini/cegah-penularan-covid-19-pemerintah-pangkas-cuti-bersama-2021-jadi-2-hari
# - https://www.kemenkopmk.go.id/sites/default/files/pengumuman/2021-02/SKB%203%20Menteri%20tentang%20Perubahan%20Libnas%20%26%20Cutber%202021%20.pdf
#
# revised jun 18, 2021: hijra moved from aug 10 to aug 11, mawlid moved from oct 19 to oct 20, remove christmas/new year joint leave so total reduced from 2 -> 1 (SKB No. 712/2021, 1/2021, 3/2021)
# ref:
# - https://www.kemenkopmk.go.id/sites/default/files/pengumuman/2021-06/SKB%203%20Menteri%20tentang%20Perubahan%20kedua%20Libur%20Nasional%20dan%20Cuti%20Bersama%202021.pdf

{
    my $isramiraj2021;
    my $eidulf2021;
    $year_holidays{2021} = [
        # - new year
        _h_chnewyear ({_expand_dm("12-02")}, {hyear=>2572}),
        _h_isramiraj ({_expand_dm("11-03")}, {hyear=>1442}),
        _h_nyepi     ({_expand_dm("14-03")}, {hyear=>1943}),
        _h_goodfri   ({_expand_dm("02-04")}),
        # - labor day
        _h_ascension ({_expand_dm("13-05")}),
        ($eidulf2021 = _h_eidulf    ({_expand_dm("13-05")}, {hyear=>1442, day=>1})),
        _h_eidulf    ({_expand_dm("14-05")}, {hyear=>1442, day=>2}),
        _h_vesakha   ({_expand_dm("26-05")}, {hyear=>2565}),
        # - pancasila day
        _h_eidula    ({_expand_dm("20-07")}, {hyear=>1442}),
        _h_hijra     ({_expand_dm("11-08")}, {hyear=>1443, original_date=>"2021-08-10"}),
        # - independence day
        _h_mawlid   ({_expand_dm("20-10")}, {hyear=>1443, original_date=>"2021-10-19"}),
        # - christmas
    ];

    push @{ $year_holidays{2021} }, (
        _jointlv     ({_expand_dm("12-05")}, {holiday=>$eidulf2021}),
    );
}

# decreed sep 22, 2021 (SKB No 963/2021, 3/2021, 4/2021)
#
# ref:
# - https://www.kemenkopmk.go.id/sites/default/files/pengumuman/2021-09/SKB%20Libnas%20%26%20Cuti%20Bersama%20Tahun%202022.pdf
#
# Eid Al-Adha is changed from 9 jul to 10 jul, ref:
# - https://www.kemenag.go.id/read/pemerintah-tetapkan-iduladha-1443-h-jatuh-pada-10-juli-2022
{
    $year_holidays{2022} = [
        # - new year
        _h_chnewyear ({_expand_dm("01-02")}, {hyear=>2573}),
        _h_isramiraj ({_expand_dm("28-02")}, {hyear=>1443}),
        _h_nyepi     ({_expand_dm("03-03")}, {hyear=>1944}),
        _h_goodfri   ({_expand_dm("15-04")}),
        # - labor day
        _h_eidulf    ({_expand_dm("02-05")}, {hyear=>1443, day=>1}),
        _h_eidulf    ({_expand_dm("03-05")}, {hyear=>1443, day=>2}),
        _h_vesakha   ({_expand_dm("16-05")}, {hyear=>2566}),
        _h_ascension ({_expand_dm("26-05")}),
        # - pancasila day
        _h_eidula    ({_expand_dm("10-07")}, {hyear=>1443}),
        _h_hijra     ({_expand_dm("30-07")}, {hyear=>1444}),
        # - independence day
        _h_mawlid({_expand_dm("08-10")}, {hyear=>1444}),
        # - christmas
    ];

    # no joint leave days
    push @{ $year_holidays{2022} }, (
    );
}

# decreed oct 11, 2022 (SKB No 1066/2022, 3/2022, 3/2022)
#
# ref:
# - https://www.kemenkopmk.go.id/pemerintah-terapkan-hari-libur-nasional-dan-cuti-bersama-tahun-2023
#
# superseded mar 29, 2023 (SKB No 327/2023, 1/2023, 1/2023)
# ref:
# - https://setkab.go.id/pemerintah-terbitkan-skb-perubahan-libur-nasional-dan-cuti-bersama-2023/
#
# superseded jun 16, 2023 (SKB No 624/2023, 2/2023, 2/2023)
# ref:
# -
{
    # 2023 holidays
    my ($chnewyear2023, $nyepi2023, $eidulf2023, $eidula2023, $vesakha2023, $christmas);
    $year_holidays{2023} = [
        # - new year
        ($chnewyear2023 = _h_chnewyear ({_expand_dm("22-01")}, {hyear=>2574})),
        _h_isramiraj ({_expand_dm("18-02")}, {hyear=>1444}),
        ($nyepi2023 = _h_nyepi     ({_expand_dm("22-03")}, {hyear=>1945})),
        _h_goodfri   ({_expand_dm("07-04")}),
        ($eidulf2023 = _h_eidulf    ({_expand_dm("22-04")}, {hyear=>1444, day=>1})),
        _h_eidulf    ({_expand_dm("23-04")}, {hyear=>1444, day=>2}),
        # - labor day
        _h_ascension ({_expand_dm("18-05")}),
        # - pancasila day
        _h_vesakha   ({_expand_dm("04-06")}, {hyear=>2567}),
        ($eidula2023 = _h_eidula    ({_expand_dm("29-06")}, {hyear=>1444})),
        _h_hijra     ({_expand_dm("19-07")}, {hyear=>1445}),
        # - independence day
        _h_mawlid({_expand_dm("28-09")}, {hyear=>1445}),
        # - christmas
    ];

    push @{ $year_holidays{2023} }, (
        _jointlv     ({_expand_dm("23-01")}, {holiday=>$chnewyear2023}),
        _jointlv     ({_expand_dm("23-03")}, {holiday=>$nyepi2023}),
        _jointlv     ({_expand_dm("19-04")}, {holiday=>$eidulf2023}),
        _jointlv     ({_expand_dm("20-04")}, {holiday=>$eidulf2023}),
        _jointlv     ({_expand_dm("21-04")}, {holiday=>$eidulf2023}),
        _jointlv     ({_expand_dm("24-04")}, {holiday=>$eidulf2023}),
        _jointlv     ({_expand_dm("25-04")}, {holiday=>$eidulf2023}),
        _jointlv     ({_expand_dm("02-06")}, {holiday=>$vesakha2023}),
        _jointlv     ({_expand_dm("28-06")}, {holiday=>$eidula2023}),
        _jointlv     ({_expand_dm("30-06")}, {holiday=>$eidula2023}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    );
}

# decreed sep 12, 2023 (SKB No 855/2023, 3/2023, 4/2023)
#
# ref:
# - https://kemenkopmk.go.id/sites/default/files/pengumuman/2023-09/SKB%202024.pdf
#
# TODO:
# - renaming of Isa Almasih to Yesus Kristus
# - decree reference for election
{
    # 2024 holidays
    my ($chnewyear2024, $nyepi2024, $eidulf2024, $ascension2024, $eidula2024, $vesakha2024, $christmas);
    local $year = 2024;
    $year_holidays{$year} = [
        # - new year
        _h_isramiraj ({_expand_dm("08-02")}, {hyear=>1445}),
        ($chnewyear2024 = _h_chnewyear ({_expand_dm("10-02")}, {hyear=>2575})),
        _h_pelection ({_expand_dm("14-02")}, {}),
        ($nyepi2024 = _h_nyepi     ({_expand_dm("11-03")}, {hyear=>1946})),
        _h_goodfri   ({_expand_dm("29-03")}),
        _h_easter    ({_expand_dm("31-03")}),
        ($eidulf2024 = _h_eidulf    ({_expand_dm("10-04")}, {hyear=>1445, day=>1})),
        _h_eidulf    ({_expand_dm("11-04")}, {hyear=>1445, day=>2}),
        # - labor day
        ($ascension2024 = _h_ascension ({_expand_dm("09-05")})),
        _h_vesakha   ({_expand_dm("23-05")}, {hyear=>2568}),
        # - pancasila day
        ($eidula2024 = _h_eidula    ({_expand_dm("17-06")}, {hyear=>1445})),
        _h_hijra     ({_expand_dm("07-07")}, {hyear=>1446}),
        # - independence day
        _h_mawlid({_expand_dm("16-09")}, {hyear=>1446}),
        # - christmas
    ];

    push @{ $year_holidays{$year} }, (
        _jointlv     ({_expand_dm("09-02")}, {holiday=>$chnewyear2024}),
        _jointlv     ({_expand_dm("12-03")}, {holiday=>$nyepi2024}),
        _jointlv     ({_expand_dm("08-04")}, {holiday=>$eidulf2024}),
        _jointlv     ({_expand_dm("09-04")}, {holiday=>$eidulf2024}),
        _jointlv     ({_expand_dm("12-04")}, {holiday=>$eidulf2024}),
        _jointlv     ({_expand_dm("15-04")}, {holiday=>$eidulf2024}),
        _jointlv     ({_expand_dm("10-05")}, {holiday=>$ascension2024}),
        _jointlv     ({_expand_dm("24-05")}, {holiday=>$vesakha2024}),
        _jointlv     ({_expand_dm("18-06")}, {holiday=>$eidula2024}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    );
}

# decreed oct 14, 2024 (SKB No 1017/2024, 2/2024, 2/2024)
#
# ref:
# - https://www.kemenkopmk.go.id/sites/default/files/pengumuman/2024-10/SKB%203%20Menteri%20Libur%20Nasional%20dan%20Cuti%20Bersama%20Tahun%202025.pdf
{
    # 2025 holidays
    my ($chnewyear2025, $nyepi2025, $eidulf2025, $ascension2025, $eidula2025, $vesakha2025, $christmas);
    local $year = 2025;
    $year_holidays{$year} = [
        # - new year
        _h_isramiraj ({_expand_dm("27-01")}, {hyear=>1446}),
        ($chnewyear2025 = _h_chnewyear ({_expand_dm("29-01")}, {hyear=>2576})),
        ($nyepi2025 = _h_nyepi({_expand_dm("29-03")}, {hyear=>1947})),
        ($eidulf2025 = _h_eidulf({_expand_dm("31-03")}, {hyear=>1446, day=>1})),
        _h_eidulf    ({_expand_dm("01-04")}, {hyear=>1446, day=>2}),
        _h_goodfri   ({_expand_dm("18-04")}),
        _h_easter    ({_expand_dm("20-04")}),
        # - labor day
        _h_vesakha   ({_expand_dm("12-05")}, {hyear=>2569}),
        ($ascension2025 = _h_ascension({_expand_dm("29-05")})),
        # - pancasila day
        ($eidula2025 = _h_eidula({_expand_dm("06-06")}, {hyear=>1446})),
        _h_hijra     ({_expand_dm("27-06")}, {hyear=>1447}),
        # - independence day
        _h_mawlid({_expand_dm("05-09")}, {hyear=>1447}),
        # - christmas
    ];

    push @{ $year_holidays{$year} }, (
        _jointlv     ({_expand_dm("28-01")}, {holiday=>$chnewyear2025}),
        _jointlv     ({_expand_dm("28-03")}, {holiday=>$nyepi2025}),
        _jointlv     ({_expand_dm("02-04")}, {holiday=>$eidulf2025}),
        _jointlv     ({_expand_dm("03-04")}, {holiday=>$eidulf2025}),
        _jointlv     ({_expand_dm("04-04")}, {holiday=>$eidulf2025}),
        _jointlv     ({_expand_dm("07-04")}, {holiday=>$eidulf2025}),
        _jointlv     ({_expand_dm("13-05")}, {holiday=>$vesakha2025}),
        _jointlv     ({_expand_dm("30-05")}, {holiday=>$ascension2025}),
        _jointlv     ({_expand_dm("09-06")}, {holiday=>$eidula2025}),
        _jointlv     ({_expand_dm("26-12")}, {holiday=>$christmas}),
    );
}

{
    # 2026 holidays
    1;
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
        if (ref $h->{ind_name} eq 'CODE') {
            $h->{ind_name} = $h->{ind_name}->({year=>$year});
        }
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

    push @holidays, _uniquify_holidays(@hf, @hy);
}

my $res = gen_read_table_func(
    name => 'list_idn_holidays',
    table_data => \@holidays,
    table_spec => {
        fields => {
            date => {
                schema     => 'date*',
                pos        => 0,
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
            },
            ind_name => {
                schema     => 'str*',
                summary    => 'Indonesian name',
                pos        => 6,
            },
            eng_aliases => {
                schema     => ['array*'=>{of=>'str*'}],
                summary    => 'English other names, if any',
                pos        => 7,
            },
            ind_aliases => {
                schema     => ['array*'=>{of=>'str*'}],
                summary    => 'Indonesian other names, if any',
                pos        => 8,
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
            },
            decree_note => {
                schema     => 'str',
                pos        => 12,
            },
            note => {
                schema     => 'str',
                pos        => 13,
            },
            tags => {
                schema     => 'array*',
                pos        => 14,
            },
        },
        pk => 'date',
    },
    langs => ['en_US', 'id_ID'],
);

die "BUG: Can't generate func: $res->[0] - $res->[1]"
    unless $res->[0] == 200;

delete $SPEC{list_idn_holidays}{args}{queries}{pos};
delete $SPEC{list_idn_holidays}{args}{queries}{slurpy};
$SPEC{list_idn_holidays}{args}{year}{pos}  = 0;
$SPEC{list_idn_holidays}{args}{month}{pos} = 1;

my $TEXT_AVAILABLE_YEARS = "Contains data from years $min_year to $max_year";

my $TEXT_WORKDAY_DEFINITION = <<'_';
Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.
_

    my $meta = $res->[2]{meta};
$meta->{summary} = "List Indonesian holidays in calendar";
$meta->{description} = <<"_";

List holidays and joint leave days ("cuti bersama").

$TEXT_AVAILABLE_YEARS

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

$SPEC{list_idn_workdays} = {
    v => 1.1,
    summary => 'List working days (non-holiday business days) for a certain period',
    description => <<"_",

$TEXT_WORKDAY_DEFINITION

$TEXT_AVAILABLE_YEARS

_
    args => {
        start_date => {
            summary => 'Starting date',
            schema  => 'str*',
            pos => 0,
            description => <<'_',

Defaults to start of current month. Either a string in the form of "YYYY-MM-DD",
or a DateTime object, is accepted.

_
        },
        end_date => {
            summary => 'End date',
            schema  => 'str*',
            pos => 1,
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
            cmdline_aliases => {j=>{}},
        },
    },
};
sub list_idn_workdays {
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
    my $res = list_idn_holidays(@args);
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
        next if grep { $_ eq $ymd } @{$res->[2]};
        push @wd, $ymd;
    }

    [200, "OK", \@wd];
}

gen_modified_sub(
    output_name => 'count_idn_workdays',
    summary     => "Count working days (non-holiday business days) for a certain period",

    base_name   => 'list_idn_workdays',
    output_code => sub {
        my $res = list_idn_workdays(@_);
        return $res unless $res->[0] == 200;
        $res->[2] = @{$res->[2]};
        $res;
    },
);

$SPEC{is_idn_holiday} = {
    v => 1.1,
    summary => 'Check whether a date is an Indonesian holiday',
    description => <<'_',

Will return boolean if a given date is a holiday. A joint leave day will not
count as holiday unless you specify `include_joint_leave` option.

Date can be given using separate `day` (of month), `month`, and `year`, or as a
single YYYY-MM-DD date.

Will return undef (exit code 2 on CLI) if year is not within range of the
holiday data.

Note that you can also use `list_idn_holidays` to check whether a `date` (or a
combination of `day`, `month`, and `year`) is a holiday , but `is_idn_holiday`
is slightly more efficient, its `include_joint_leave` option is more convenient,
and it offers a few more options.

_
    args => {
        %argspecs_date_or_day_month_year,

        include_joint_leave => {schema=>'bool*', cmdline_aliases=>{j=>{}}},
        reverse    => {schema=>'bool*', cmdline_aliases=>{r=>{}}},
        quiet      => {schema=>'bool*', cmdline_aliases=>{q=>{}}},
        detail     => {schema=>'bool*', cmdline_aliases=>{l=>{}}},
    },
    args_rels => {
        %argsrels_date_or_day_month_year,
    },
};
sub is_idn_holiday {
    my %args = @_;

    my $res = _get_date_day_month_year(\%args);
    return $res unless $res->[0] == 200;
    my ($date, $y, $m, $d) = @{ $res->[2] };

    for my $e (@fixed_holidays) {
        next if defined $e->{year_start} && $y < $e->{year_start};
        next if defined $e->{year_end} && $y > $e->{year_end};
        next unless $e->{day} == $d && $e->{month} == $m;
        return [200, "OK", ($args{reverse} ? 0 : ($args{detail} ? $e : 1)), {
            'cmdline.exit_code' => ($args{reverse} ? 1 : 0),
            ('cmdline.result' => ($args{quiet} ? '' : "Date $date IS a holiday")) x !$args{detail},
        }];
    }

    unless ($y >= $min_year && $y <= $max_year) {
        return [200, "OK", undef, {
            'cmdline.exit_code' => 2,
            'cmdline.result' => ($args{quiet} ? '' : "Date year ($y) is not within range of holiday data ($min_year-$max_year)"),
        }];
    }

    for my $e (@{ $year_holidays{$y} }) {
        next unless $e->{day} == $d && $e->{month} == $m;
        next if $e->{is_joint_leave} && !$args{include_joint_leave};
        return [200, "OK", ($args{reverse} ? 0 : ($args{detail} ? $e : 1)), {
            'cmdline.exit_code' => ($args{reverse} ? 1 : 0),
            ('cmdline.result' => ($args{quiet} ? '' : "Date $date IS a holiday")) x !$args{detail},
        }];
    }

    return [200, "OK", ($args{reverse} ? 1:0), {
        'cmdline.exit_code' => ($args{reverse} ? 0 : 1),
        'cmdline.result' => ($args{quiet} ? '' : "Date $date is NOT a holiday"),
    }];
}

gen_modified_sub(
    output_name => 'is_idn_workday',
    summary     => "Check whether a date is a working day (non-holiday business day)",
    base_name   => 'count_idn_workdays',
    modify_meta => sub {
        my $meta = shift;
        delete $meta->{args}{start_date};
        delete $meta->{args}{end_date};
        $meta->{args}{$_} = $argspecs_date_or_day_month_year{$_}
            for keys %argspecs_date_or_day_month_year;
        $meta->{args_rels} = {
            %argsrels_date_or_day_month_year,
        };
    },
    output_code => sub {
        my %args = @_;

        my $res = _get_date_day_month_year(\%args);
        return $res unless $res->[0] == 200;
        my ($date, $y, $m, $d) = @{ $res->[2] };

        delete $args{date};
        delete $args{day};
        delete $args{month};
        delete $args{year};

        $res = count_idn_workdays(%args, start_date=>$date, end_date=>$date);
        return $res unless $res->[0] == 200;
        $res;
    },
);

1;
# ABSTRACT: List Indonesian public holidays

__END__

=pod

=encoding UTF-8

=head1 NAME

Calendar::Indonesia::Holiday - List Indonesian public holidays

=head1 VERSION

This document describes version 0.353 of Calendar::Indonesia::Holiday (from Perl distribution Calendar-Indonesia-Holiday), released on 2025-03-29.

=head1 SYNOPSIS

 use Calendar::Indonesia::Holiday qw(
     list_idn_holidays
     list_idn_workdays

     count_idn_workdays

     is_idn_holiday
     is_idn_workday
 );

This lists Indonesian holidays for the year 2011, without the joint leave days
("cuti bersama"), showing only the dates:

 my $res = list_idn_holidays(year => 2011, is_joint_leave=>0);

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

 my $res = list_idn_holidays(year => 2011,
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

 my $res = is_idn_holiday(date => '2011-02-16');
 print "2011-02-16 is a holiday\n" if $res->[2];

This checks whether 2021-03-11 is a working day:

 my $res = is_idn_workday(date => '2021-03-11');
 print "2011-02-16 is a holiday\n" if $res->[2];

This lists working days for a certain period:

 my $res = list_idn_workdays(start_date=>'2021-01-01', end_date=>'2021-06-30');

Idem, but returns a number instead. If unspecified, C<start_date> defaults to
start of current month and C<end_date> defaults to end of current month. So this
returns the number of working days in the current month:

 my $res = count_idn_workdays();

=head1 DESCRIPTION

This module provides functions to list Indonesian holidays. There is a
command-line script interface for this module: L<list-idn-holidays> and a few
others distributed in L<App::IndonesianHolidayUtils> distribution.

Calendar years supported: 1990-2025.

Note: Note that sometimes the holiday (as set by law) falls at a different date
than the actual religious commemoration date. When you use the C<detail> option,
the C<original_date> key will show you the actual religious date.

Note: it is also possible that multiple (religious, cultural) holidays fall on
the same national holiday. An example is May 8, 1997 which is commemorated as
Hijra 1418H as well as Ascension Day. When this happens, the C<holidays> key
will contain the details of each religious/cultural holiday.

Caveat: aside from national holidays, some provinces sometimes declare their own
(e.g. governor election day for East Java province, etc). This is currently not
yet included in this module.

=head1 DEVELOPER NOTES

To mark that a holiday has been moved from its original date, use the
C<original_date> option. For example, Mawlid in 2021 has been moved from its
original date 2021-11-19 (this is the day it is actually observed/commemorated)
to 2021-11-20 (this is the day the holiday is in effect where offices and public
places are closed). By adding this option, the summary will reflect this
information:

 date: 2021-12-20
 eng_name: Mawlid (commemorated on 2021-12-19)
 ind_name: Maulid Nabi Muhammad (diperingati 2021-12-19)

=head1 FUNCTIONS


=head2 count_idn_workdays

Usage:

 count_idn_workdays(%args) -> [$status_code, $reason, $payload, \%result_meta]

Count working days (non-holiday business days) for a certain period.

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

Contains data from years 1990 to 2025

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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_idn_holiday

Usage:

 is_idn_holiday(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether a date is an Indonesian holiday.

Will return boolean if a given date is a holiday. A joint leave day will not
count as holiday unless you specify C<include_joint_leave> option.

Date can be given using separate C<day> (of month), C<month>, and C<year>, or as a
single YYYY-MM-DD date.

Will return undef (exit code 2 on CLI) if year is not within range of the
holiday data.

Note that you can also use C<list_idn_holidays> to check whether a C<date> (or a
combination of C<day>, C<month>, and C<year>) is a holiday , but C<is_idn_holiday>
is slightly more efficient, its C<include_joint_leave> option is more convenient,
and it offers a few more options.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<str>

(No description)

=item * B<day> => I<int>

(No description)

=item * B<detail> => I<bool>

(No description)

=item * B<include_joint_leave> => I<bool>

(No description)

=item * B<month> => I<int>

(No description)

=item * B<quiet> => I<bool>

(No description)

=item * B<reverse> => I<bool>

(No description)

=item * B<year> => I<int>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 is_idn_workday

Usage:

 is_idn_workday(%args) -> [$status_code, $reason, $payload, \%result_meta]

Check whether a date is a working day (non-holiday business day).

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

Contains data from years 1990 to 2025

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<date> => I<str>

(No description)

=item * B<day> => I<int>

(No description)

=item * B<month> => I<int>

(No description)

=item * B<observe_joint_leaves> => I<bool> (default: 1)

If set to 0, do not observe joint leave as holidays.

=item * B<work_saturdays> => I<bool> (default: 0)

If set to 1, Saturday is a working day.

=item * B<year> => I<int>

(No description)


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_idn_holidays

Usage:

 list_idn_holidays(%args) -> [$status_code, $reason, $payload, \%result_meta]

List Indonesian holidays in calendar.

List holidays and joint leave days ("cuti bersama").

Contains data from years 1990 to 2025

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

=item * B<eng_aliases> => I<array>

Only return records where the 'eng_aliases' field equals specified value.

=item * B<eng_aliases.has> => I<array[str]>

Only return records where the 'eng_aliases' field is an arrayE<sol>list which contains specified value.

=item * B<eng_aliases.is> => I<array>

Only return records where the 'eng_aliases' field equals specified value.

=item * B<eng_aliases.isnt> => I<array>

Only return records where the 'eng_aliases' field does not equal specified value.

=item * B<eng_aliases.lacks> => I<array[str]>

Only return records where the 'eng_aliases' field is an arrayE<sol>list which does not contain specified value.

=item * B<eng_name> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.contains> => I<str>

Only return records where the 'eng_name' field contains specified text.

=item * B<eng_name.in> => I<array[str]>

Only return records where the 'eng_name' field is in the specified values.

=item * B<eng_name.is> => I<str>

Only return records where the 'eng_name' field equals specified value.

=item * B<eng_name.isnt> => I<str>

Only return records where the 'eng_name' field does not equal specified value.

=item * B<eng_name.max> => I<str>

Only return records where the 'eng_name' field is less than or equal to specified value.

=item * B<eng_name.min> => I<str>

Only return records where the 'eng_name' field is greater than or equal to specified value.

=item * B<eng_name.not_contains> => I<str>

Only return records where the 'eng_name' field does not contain specified text.

=item * B<eng_name.not_in> => I<array[str]>

Only return records where the 'eng_name' field is not in the specified values.

=item * B<eng_name.xmax> => I<str>

Only return records where the 'eng_name' field is less than specified value.

=item * B<eng_name.xmin> => I<str>

Only return records where the 'eng_name' field is greater than specified value.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<ind_aliases> => I<array>

Only return records where the 'ind_aliases' field equals specified value.

=item * B<ind_aliases.has> => I<array[str]>

Only return records where the 'ind_aliases' field is an arrayE<sol>list which contains specified value.

=item * B<ind_aliases.is> => I<array>

Only return records where the 'ind_aliases' field equals specified value.

=item * B<ind_aliases.isnt> => I<array>

Only return records where the 'ind_aliases' field does not equal specified value.

=item * B<ind_aliases.lacks> => I<array[str]>

Only return records where the 'ind_aliases' field is an arrayE<sol>list which does not contain specified value.

=item * B<ind_name> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.contains> => I<str>

Only return records where the 'ind_name' field contains specified text.

=item * B<ind_name.in> => I<array[str]>

Only return records where the 'ind_name' field is in the specified values.

=item * B<ind_name.is> => I<str>

Only return records where the 'ind_name' field equals specified value.

=item * B<ind_name.isnt> => I<str>

Only return records where the 'ind_name' field does not equal specified value.

=item * B<ind_name.max> => I<str>

Only return records where the 'ind_name' field is less than or equal to specified value.

=item * B<ind_name.min> => I<str>

Only return records where the 'ind_name' field is greater than or equal to specified value.

=item * B<ind_name.not_contains> => I<str>

Only return records where the 'ind_name' field does not contain specified text.

=item * B<ind_name.not_in> => I<array[str]>

Only return records where the 'ind_name' field is not in the specified values.

=item * B<ind_name.xmax> => I<str>

Only return records where the 'ind_name' field is less than specified value.

=item * B<ind_name.xmin> => I<str>

Only return records where the 'ind_name' field is greater than specified value.

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

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

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

Only return records where the 'tags' field is an arrayE<sol>list which contains specified value.

=item * B<tags.is> => I<array>

Only return records where the 'tags' field equals specified value.

=item * B<tags.isnt> => I<array>

Only return records where the 'tags' field does not equal specified value.

=item * B<tags.lacks> => I<array[str]>

Only return records where the 'tags' field is an arrayE<sol>list which does not contain specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)



=head2 list_idn_workdays

Usage:

 list_idn_workdays(%args) -> [$status_code, $reason, $payload, \%result_meta]

List working days (non-holiday business days) for a certain period.

Working day is defined as day that is not Saturday*/Sunday/holiday/joint leave
days*. If work_saturdays is set to true, Saturdays are also counted as working
days. If observe_joint_leaves is set to false, joint leave days are also counted
as working days.

Contains data from years 1990 to 2025

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

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=for Pod::Coverage ^(.+_id_.+)$

=head1 FAQ

=head2 What is "joint leave"?

Workers are normally granted around 12 days of paid leave per year (excluding
special leaves like maternity, etc). They are free to spend them on whichever
days they want. The joint leave ("cuti bersama") is a government program to
recommend that some of these leave days be spent together nationally on certain
assigned days, especially adjacent to holidays like Eid Ul-Fitr ("Lebaran"). It
is not mandated (companies can opt to follow it or not, depending on their
specific situation), but many do follow it anyway, e.g. government civil
workers, banks, etc. I am marking joint leave days with is_joint_leave=1 and
is_holiday=0, while the holidays themselves with is_holiday=1, so you can
differentiate/select both/either one.

=head2 When was joint leave established?

Joint leave was first decreed in 2001 [1] for the 2002 & 2003 calendar years.
The 2001 calendar year does not yet have joint leave days [2]. See also [3].
Websites that list joint leave days for 2001 or earlier years (example: [4],
[5]) are incorrect; by 2001 or earlier, these joint leave days had not been
officially decreed by the government.

[1] https://jdih.kemnaker.go.id/data_wirata/2002-4-4.pdf

[2] https://peraturan.bkpm.go.id/jdih/userfiles/batang/Kepmenag_162_2000.pdf

[3] http://www.wikiapbn.org/cuti-bersama/

[4] https://kalenderindonesia.com/libur/masehi/2001

[5] https://kalenderindonesia.com/libur/masehi/1991

=head2 What happens when multiple religious/holidays coincide on a single calendar day?

For example, in 1997, both Hijra and Ascension Day fall on May 8th. When this
happens, C<ind_name> and C<eng_name> will contain all the names of the holidays
separated by comma, respectively:

 Tahun Baru Hijriah, Kenaikan Isa Al-Masih
 Hijra, Ascension Day

All the properties that have the same value will be set in the merged holiday
data:

 is_holiday => 1,
 is_joint_leave => 1,

The C<multiple> property will also be set to true:

 multiple => 1,

All the tags will be merged:

 tags => ['religious', 'religion=christianity', 'calendar=lunar']

You can get each holiday's data in the C<holidays> key.

=head2 Data for older holidays?

Will be provided if there is demand and data source.

=head2 Holidays after (current year)+1?

Some religious holidays, especially Vesakha, are not determined yet. Joint leave
days are also usually decreed by the government in as late as October/November
in the preceding year.

=head2 How to calculate the difference of two dates in number of working days?

Use L</count_idn_workdays>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Calendar-Indonesia-Holiday>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Calendar-Indonesia-Holiday>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Steven Haryanto

Steven Haryanto <stevenharyanto@gmail.com>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Calendar-Indonesia-Holiday>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
