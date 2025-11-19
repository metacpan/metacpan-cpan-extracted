use FindBin;
use lib "$FindBin::Bin/lib";
use Test2AndUtils;
use IO::Handle;
use File::Temp;
use Crypt::SecretBuffer qw(NONBLOCK);

sub check_content {
   my ($buf, $expected, $msg) = @_;
   local $buf->{stringify_mask} = undef;
   is("$buf", $expected, $msg);
}

subtest 'append_sysread basic' => sub {
   my ($r, $w) = pipe_with_data('hello world');
   my $buf = Crypt::SecretBuffer->new;
   my $got = $buf->append_sysread($r, 5);
   is($got, 5, 'read 5 bytes');
   check_content($buf, 'hello', 'buffer has hello');
   $got = $buf->append_sysread($r, 6);
   is($got, 6, 'read remaining bytes');
   check_content($buf, 'hello world', 'all data read');
   close $r; close $w;
};

subtest 'append_sysread EOF' => sub {
   my ($r, $w) = pipe_with_data('abc');
   close $w;
   my $buf = Crypt::SecretBuffer->new;
   my $got = $buf->append_sysread($r, 10);
   is($got, 3, 'only three bytes');
   check_content($buf, 'abc', 'buffer has abc');
   $got = $buf->append_sysread($r, 1);
   is($got, 0, 'zero at EOF');
   close $r;
};

subtest load_file => sub {
   my $content= "1234"x50;
   my $f= File::Temp->new;
   $f->print($content);
   $f->close;
   my $buf= Crypt::SecretBuffer->new(load_file => "$f");
   check_content($buf, $content);
};

done_testing;

