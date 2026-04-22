use strict;
use warnings;

use Test::Most;
use Test::Needs 'Class::Simple';

use_ok('App::Test::Generator');

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use open qw(:std :encoding(UTF-8));

my $conf_file = 't/conf/app_generator.yml';
ok(-e $conf_file, 'config file exists: $conf_file');

# Generate into a scalar
{
	local *STDOUT;
	open STDOUT, '>', \my $output;
	App::Test::Generator->generate($conf_file);
	like($output, qr/use Test::Most;/, 'output looks like a test file');
}

dies_ok { App::Test::Generator->generate() } 'Dies when not given an argument';
like $@, qr/^Usage: /;

done_testing();
