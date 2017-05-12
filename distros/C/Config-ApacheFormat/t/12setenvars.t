
use Test::More tests => 13;
BEGIN { use_ok 'Config::ApacheFormat'; }

$ENV{PRESET} = $ENV{VARS} = 1;

my $config = Config::ApacheFormat->new(setenv_vars => 1, expand_vars => 1);
$config->read("t/setenvars.conf");

is($config->get('SPECIALNESS'), "Super");
isnt($ENV{SPECIALNESS}, "Super");

is($config->get('toughness'), '*Negative*');
isnt($ENV{TOUGHNESS}, '*Negative*');

is($config->get('bindir'), 'bin');
is($ENV{bindir}, undef);

is($config->get('ORACLE_HOME'), '/oracle/bin');
isnt($ENV{'ORACLE_HOME'}, '/oracle/bin');
is($ENV{'SUPER'}, ($config->get('setenv'))[1]);

is($ENV{PRESET}, undef);
is($ENV{VARS}, undef);

is($config->get('SomeVar'), 'yabba');

