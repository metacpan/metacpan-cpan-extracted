use strict;
use warnings;
use Test::More;

=pod

Tests which expect a STOMP server like ActiveMQ to exist on
localhost:61613, which is what you get if you just get the ActiveMQ
distro and change its config.

If the Load() function in YAML::XS is given a byte that can be thought
of as the first of a multibyte character (UTF-8) and it isn't, it can
explode.

=cut

use Net::Stomp;
use YAML::XS qw/ Dump Load /;
use Data::Dumper;
use Encode;

use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use TestServer;

binmode(STDOUT, ":utf8"); # Set you terminal to show UTF8 !!!!!!!!!!

my $stomp = start_server();

plan tests => 13;

my $frame = $stomp->connect();
ok($frame, 'connect to MQ server ok');

my $reply_to = sprintf '%s:1', $frame->headers->{session};
ok($frame->headers->{session}, 'got a session');
ok(length $reply_to > 2, 'valid-looking reply_to queue');

ok($stomp->subscribe( { destination => '/temp-queue/reply' } ), 'subscribe to temp queue');

# \x{eb} is ë, or "LATIN SMALL LETTER E WITH DIAERESIS".
# \x{eb} is the codepoint, 235, perl uses internally for the character
# If you have ë in a simple perl string, switch the utf-8 flag on, Dumper() will display \x{eb}
# In octets, i.e. proper UTF-8, it comes out as \xc3 \xab,
# So we want two bytes back, not one
# The Load() function will convert it back into Perl internal representation of \x{eb}
#

my $text_string  = "Maria van Bourgondiëlaan";
Encode::_utf8_on($text_string); # this is now how we get things from XML::Compile which deals with XML in utf-8 encoding

my $message = {
	       payload => { string => $text_string }, # was send_string...
	       reply_to => $reply_to,
	       type => 'testutf8',
	      };
my $text = Dump($message);
ok($text, 'compose message, sending : ' . Dumper($message) );

$stomp->send( { destination => '/queue/testcontroller', body => $text } );

ok(1, "sent");

my $reply_frame = $stomp->receive_frame();
ok($reply_frame, 'got a reply');
ok($reply_frame->headers->{destination} eq "/remote-temp-queue/$reply_to", 'came to correct temp queue');
ok($reply_frame->body, 'has a body');

my $response = Load($reply_frame->body);

ok($response, 'YAML response ok');
ok($response->{type}   eq 'testutf8_response', 'correct type');

# Without utf-8 encoding, the new string comes back as "Maria van Bourgondi\x{fffd}laan"
# With    utf-8 encoding, the new string comes back as "Maria van Bourgondi\x{eb}laan"
my $new_string = $response->{struct}->[1]->{new_string};

ok($new_string eq $text_string,
   "new string is the same as our text string : \n" .
   Dumper( $new_string ) . " == \n" . Dumper($text_string) .
   "OR\n".
   "$new_string eq $text_string\n".
   "utf8 for new_string  : " . Encode::is_utf8($new_string)  . "\n" .
   "utf8 for text_string : " . Encode::is_utf8($text_string) . "\n"  );


$stomp->disconnect;
ok(!$stomp->socket->connected, 'disconnected');
