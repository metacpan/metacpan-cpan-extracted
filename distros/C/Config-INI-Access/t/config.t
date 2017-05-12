use Test::More qw(no_plan);

use Config::INI::Access;

ok(7 == config->load('t/config.ini'), 'Reading config file');

ok(config->globalA eq 'value A', 'Global key value');
ok(config->globalB eq 'value B', 'Global key value');

ok(config->section1->key1 eq 'value 1', 'Key within section');
ok(config->section1->key2 eq 'value 2', 'Key within section');

#ok(!defined config->unknown, 'Unknown top level key');
#ok(!defined config->section1->unknown, 'Unknown key within a section');

ok(config->section2->k1 eq 'alpha', 'Key within another section');
ok(config->section2->k2 eq 'beta', 'Key within another section');
ok(config->section2->k3 eq 'gamma', 'Key within another section');

my $unknown = 7;
$unknown = config->non_existing if config->{'non_existing'};
ok($unknown == 7, "Skipping non-existing root element");

$unknown = config->section2->non_existing if config->section2->{'non_existing'};
ok($unknown == 7, "Skipping non-existing section element");
