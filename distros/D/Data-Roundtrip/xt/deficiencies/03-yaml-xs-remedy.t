#!perl -T

use 5.008;

use strict;
use warnings;

our $VERSION='0.21';

######################################################
# this test fails because of YAML v1.30
# see:
#    https://github.com/ingydotnet/yaml-pm/issues/224
######################################################

use Test::More;
use Test2::Plugin::UTF8;
use YAML::XS;

my $perl = [
	{
		"\"aaa'bbb" => "aaa",
		"bbb" => 1,
	}
];
my $yamlstr = eval { Dump($perl) };
ok(defined($yamlstr), 'Dump()'." : called and got defined result");
ok($yamlstr =~ /^\-\-\-/, 'Dump()'." : called and looks like a yaml string");

my $newperl = Load($yamlstr);
ok(defined($newperl), 'Load()'." : called and got good result");

is_deeply($perl, $newperl, 'Load()'." : result is exactly the same as the data structure we started with");

done_testing;

1;
__END__
