# - Test that dependencies are loaded
# - Check that Driver was pre-loaded okay
# - Test Session construction with fake memcached connection mock-object
# (Class for connection is never hard-verified by driver)
use Test::More;
use lib '..';


use memcache;

plan('tests', 7); # 3
use_ok('CGI');
use_ok('CGI::Session');
# Trick CGI::Session / require() before module is installed
if (!$INC{'CGI/Session/Driver/memcache.pm'}) {
   $INC{'CGI/Session/Driver/memcache.pm'} = $INC{'memcache.pm'};
}
# Dependencies loaded
ok($CGI::Session::VERSION, "CGI::Session ($CGI::Session::VERSION) has been loaded");
# memcache driver loaded
ok($CGI::Session::Driver::VERSION, "CGI::Session driver ($CGI::Session::Driver::VERSION) for memcache loaded OK");

ok($CGI::Session::Driver::memcache::VERSION, "CGI::Session  memcache backend ($CGI::Session::Driver::memcache::VERSION) loaded OK");
# Mock object for memcached connection
my $memd = bless {}, 'Fake';
sub Fake::set {1;}; # Mock set-method that happens to be must-have
my $cgi = CGI->new();
my $sess = CGI::Session->new("driver:memcache", $cgi, {'Handle' => $memd});
ok(ref($sess), "CGI::Session instantiated for memcache backend");
isa_ok($sess, 'CGI::Session');

