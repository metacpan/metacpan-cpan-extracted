use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN {plan tests=> 5; }

my ($first_name, $last_name)=qw(foo bar);
my $home_address='12334445566';

use AutoCode::ModuleLoader 'ContactSchema';
ok 1;

my $vp=AutoCode::ModuleLoader->load('Person');
my $person=$vp->new(
    -first_name => $first_name
);
ok $person->first_name, $first_name;

my $o_vp =$vp;
$vp=AutoCode::ModuleLoader->load('Buddy');
ok $vp, 'AutoCode::Virtual::Buddy';

my $buddy=$vp->new(
    -first_name => $first_name,
    -home_address => $home_address
);

# print UNIVERSAL::can($vp, 'dbid'), "\n";
ok $buddy->home_address, $home_address;
ok $buddy->first_name, $first_name;
no strict 'refs';
#print join('|', @{"$vp\::ISA"}) ."\n";
#print UNIVERSAL::isa($vp, $o_vp) ."\n";
