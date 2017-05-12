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
    plan tests => 22;
    #plan 'no_plan';
}

# load module
BEGIN { use_ok('Config::LotusNotes::Configuration') or exit; }

# ensure that test data can be found 
BEGIN {chdir 't' if -d 't'}
die "test data directory $test_data not found" unless -d $test_data;

# do we test the expected version?
is($Config::LotusNotes::Configuration::VERSION, $VERSION, "version = $VERSION");

# all methods available?
can_ok('Config::LotusNotes::Configuration', qw(
    new 
    notesini  notespath  datapath 
    version   is_client  is_server install_scope
    get_environment_value set_environment_value
));

# constructor should die if called without path argument
eval { Config::LotusNotes::Configuration->new() };
like(
    $@, 
    qr/no Notes install path specified/,
    'constructor dies if no path is supplied'
);

# this should work. If not, exit as the rest of the test will also fail.
ok(
    my $config = Config::LotusNotes::Configuration->new(path => 'data'),
    'constructor successful'
) or exit;
isa_ok($config, 'Config::LotusNotes::Configuration') or exit;

# checking attributes
is($config->notespath, "data",            'notespath attribute');
is($config->datapath,  "d:\\notes\\data", 'datapath attribute' );
is($config->notesini,  "data\\notes.ini", 'notesini attribute' );

is($config->version,  '5.0.10',           'version attribute'  );
is($config->is_client, 1,                 'is_client attribute');
is($config->is_server, '',                'is_server attribute');
is($config->install_scope, 'just for me', 'install_scope'      );

# reading, writing and deleting environment values
is($config->get_environment_value('KitType'             ), 1,      'read existing key');
is($config->get_environment_value('$EmptyKey'           ), '',     'read empty key');
is($config->get_environment_value('$testthewest'        ), undef,  'read undefined key');
ok($config->set_environment_value('$testthewest', 'test'),         'store key' );
is($config->get_environment_value('$testthewest'        ), 'test', 'verify key');
ok($config->set_environment_value('$testthewest', ''    ),         'set empty value');
is($config->get_environment_value('$testthewest'        ), '',     'verify empty value');
ok($config->set_environment_value('$testthewest', undef ),         'delete key');
is($config->get_environment_value('$testthewest'        ), undef,  'verify deleted key');
