#!perl -T

use Test::More tests => 23;

BEGIN {
    use_ok( 'App::Rad', qw/Daemonize/ );
}

can_ok('App::Rad', 'run');


# why not $c = App::Rad->new(); ??
my $c = {};
bless $c, 'App::Rad';
$c->_init();

can_ok($c, 'after_detach');
can_ok($c, 'set_daemonize_pars');
can_ok($c, 'get_daemonize_pars');
can_ok($c, 'daemonize');
can_ok($c, 'detach');
can_ok($c, 'chroot');
can_ok($c, 'change_user');
can_ok($c, 'check_root');
can_ok($c, 'write_pidfile');
can_ok($c, 'change_procname');
can_ok($c, 'read_pidfile');
can_ok($c, 'stop');
can_ok($c, 'kill');
can_ok($c, 'is_running');
can_ok($c, 'signal_handlers');

ok(my $ret = $c->daemonize);


SKIP: {
   skip "Couldn't run \$c->daemonize()", 5 unless $ret;
   ok($c->is_command("start"));
   ok($c->is_command("stop"));
   ok($c->is_command("restart"));
   ok($c->is_command("status"));
   SKIP: {
      skip "It's not a Windows SO...", 1 unless $^O eq "MSWin32";
      ok($c->is_command("Win32_Daemon"));
   }
}

