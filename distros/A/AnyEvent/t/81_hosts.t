use File::Temp qw(tempfile);
use Test::More tests => 2;

my $test_host = 'test.invalid.';
my $test_addr = '127.9.9.9';

my ($hosts_fh, $hosts_file) = tempfile UNLINK => 1;
print $hosts_fh "$test_addr $test_host\n";
close $hosts_fh;

$ENV{PERL_ANYEVENT_HOSTS} = $hosts_file;

require AnyEvent;
require AnyEvent::Socket;

sub resolved($) {
   my $cv = AnyEvent->condvar;

   AnyEvent::Socket::resolve_sockaddr (shift, 80, undef, undef, undef, sub {
      return $cv->send unless @_;
      my $sockaddr = $_[0][-1];
      my $address = (AnyEvent::Socket::unpack_sockaddr ($sockaddr))[1];
      return $cv->send (AnyEvent::Socket::format_address ($address));
   });

   return $cv->recv;
}
 
is resolved $test_host, $test_addr, 'resolved on first attempt';
is resolved $test_host, $test_addr, 'resolved on second attempt';

