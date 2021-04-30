use Test::More;
use Test::Deep;
use Ouch;

if ($ENV{TEST_LOGGING}) {
    my $logging_conf = q(
        log4perl.logger = DEBUG, mainlog
        log4perl.appender.mainlog          = Log::Log4perl::Appender::File
        log4perl.appender.mainlog.filename = test.log
        log4perl.appender.mainlog.layout   = PatternLayout
        log4perl.appender.mainlog.layout.ConversionPattern = %d %p %m %n
    );

    use Log::Log4perl;
    Log::Log4perl::init(\$logging_conf);
    use Log::Any::Adapter;
    Log::Any::Adapter->set('Log4perl');
}

use lib '../lib';
use 5.010;
use Box::Calc::Box;
use strict;

use_ok 'Box::Calc';

use Time::HiRes qw/gettimeofday tv_interval/;


my $t = [gettimeofday()];
my $calc = Box::Calc->new;
note "Time to create Box::Calc object: ".tv_interval($t);

$t = [gettimeofday()];
$calc->add_box_type(x => 6, y => 8, z => 3, weight => 20, name => 'a');
$calc->add_box_type(x => 8, y => 8, z => 12, weight => 20, name => 'b');
$calc->add_box_type(x => 2, y => 6, z => 6, weight => 20, name => 'c');
$calc->add_box_type(x => 10, y => 8, z => 12, weight => 20, name => 'd');
$calc->add_box_type(x => 3, y => 12, z => 10, weight => 20, name => 'e');
$calc->add_box_type(x => 12, y => 12, z => 12, weight => 20, name => 'f');
$calc->add_box_type(x => 10, y => 12, z => 18, weight => 20, name => 'g');
note "Time to add box types: ".tv_interval($t);

$t = [gettimeofday()];
my $plane = $calc->add_item(8000, {x => 2.5, y => 2.25, z => 0.5, name => 'Plane', weight => 1});
my $car = $calc->add_item(1150, {x => 2, y => 0.25, z => 0.125, name => 'Car', weight => 0.1});
my $bills = $calc->add_item(662, {x => 3, y => 2, z => 0.125, name => 'Bills', weight => 0.1});
my $die = $calc->add_item(558, {x => 0.5, y => 0.5, z => 0.5, name => 'Die', weight => 0.1});
note "Time to add 10,000+ parts: ".tv_interval($t);

$t = [gettimeofday()];
$calc->pack_items;
note "Time to pack parts into boxes: ".tv_interval($t);

$t = [gettimeofday()];
$calc->packing_list;
note "Time to generate packing list: ".tv_interval($t);

$t = [gettimeofday()];
$calc->packing_instructions;
note "Time to generate packing instructions: ".tv_interval($t);

ok(1);

done_testing;

