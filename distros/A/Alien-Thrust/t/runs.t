use Test::More tests => 3;

use strict;

use Alien::Thrust;
use IPC::Open2;

diag("Thrust shell binary: $Alien::Thrust::thrust_shell_binary");

ok(-e $Alien::Thrust::thrust_shell_binary, 'binary file exists');
ok(-x $Alien::Thrust::thrust_shell_binary, 'binary file is executable');

my $pid = open2(my $child_out, my $child_in, $Alien::Thrust::thrust_shell_binary);

END {
  kill 'KILL', $pid;
}

print $child_in q{
{"_id":1,"_action":"create","_type":"window","_args":{"root_url":"http://google.com"}}
--(Foo)++__THRUST_SHELL_BOUNDARY__++(Bar)--
};

close $child_in;

while(<$child_out>) {
  if (/THRUST_SHELL_BOUNDARY/) {
    ok(1, 'found thrust shell boundary line');
    last;
  }
}
