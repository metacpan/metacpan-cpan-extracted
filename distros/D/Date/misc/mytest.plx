#!/usr/bin/perl
use 5.012;
use lib 'blib/lib', 'blib/arch';
use Benchmark qw/timethis timethese/;
use Scalar::Util qw/blessed/;
use POSIX();
use Date qw/now today date rdate :const idate/;
use Time::XS qw/tzget tzset/;
use Class::Date;
use Data::Dumper qw/Dumper/;
use Storable qw/freeze nfreeze thaw dclone/;
say "START";

my $date = Date::now();
timethis(-1, sub { $date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch;$date->epoch; });

sub p { 
    my $pdate = shift; 
    printf "%s tz:%s dst:%s epoch:%s\n", $pdate->string, $pdate->tz->{name}, $pdate->isdst ? 'Y' : 'N', $pdate->epoch; 
}; 

#-- dst starts at 01:00 
my $date = Date->new('2014-03-30 00:59:59'); 
$date->tz('Europe/London'); 
p($date); 
my $delta = Date::Rel->new({sec => 1}); 
$date->add($delta); 
p($date); 
$date->subtract($delta); 
p($date); 

#output: 
#2014-03-30 00:59:59 tz:Europe/London dst:N epoch:1396141199 
#2014-03-30 02:00:00 tz:Europe/London dst:Y epoch:1396141200 
#2014-03-30 02:59:59 tz:Europe/London dst:Y epoch:1396144799

# I would expect value '2014-03-30 00:59:59' as a last result.

exit;

tzset();
POSIX::tzset();

*my_gmtime = *Time::XS::gmtime;
*my_timegm = *Time::XS::timegm;
*my_timegmn = *Time::XS::timegmn;
*my_localtime = *Time::XS::localtime;
*my_timelocal = *Time::XS::timelocal;
*my_timelocaln = *Time::XS::timelocaln;
*systimegm = *Time::XS::systimegm;
*systimelocal = *Time::XS::systimelocal;

*gmtime_bench = *Time::XS::gmtime_bench;
*timegm_bench = *Time::XS::timegm_bench;
*timegml_bench = *Time::XS::timegml_bench;
*localtime_bench = *Time::XS::localtime_bench;
*timelocal_bench = *Time::XS::timelocal_bench;
*timelocall_bench = *Time::XS::timelocall_bench;
*posix_gmtime_bench = *Time::XS::posix_gmtime_bench;
*posix_localtime_bench = *Time::XS::posix_localtime_bench;
*posix_timegm_bench = *Time::XS::posix_timegm_bench;
*posix_timelocal_bench = *Time::XS::posix_timelocal_bench;
*bmy = *Time::XS::bench_my;

my $tz = $ENV{TZ};
my $zone = tzget($tz);
say Dumper($zone);

my %dates = (
    vneg => [-100000000000, [20, 13, 14, 15, 1, -1199]],
    neg  => [-100000000, [20, 13, 14, 31, 9, 1966]],
    pos  => [1300000000, [40, 6, 7, 13, 2, 2011]],
    fut  => [10000000000, [40, 46, 17, 20, 10, 2286]],
);

my %funcs = (
    mygt  => [0, \&gmtime_bench],
    osgt  => [0, \&posix_gmtime_bench],
    mytg  => [1, \&timegm_bench],
    mytgl => [1, \&timegml_bench],
    ostg  => [1, \&posix_timegm_bench],
    
    mylt  => [0, \&localtime_bench],
    oslt  => [0, \&posix_localtime_bench],
    mytl  => [1, \&timelocal_bench],
    mytll => [1, \&timelocall_bench],
    ostl  => [1, \&posix_timelocal_bench],
);

my %to_test;

while (my ($fname, $fdata) = each %funcs) {
    while (my ($dname, $ddata) = each %dates) {
        my $val = $ddata->[$fdata->[0]];
        my $func = $fdata->[1];
        if (ref($val) eq 'ARRAY') {
            my @arr = @$val;
            $to_test{"${fname}_$dname"} = sub { $func->(@arr) };
        } else {
            $to_test{"${fname}_$dname"} = sub { $func->($val) };
            say join(', ', $dname, my_gmtime($val));
        }
    }
}

my ($isdst,$Y,$M,$D,$h,$m,$s) = (1,2010,0,1,0,0,0);
timethese(-1, \%to_test);

exit;

if (my $datestr = shift @ARGV) {
    test_one_tl($datestr);
    exit;
}

my ($a, $b, $c, $d, $e, $f) = ([], [], [], [], [], []);
exit;

