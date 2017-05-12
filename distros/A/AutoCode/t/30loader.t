use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 4;}

my ($first_name, $last_name)=qw(foo bar);

my $home_address=1234567;
use AutoCode::ModuleLoader 'ContactSchema', 'MyContactWhatever';


ok(1);

my $vp = AutoCode::ModuleLoader->load('Buddy');
my $instance = $vp->new(
    -first_name => $first_name,
    -last_name => $last_name,
    -emails => [qw(foo@bar.com bar@foo.com)],
    -home_address => $home_address
);

ok($instance->first_name, $first_name);
ok($instance->last_name, $last_name);
ok($instance->home_address, $home_address);


