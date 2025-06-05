use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use IO::Handle;
use Crypt::SecretBuffer qw(NONBLOCK);

sub check_buf { my ($buf,$exp,$msg)=@_; local $buf->{stringify_mask}=undef; is("$buf",$exp,$msg) }

subtest 'append_read basic' => sub {
    my ($r,$w)= pipe_with_data('hello');
    my $buf = Crypt::SecretBuffer->new;
    my $n = $buf->append_read($r,5);
    is($n,5,'read all');
    check_buf($buf,'hello','content');
    close $r; close $w;
};


subtest 'append_read NONBLOCK' => sub {
   skip_all "Nonblocking doesn't work on Win32"
      if $^O eq 'MSWin32';

   my ($r,$w)= pipe_with_data('x');
   $r->blocking(0);
   my $buf = Crypt::SecretBuffer->new;
   my $n = $buf->append_read($r,1);
   ok($n==1,'one byte');
   $n = $buf->append_read($r,1);
   is( $n, undef, 'nonblock = syserror' ) && ok( $!{EAGAIN}, 'EAGAIN' );
   close $w;
   $n = $buf->append_read($r,1);
   is( $n, 0, 'EOF' );
   close $r;
};

done_testing;

