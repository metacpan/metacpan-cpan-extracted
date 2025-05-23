use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use Crypt::SecretBuffer qw(secret);

subtest 'child receives secret' => sub {
   my $buf = Crypt::SecretBuffer->new('pipe secret');
   my $pipe = $buf->as_pipe;
   pipe(my $parent_r, my $child_w) or die "pipe: $!";
   my $pid = fork();
   die "fork: $!" unless defined $pid;
   if (!$pid) {
      close $parent_r;
      local $/;
      my $got = <$pipe>;
      print $child_w $got;
      close $child_w;
      close $pipe;
      exit 0;
   }
   close $child_w;
   local $/;
   my $got = <$parent_r>;
   is($got, 'pipe secret', 'child got secret');
   close $parent_r;
   close $pipe;
   waitpid($pid, 0);
};

subtest 'IPC::Run /dev/fd notation' => sub {
   skip_all('IPC::Run or /dev/fd unsupported')
      unless eval { require IPC::Run; 1 } && -e '/proc/self/fd';
   my $buf = Crypt::SecretBuffer->new('ipc run secret');
   my $echoed = '';
   IPC::Run::run([ 'cat', '/dev/fd/3' ], '1>', \$echoed, '3<', $buf->as_pipe);
   is($echoed, 'ipc run secret', 'cat read secret via /dev/fd/3');
};

done_testing;
