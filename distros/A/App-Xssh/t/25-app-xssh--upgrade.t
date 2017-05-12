use strict;
use warnings;

use Test::More;
use File::Temp;

use App::Xssh;
use App::Xssh::Config;

# Create a temporary config object, so we can mess with it
$ENV{HOME} = File::Temp::tempdir( CLEANUP => 1 );
my $xssh = App::Xssh->new();
my $config = App::Xssh::Config->new();

my $data = {
	hosts => {
		monster => {
			extra => 'extra',
			option => 'value',
		}
	},
	extra => {
		name => {
			option => 'value',
		}
	},
};
$data = $xssh->upgradeConfig($config,$data);

is($data->{hosts}->{monster}->{profile},"extra","extra host option copied");
isnt($data->{hosts}->{monster}->{extra},"extra","extra host option removed");

is($data->{profile}->{name}->{option},"value","extra profile option copied");
isnt($data->{extra}->{name}->{option},"value","extra profile option removed");

is($data->{hosts}->{monster}->{option},"value","some things don't change");

done_testing();