timethese(-1, {
#    c_my_gmtime_pos     => sub { gmtime_bench(1000000000000); },
#    c_my_gmtime_neg     => sub { gmtime_bench(-1000000000); },
#    c_my_gmtime_vneg    => sub { gmtime_bench(-1000000000000); },
#    c_posix_gmtime_pos  => sub { posix_gmtime_bench(1000000000000); },
#    c_posix_gmtime_neg  => sub { posix_gmtime_bench(-1000000000); },
#    c_posix_gmtime_vneg => sub { posix_gmtime_bench(-1000000000000); },
#    xs_my_gmtime            => sub { my $a = my_gmtime(10000000000); },
#    xs_core_gmtime          => sub { my $a = gmtime(10000000000); },
    c_my_timegm_lite_pos => sub { timegm_lite_bench(20, 15, 18, 28, 2, 2013) },
    c_my_timegm_lite_neg => sub { timegm_lite_bench(20, 15, 18, 28, 0, -2900) },
    c_my_timegm_pos      => sub { timegm_bench(20, 15, 18, 28, 2, 2013) },
    c_my_timegm_neg      => sub { timegm_bench(20, 15, 18, 28, 0, -2900) },
    c_posix_timegm_pos   => sub { posix_timegm_bench(20, 15, 18, 28, 2, 2013) },
    c_posix_timegm_neg   => sub { posix_timegm_bench(20, 15, 18, 28, 0, -2900) },
#    xs_my_timegm_pos            => sub { my $a = my_timegm(20, 15, 18, 28, 2, 2013); },
#    xs_core_timegm_pos          => sub { my $a = timegm(20, 15, 18, 28, 2, 113); },
#    xs_my_timegm_neg            => sub { my $a = my_timegm(20, 15, 18, 28, 0, -2900); },
#    xs_core_timegm_neg          => sub { my $a = timegm(20, 15, 18, 28, 2, 0, -2900); },
#    c_my_localtime_pos     => sub { localtime_bench(1000000000); },
#    c_my_localtime_posf    => sub { localtime_bench(520000000000); },
#    c_my_localtime_neg     => sub { localtime_bench(-1000000000); },
#    c_my_localtime_vneg    => sub { localtime_bench(-10000000000); },
#    c_posix_localtime_pos  => sub { posix_localtime_bench(1000000000); },
#    c_posix_localtime_posf => sub { posix_localtime_bench(520000000000); },
#    c_posix_localtime_neg  => sub { posix_localtime_bench(-1000000000); },
#    c_posix_localtime_vneg => sub { posix_localtime_bench(-10000000000); },
    #c_my_timelocal_pos => sub { timelocal_bench(40, 46, 5, 9, 8, 2001) },
    #c_my_timelocal_posf => sub { timelocal_bench(40, 46, 13, 16, 10, 5138) },
    #c_my_timelocal_neg => sub { timelocal_bench(20, 13, 1, 25, 3, 1938) },
    #c_my_timelocal_vneg => sub { timelocal_bench(40, 43, 8, 10, 1, 1653) },
    #c_posix_timelocal_pos => sub { posix_timelocal_bench(40, 46, 5, 9, 8, 2001) },
    #c_posix_timelocal_posf => sub { posix_timelocal_bench(40, 46, 13, 16, 10, 5138) },
    #c_posix_timelocal_neg => sub { posix_timelocal_bench(20, 13, 1, 25, 3, 1938) },
    #c_posix_timelocal_vneg => sub { posix_timelocal_bench(40, 43, 8, 10, 1, 1653) },
});

sub test_one_tl {
    my ($str) = shift;
    die "CANNOT PARSE" unless $str =~ m#^(-?\d+)[/-](-?\d+)[/-](-?\d+) (-?\d+):(-?\d+):(-?\d+)$#;
    my ($Y, $M, $D, $h, $m, $s) = ($1, $2, $3, $4, $5, $6);
    say sprintf("%04d-%02d-%02d %02d:%02d:%02d", $Y, $M, $D, $h, $m, $s);
    $M--;
    my $b = systimelocal($s, $m, $h, $D, $M, $Y-1900);
    my $isdst = -1;
    my $a = my_timelocaln($s, $m, $h, $D, $M, $Y, $isdst);
    say "MY: $a ".my_localtime($a).sprintf(" (%04d-%02d-%02d %02d:%02d:%02d)", $Y, $M+1, $D, $h, $m, $s);
    say "OS: $b ".localtime($b);
}
