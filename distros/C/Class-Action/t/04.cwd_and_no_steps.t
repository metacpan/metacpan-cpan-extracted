use Test::More tests => 22;
use Test::Carp;

use lib 'lib', '../lib';

BEGIN {
use_ok( 'Class::Action' );
}

diag( "Testing Class::Action $Class::Action::VERSION" );

my $act_a = Class::Action->new();
my $act_b = Class::Action->new({'enable_cwd' => 1});

ok(!$act_a->get_enable_cwd(), 'CWD not enabled by default');
ok($act_b->get_enable_cwd(), 'CWD enabled by option to new()');

$act_a->set_enable_cwd(1);
$act_b->set_enable_cwd(0);

ok($act_a->get_enable_cwd(), 'CWD enabled by set method');
ok(!$act_b->get_enable_cwd(), 'CWD disabled by set method');

ok(!$act_a->get_starting_cwd(), 'can not get CWD of execute until it has been set - when on');
ok(!$act_b->get_starting_cwd(), 'can not get CWD of execute until it has been set - when off');

does_carp(sub { 
    ok($act_a->execute(), 'execute returns true w/ no steps - 1');
});

does_carp(sub { 
    ok($act_b->execute(), 'execute returns true w/ no steps - 2');
});

ok(!$act_b->get_starting_cwd(), 'CWD not set on execute() when option is off');
ok($act_a->get_starting_cwd(),'CWD is set on execute() when option is on');

ok($act_b->set_starting_cwd() == 1, 'setting returns 1 when it was not previously set');
my $cwd = $act_b->get_starting_cwd();
ok($cwd, 'CWD set OK');
mkdir 'test_cwd';
chdir 'test_cwd' or diag("Could not chdir into temp dir: $!");
ok($act_b->set_starting_cwd() eq $cwd, 'subsequent setting returns previous value when it was previously set');
ok($act_b->get_starting_cwd() ne $cwd, 'CWD was updated OK');
chdir '..' or diag("Could not chdir back into working dir: $!");
rmdir 'test_cwd' or diag("Could not rmdir temp dir: $!");

$act_a->reset();
$act_b->reset();

ok(!$act_a->get_starting_cwd() && !$act_b->get_starting_cwd(), 'reset updates stored value');
ok($act_a->get_enable_cwd(), 'CWD enabled not changed by reset');
ok(!$act_b->get_enable_cwd(), 'CWD disabled not changed by reset');

does_carp(sub {
    ok(!$act_a->next_step() && !$act_a->prev_step(), 'no steps next and prev returns false');
});


