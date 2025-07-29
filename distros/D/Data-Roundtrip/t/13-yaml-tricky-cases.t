#!perl -T

use 5.008;

use strict;
use warnings;

use utf8;

our $VERSION='0.30';

######################################################
# see also:
#    https://github.com/ingydotnet/yaml-pm/issues/224
######################################################

use Test::More;
use Test2::Plugin::UTF8;

use Data::Roundtrip qw/yaml2perl perl2yaml/;

my ($perl, $newperl, $yamlstr);

$perl = [
	{
		"\"aaa'bbb" => "aaa",
		"bbb" => 1,
	}
];

$yamlstr = perl2yaml($perl);
ok(defined($yamlstr), 'perl2yaml()'." : called and got defined result");
ok($yamlstr =~ /^\-\-\-/, 'perl2yaml()'." : called and looks like a yaml string");

$newperl = yaml2perl($yamlstr);
ok(defined($newperl), 'yaml2perl()'." : called and got good result");

is_deeply($perl, $newperl, 'yaml2perl()'." : result is exactly the same as the data structure we started with");

# with unicode
$perl = [
	{
		"\"ααα'βββ" => "ααα",
		"βββ" => 1,
	}
];

$yamlstr = perl2yaml($perl);
ok(defined($yamlstr), 'perl2yaml()'." : called and got defined result");
ok($yamlstr =~ /^\-\-\-/, 'perl2yaml()'." : called and looks like a yaml string");

$newperl = yaml2perl($yamlstr);
ok(defined($newperl), 'yaml2perl()'." : called and got good result");

is_deeply($perl, $newperl, 'yaml2perl()'." : result is exactly the same as the data structure we started with");

done_testing;

1;
__END__
