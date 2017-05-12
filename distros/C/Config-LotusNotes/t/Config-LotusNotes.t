# As we do not know how many installations the current machine really has,
# we only do some very basic tests.

BEGIN {
    print "1..0 # Skip win32 required\n" and exit unless $^O =~ /win32|cygwin/i;
}

use strict;
use warnings;
use Test::More;

my $VERSION = '0.34';
my $test_data = 'data';  # directory with test files mocking a Notes install

# expected number of tests
BEGIN {
    plan tests => 10;
    #plan 'no_plan';
}

# load module
BEGIN { use_ok('Config::LotusNotes') or exit; }

# ensure that test data can be found 
BEGIN {chdir 't' if -d 't'}
die "test data directory $test_data not found" unless -d $test_data;

# do we test the expected version?
is($Config::LotusNotes::VERSION, $VERSION, "version = $VERSION");

# all methods available?
can_ok('Config::LotusNotes', qw(new default_configuration all_configurations));

# constructor for the factory object
ok(my $factory = Config::LotusNotes->new, 'constructor');
isa_ok($factory, 'Config::LotusNotes');

{
    # As we do not know anything about the existing Lotus Notes installs 
    # on this computer, we resort to testing with fake data.
    # We locally mock the methods that figure out potential install paths. 

    # get default configuration
    no warnings 'redefine';
    local *Config::LotusNotes::_get_default_location = sub { 'data' };
    ok(my $conf = $factory->default_configuration, 'get default configuration');
    isa_ok($conf, 'Config::LotusNotes::Configuration');

    # get all configurations
    # we supply two existing paths and one invalid location.
    local *Config::LotusNotes::_get_all_locations = sub { qw(data data nothing) };
    my @all_confs = $factory->all_configurations();
    is(@all_confs, 2, 'Two install found');
    isa_ok($all_confs[0], 'Config::LotusNotes::Configuration');
    isa_ok($all_confs[1], 'Config::LotusNotes::Configuration');
}
