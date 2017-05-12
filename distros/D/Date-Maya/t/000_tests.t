# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

our $r = eval "require Test::NoWarnings; 1";

my $tests = 66 + ($r || 0);
print "1..$tests\n";

END {print "not ok 1\n" unless $loaded;}
use Date::Maya qw /:DEFAULT :MAYA_EPOCH maya_epoch/;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my @list1 = (
    [2451432 => ['12.19.6.9.7',    '13 Manik',  '15 Mol'   ]],
    [2451433 => ['12.19.6.9.8',     '1 Lamat',  '16 Mol'   ]],
    [2456285 => ['13.0.0.0.0',      '4 Ahau',    '3 Kankin']],
    [2456283 => ['12.19.19.17.18',  '2 Etznab',  '1 Kankin']],
    [ 584295 => ['13.0.0.0.10',     '1 Oc',     '18 Cumku' ]],
    [ 584296 => ['13.0.0.0.11',     '2 Chuen',  '19 Cumku' ]],
);

my @list2 = (
    ['12.19.6.9.7'    => 2451432],
    ['12.19.6.9.8'    => 2451433],
    ['13.0.0.0.0'     =>  584285],
    ['12.19.19.17.18' => 2456283],
    ['13.0.0.0.10'    =>  584295],
    ['13.0.0.0.11'    =>  584296],
);


my @list3 = (
    [2451432 => ['13.12.10.2.8',   '1 Lamat',  '16 Mol'   ]],
    [2451433 => ['13.12.10.2.9',   '2 Muluc',  '17 Mol'   ]],
    [2456285 => ['13.13.3.11.1',   '5 Imix',    '4 Kankin']],
    [2456283 => ['13.13.3.10.19',  '3 Caunac',  '2 Kankin']],
    [ 489396 => ['13.0.0.0.12',    '3 Eb',      '0 Uayeb' ]],
    [ 489397 => ['13.0.0.0.13',    '4 Ben',     '1 Uayeb' ]],
);

my @list4 = (
    ['13.0.0.0.12'    =>  489396],
    ['13.0.0.0.13'    =>  489397],
);

my $t = 1;

foreach my $entry (@list1) {
    my ($jd, $maya)     = @$entry;
    my  $lc1            = julian_to_maya $jd;
    my ($lc2, $tz, $hb) = julian_to_maya $jd;
    $t ++; print $lc1 eq $maya -> [0] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $lc2 eq $maya -> [0] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $tz  eq $maya -> [1] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $hb  eq $maya -> [2] ? "ok $t\n" : "not ok $t\n";
}

foreach my $entry (@list2) {
    my ($lc, $jd) = @$entry;
    my  $jd1      = maya_to_julian $lc;
    $t ++; print $jd == $jd1 ? "ok $t\n" : "not ok $t\n";
}

maya_epoch MAYA_EPOCH3;


foreach my $entry (@list3) {
    my ($jd, $maya)     = @$entry;
    my  $lc1            = julian_to_maya $jd;
    my ($lc2, $tz, $hb) = julian_to_maya $jd;
    $t ++; print $lc1 eq $maya -> [0] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $lc2 eq $maya -> [0] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $tz  eq $maya -> [1] ? "ok $t\n" : "not ok $t\n";
    $t ++; print $hb  eq $maya -> [2] ? "ok $t\n" : "not ok $t\n";
}

foreach my $entry (@list4) {
    my ($lc, $jd) = @$entry;
    my  $jd1      = maya_to_julian $lc;
    $t ++; print $jd == $jd1 ? "ok $t\n" : "not ok $t\n";
}

eval {&maya_to_julian};
$t++; print $@ =~ /^Failed to supply argument/ ? "ok $t\n" : "not ok $t\n";

eval {maya_to_julian undef};
$t++; print $@ =~ /^Undefined argument/ ? "ok $t\n" : "not ok $t\n";

eval {maya_to_julian "Froob"};
$t++; print $@ =~ /^Illegal argument/ ? "ok $t\n" : "not ok $t\n";

eval {maya_to_julian "10.9.24.0.0"};
$t++; print $@ =~ /^Out of bounds/ ? "ok $t\n" : "not ok $t\n";

eval {maya_to_julian "10.9.4.19.0"};
$t++; print $@ =~ /^Out of bounds/ ? "ok $t\n" : "not ok $t\n";

eval {&julian_to_maya};
$t++; print $@ =~ /^No argument/ ? "ok $t\n" : "not ok $t\n";

eval {julian_to_maya undef};
$t++; print $@ =~ /^Undefined argument/ ? "ok $t\n" : "not ok $t\n";

eval {julian_to_maya "Froob"};
$t++; print $@ =~ /^Illegal argument/ ? "ok $t\n" : "not ok $t\n";

eval {julian_to_maya 0};
$t++; print $@ =~ /^Cannot deal with dates/ ? "ok $t\n" : "not ok $t\n";


if ($r) {
    my @w = Test::NoWarnings::warnings ();
    $t ++;
    print @w ? "not ok $t\n" : "ok $t\n";
}
