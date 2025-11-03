use strict;
use warnings;

use Test::More;
use Test::Needs 'Class::Simple';
use App::Test::Generator qw(generate);

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use open qw(:std :encoding(UTF-8));

my $conf_file = 't/conf/class_simple.conf';
ok(-e $conf_file, 'config file exists: $conf_file');

# Generate into a scalar
{
	local *STDOUT;
	open STDOUT, '>', \my $output;
	App::Test::Generator::generate($conf_file);
	like($output, qr/use Test::Most;/, 'output looks like a test file');
}

done_testing;
