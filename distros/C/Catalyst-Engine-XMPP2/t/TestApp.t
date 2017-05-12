use strict;
use warnings;

use Test::More tests => 14;

BEGIN { $ENV{CATALYST_ENGINE} = 'XMPP2' };
BEGIN { use_ok('Catalyst::Engine::XMPP2') };

use lib 't/lib';
use lib 't/TestApp/lib';
require TestApp;

my %connections;
# let's replace some key subs.
{   package Event;
    no warnings;
    sub loop {
        return;
    }
};
{   package Catalyst::Engine::XMPP2;
    no warnings;
    sub loop {
        return;
    }
};
{   package AnyEvent::XMPP::Connection;
    no warnings;
    sub new {
        my $class = shift;
        my %data = @_;
        my $res = $data{resource};
        $connections{$res} = bless \%data, 'Test::XMPP2';
        return $connections{$res};
    }
};

my $last_set_callback;
my $expecting = '';
{   package Test::XMPP2;
    sub connect {
        return 1;
    }
    sub reg_cb {
        my $self = shift;
        my %callbacks = @_;
        $self->{callbacks} = \%callbacks;
    }
    sub reply_iq_result {
        my ($self, $id, $cb) = @_;
        return unless $expecting eq 'iq_reply';
        $last_set_callback = $cb;
    }
    sub send_message {
        my ($self, $jid, $type, $cb, %attr) = @_;
        return unless $expecting eq 'message';
        $last_set_callback = $cb;
    }
    sub send_presence {
        my ($self, $type, $cb, %attr) = @_;
        return unless $expecting eq 'presence';
        $last_set_callback = $cb;
    }
};

{   package Test::Writer;
    sub new {
        return bless {}, 'Test::Writer';
    }
    sub raw {
        my ($self, $data) = @_;
        $self->{data} = $data;
    }
}

TestApp->run();

pass('Engine initialized');

my %expected_resources =
  (
   'foo/iq_req' => 1,
   'foo/iq_req_xml' => 1,
   'foo/message' => 1,
   'foo/presence' => 1
  );

for my $c (keys %connections) {
    if (my $res = delete $expected_resources{$c}) {
        pass('Resource '.$c.' registered');
    } else {
        fail('Unexpected resource '.$c);
    }
}
for my $c (keys %expected_resources) {
    fail('Missing resource '.$c);
}

# let's say the stream is ready
for my $c (keys %connections) {
    $connections{$c}{callbacks}{stream_ready}->();
}

require AnyEvent::XMPP::Parser;


{
    # now let's do an iq request...
    my $parser = AnyEvent::XMPP::Parser->new();
    $parser->set_stanza_cb
      (sub {
           my ($parser, $node) = @_;
           return unless $node;

           $last_set_callback = undef;
           $expecting = 'iq_reply';
           my $writer = Test::Writer->new();

           $connections{'foo/iq_req'}{callbacks}{iq_get_request_xml}->($parser,$node);

           ok($last_set_callback, 'reply sent');
           $last_set_callback->($writer) if $last_set_callback;
           is($writer->{data}, '<body>Hello World</body>', 'got correct iq reply');
       });
    $parser->set_error_cb
      (sub {
           my ($error, $data) = @_;
           warn 'Failed!! '.$error.': '.$data;
       });
    $parser->feed('<stream><iq id="1234" from="foo@example.com">World</iq></stream>');
}
{
    # now let's do an iq that returns a xml body...
    my $parser = AnyEvent::XMPP::Parser->new();
    $parser->set_stanza_cb
      (sub {
           my ($parser, $node) = @_;
           return unless $node;

           $last_set_callback = undef;
           $expecting = 'iq_reply';
           my $writer = Test::Writer->new();

           $connections{'foo/iq_req_xml'}{callbacks}{iq_set_request_xml}->($parser,$node);

           ok($last_set_callback, 'reply sent');
           $last_set_callback->($writer) if $last_set_callback;
           is($writer->{data}, '<hello>World</hello>', 'got correct iq reply');
       });
    $parser->set_error_cb
      (sub {
           my ($error, $data) = @_;
           warn 'Failed!! '.$error.': '.$data;
       });
    $parser->feed('<stream><iq id="1234" from="foo@example.com">World</iq></stream>');
}
{
    # now let's do a message that messages us back...
    my $parser = AnyEvent::XMPP::Parser->new();
    $parser->set_stanza_cb
      (sub {
           my ($parser, $node) = @_;
           return unless $node;

           $last_set_callback = undef;
           $expecting = 'message';
           my $writer = Test::Writer->new();

           $connections{'foo/message'}{callbacks}{message_xml}->($parser,$node);

           ok($last_set_callback, 'reply sent');
           $last_set_callback->($writer) if $last_set_callback;
           is($writer->{data}, '<hello>World</hello>', 'got correct message');
       });
    $parser->set_error_cb
      (sub {
           my ($error, $data) = @_;
           warn 'Failed!! '.$error.': '.$data;
       });
    $parser->feed('<stream><message>World</message></stream>');
}
{
    # now let's do a presence that presences us back...
    my $parser = AnyEvent::XMPP::Parser->new();
    $parser->set_stanza_cb
      (sub {
           my ($parser, $node) = @_;
           return unless $node;

           $last_set_callback = undef;
           $expecting = 'presence';
           my $writer = Test::Writer->new();

           $connections{'foo/presence'}{callbacks}{message_xml}->($parser,$node);

           ok($last_set_callback, 'reply sent');
           $last_set_callback->($writer) if $last_set_callback;
           is($writer->{data}, '<hello><place>World</place></hello>', 'got correct presence');
       });
    $parser->set_error_cb
      (sub {
           my ($error, $data) = @_;
           warn 'Failed!! '.$error.': '.$data;
       });
    $parser->feed('<stream><presence><place>World</place></presence></stream>');
}
