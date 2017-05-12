# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Config-File-Simple.t'

#########################

use Test::More tests => 24;

use_ok 'Config::File::Simple';

my $config_file = 'config_sample.txt';

my $config = new Config::File::Simple($config_file);
isa_ok($config, "Config::File::Simple");

my @methods = qw/read multiple_read variable_exists has_special_characters set add change add_comment/;
can_ok($config, $_) foreach @methods;

# scalar context

ok($config->set('foo', 'bar'), "set() successfull");
ok($config->add('quux', 'quuux'), "add() successfull");
ok($config->change('foo', 'foobar'), "change() successfull");
ok($config->read('foo'), "read() successfull");
ok($config->multiple_read('foo'), "multiple_read() successfull");
ok($config->has_special_characters('!foo!'), "has_special_characters() successfull");
ok($config->variable_exists('foo'), "variable_exists() successfull");
ok($config->add_comment('blablub'), "add_comment() successfull");

# list context

my %values = $config->read('foo', 'quux');
ok(%values, "read() list context successfull");
undef %values;
%values = $config->multiple_read('foo', 'quux');
ok(%values, "multiple_read() list context successfull");
ok($config->add_comment('Test!', 'Yet another Test'), "add_comment() list context successfull");

# hash (#) stuff

ok($config->set('bla', 'bl # ub'), "set() with hash successfull");
my $value = $config->read('bla');
ok($value, "read() with hash successfull");
like($value, qr/[^\\]#/, "read() successfully unescapes the hash");

END { unlink $config_file; }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

