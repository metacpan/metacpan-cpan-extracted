use Time::Local;
use Test::More tests => 16;

#first check that I can load the package
BEGIN 
{ use_ok('App::BackupPlan::Utils', qw(fromISO2TS fromTS2ISO addSpan subSpan))}; #test 1

cmp_ok('0.0.9','eq',$App::BackupPlan::Utils::VERSION,'App::BackupPlan::Utils::VERSION'); #test 2

#check conversion ISO date ->timestam -> ISO date
my $iso = '20190415';
my $ts   = fromISO2TS($iso);
my $iso2 = fromTS2ISO($ts);
cmp_ok($iso2, 'eq', $iso,'roundrip from ISO date back to ISO date'); #test 3

#test move two days later
$ts2 = addSpan($ts,'2d');
$iso2 = fromTS2ISO($ts2);
cmp_ok($iso2, 'eq', '20190417','moving to two dayes later'); #test 4

#moving to two days before
$ts2 = subSpan($ts,'2d');
$iso2 = fromTS2ISO($ts2);
cmp_ok($iso2, 'eq', '20190413','moving to two dayes before'); #test 5

#time trasformation tests
my $time = timelocal(0,0,0,15,9,1963);
my $Ts = fromTS2ISO($time);
cmp_ok('19631015','eq',$Ts,'time formatting test'); #test 6

#add 7 days
my $then = addSpan($time,'7d');
my $thenTs = fromTS2ISO($then);
cmp_ok('19631022','eq',$thenTs,'add seven days'); #test 7

#add 4 days near year end
my $yearEnd = timelocal(0,0,0,30,11,2012);
$then = addSpan($yearEnd,'4d');
$thenTs = fromTS2ISO($then);
cmp_ok('20130103','eq',$thenTs,'add four days near year end'); #test 8

#add 2 months
$then = addSpan($time,'2m');
$thenTs = fromTS2ISO($then);		
cmp_ok('19631215','eq',$thenTs,'add two months'); #test 9

#add 3 months near year end
$then = addSpan($yearEnd,'3m');
$thenTs = fromTS2ISO($then);		
cmp_ok('20130330','eq',$thenTs,'add three months near year end'); #test 10

#add 1 year
$then = addSpan($time,'1y');
$thenTs = fromTS2ISO($then);		
cmp_ok('19641015','eq',$thenTs,'add one year'); #test 11

#subtracting 7 days
$then = subSpan($time,'7d');
$thenTs = fromTS2ISO($then);		
cmp_ok('19631008','eq',$thenTs,'subtracting seven days'); #test 12

#subtracting 4 days near year start
my $yearStart = timelocal(0,0,0,3,0,2013);
$then = subSpan($yearStart,'4d');
$thenTs = fromTS2ISO($then);		
cmp_ok('20121230','eq',$thenTs,'subtracting four days near year start'); #test 13

#Subtracting 2 months
$then = subSpan($time,'2m');
$thenTs = fromTS2ISO($then);		
cmp_ok('19630815','eq',$thenTs,'subtracting two months'); #test 14

#Subtracting 3 months near year start
$then = subSpan($yearStart,'3m');
$thenTs = fromTS2ISO($then);		
cmp_ok('20121003','eq',$thenTs,'subtracting three months near year start'); #test 15

#Subtracting 1 year
$then = subSpan($time,'1y');
$thenTs = fromTS2ISO($then);		
cmp_ok('19621015','eq',$thenTs,'subtracting one year'); #test 16

