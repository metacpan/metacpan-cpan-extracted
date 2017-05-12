package AI::CleverbotIO;
use strict;
use warnings;
{ our $VERSION = '0.002'; }

use Moo;
use Ouch;
use Log::Any ();
use Data::Dumper;
use JSON::PP qw< decode_json >;

has endpoints => (
   is      => 'ro',
   default => sub {
      return {
         ask    => 'https://cleverbot.io/1.0/ask',
         create => 'https://cleverbot.io/1.0/create',
      };
   },
);

has key => (
   is       => 'ro',
   required => 1,
);

has logger => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_logger',
);

has nick => (
   is        => 'rw',
   lazy      => 1,
   predicate => 1,
);

has user => (
   is       => 'ro',
   required => 1,
);

has ua => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_ua',
);

sub BUILD_logger {
   return Log::Any->get_logger;
}

sub BUILD_ua {
   my $self = shift;
   require HTTP::Tiny;
   return HTTP::Tiny->new;
}

sub ask {
   my ($self, $question) = @_;
   my %ps = (
      key  => $self->key,
      text => $question,
      user => $self->user,
   );
   $ps{nick} = $self->nick if $self->has_nick;
   return $self->_parse_response(
      $self->ua->post_form($self->endpoints->{ask}, \%ps));
}

sub create {
   my $self = shift;
   $self->nick(shift) if @_;

   # build request parameters
   my %ps = (
      key  => $self->key,
      user => $self->user,
   );
   $ps{nick} = $self->nick if $self->has_nick && length $self->nick;

   my $data =
     $self->_parse_response(
      $self->ua->post_form($self->endpoints->{create}, \%ps));

   $self->nick($data->{nick}) if exists($data->{nick});

   return $data;
}

sub _parse_response {
   my ($self, $response) = @_;

   {
      local $Data::Dumper::Indent = 1;
      $self->logger->debug('got response: ' . Dumper($response));
   }

   ouch 500, 'no response (possible bug in HTTP::Tiny though?)'
     unless ref($response) eq 'HASH';

   my $status = $response->{status};
   ouch $status, $response->{reason}
      if ($status != 200) && ($status != 400);

   my $data = __decode_content($response);
   return $data if $response->{success};
   ouch 400, $data->{status};
} ## end sub _parse_response

sub __decode_content {
   my $response = shift;
   my $encoded  = $response->{content};
   if (!$encoded) {
      my $url = $response->{url} // '*unknown url, check HTTP::Tiny*';
      ouch 500, "response status $response->{status}, nothing from $url)";
   }
   my $decoded = eval { decode_json($encoded) }
     or ouch 500, "response status $response->{status}, exception: $@";
   return $decoded;
} ## end sub __decode_content

1;
