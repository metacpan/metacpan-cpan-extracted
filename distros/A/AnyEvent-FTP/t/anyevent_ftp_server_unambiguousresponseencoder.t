use Test2::V0 -no_srand => 1;
use AnyEvent::FTP::Server::UnambiguousResponseEncoder;
use AnyEvent::FTP::Client::Role::ResponseBuffer;
use AnyEvent::FTP::Response;

my $encoder = AnyEvent::FTP::Server::UnambiguousResponseEncoder->new;
isa_ok $encoder, 'AnyEvent::FTP::Server::UnambiguousResponseEncoder';

eval q{
  package Client;
  
  use Moo;
  
  with 'AnyEvent::FTP::Client::Role::ResponseBuffer';
};
die $@ if $@;

my $client = Client->new;
isa_ok $client, 'Client';

do {
  my $raw = $encoder->encode(220, 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]');
  is $raw, "220 ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]', 'message match';
  });
  
  $client->process_message_line($raw);
};

do {
  my $raw = $encoder->encode(220, ['ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]']);
  is $raw, "220 ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]', 'message match';
  });
  
  $client->process_message_line($raw);
};

do {
  my $raw = $encoder->encode(AnyEvent::FTP::Response->new(220, ['ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]']));
  is $raw, "220 ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]', 'message match';
  });
  
  $client->process_message_line($raw);
};

do {
  my $raw = $encoder->encode(AnyEvent::FTP::Response->new(220, 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]'));
  is $raw, "220 ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'ProFTPD 1.3.3a Server (Debian) [::ffff:127.0.0.1]', 'message match';
  });
  
  $client->process_message_line($raw);
};

do {
  my $raw = $encoder->encode(220, [qw( one two three )]);
  is $raw, "220-one\015\012220-two\015\012220 three\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'one|two|three', 'message match';
  });
  
  $client->process_message_line($_) for split /\015\012/, $raw;
};

do {
  my $raw = $encoder->encode(AnyEvent::FTP::Response->new(220, [qw( one two three )]));
  is $raw, "220-one\015\012220-two\015\012220 three\015\012", 'raw response';
  
  $client->on_next_response(sub {
    my $res = shift;
    is $res->code, 220, 'code match';
    is join('|', @{ $res->message }), 'one|two|three', 'message match';
  });
  
  $client->process_message_line($_) for split /\015\012/, $raw;
};

done_testing;
