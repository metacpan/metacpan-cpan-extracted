package AnyEvent::SlackBot;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::clean;
use Data::Dumper;
use LWP::UserAgent;
use HTTP::Request;
use URI::Escape;
use HTTP::Request::Common qw(POST);
use AnyEvent::HTTP::MultiGet;
use AnyEvent::WebSocket::Client;
use JSON;
use namespace::clean;
our $VERSION='1.0002';

BEGIN { 
  no namespace::clean;
  with 'Log::LogMethods','Data::Result::Moo';
}
 

=head1 NAME

AnyEvent::SlackBot - AnyEvent Driven Slack Bot Interface

=head1 SYNOPSIS

  use Modern::Perl;
  use Data::Dumper;
  use AnyEvent::SlackBot;
  use AnyEvent::Loop;

  $|=1;
  my $sb=AnyEvent::SlackBot->new(
    on_event=>sub {
      my ($sb,$json,$conn_data)=@_;
      if(exists $json->{type} and $json->{type} eq 'desktop_notification') {
        my $ref={
          type=>'message',
          bot_id=>$sb->bot_id,
          channel=>$json->{channel},
          text=>'this is a test',
          subtype=>'bot_message',
        };
        print Dumper($json,$ref);
        $sb->send($ref);
      }
    },
  );

  my $result=$sb->connect_and_run;
  die $result unless $result;
  AnyEvent::Loop::run;

=head1 DESCRIPTION

Slack client.  Handles Ping Pong on idle conntions, and transparrently reconnects as needed.  The guts of the module wrap AnyEvent::WebSocket::Client, keeping the code base very light.

=head1 OO Arguments and accessors

Required Arguments

  on_event: code refrence for handling events
    sub { my ($self,$connection,$message,$startup_info)=@_ }

Optional Arguments

  on_idle: code refrence for use in idle time
    sub { my ($self)=@_ }

  on_reply: code refrence called when the server responds to a post
    sub { my ($self,$json,$connection_data)=@_ }

  agent: Sets the AnyEvent::HTTP::MultiGet Object
  logger: sets the logging object, DOES( Log::Log4perl::Logger )
  rtm_start_url: the url used to fetch the websockets connection from
  token: the authentication token used by rtm_start_url
  auto_reconnect: if true ( default ) reconnects when a connection fails
  unknown_que: array ref of objects that may be repeats from us

Set at Run time

  connection: The connection object
  bot_id:     The Bot ID defined at runtime
  stats:      An anonyous hash ref of useful stats

=cut

has unknown_que=>(
  is=>'ro',
  isa=>ArrayRef,
  default=>sub { [] },
  required=>1,
);

has on_reply=>(
  is=>'ro',
  isa=>CodeRef,
  default=>sub { sub {} },
  required=>1,
);

has agent=>(
  is=>'ro',
  isa=>Object,
  default=>sub { new AnyEvent::HTTP::MultiGet() },
);

has rtm_start_url=>(
  is=>'ro',
  isa=>Str,
  required=>1,
  default=>'https://slack.com/api/rtm.start',
);

has on_idle=>(
  is=>'ro',
  isa=>CodeRef,
  required=>1,
  default=>sub { sub {} }
);

has token=>(
  is=>'ro',
  isa=>Str,
  required=>1,
);

has stats=>(
  is=>'ro',
  isa=>HashRef,
  required=>1,
  default=>sub { {} },
);

has on_event=>(
  is=>'ro',
  isa=>CodeRef,
  requried=>1,
);

has auto_reconnect=>(
  is=>'rw',
  isa=>Bool,
  required=>1,
  default=>1,
);

has connection=>(
  is=>'rw',
  isa=>Object,
  required=>0,
);

has bot_id=>(
  is=>'rw',
  isa=>Str,
  required=>0,
);

has keep_alive_timeout =>(
  is=>'ro',
  isa=>Int,
  requried=>1,
  default=>15,
);

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;

  $self->{backlog}=[];
  $self->{ignore}={};
  $self->stats->{service_started_on}=time;
  $self->stats->{running_posts}=0;
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};

=head1 OO Methods

=over 4

=item * $self->connect_and_run

COnnects and starts running

=cut

sub connect_and_run {
  my ($self)=@_;
  my $request=POST $self->rtm_start_url,[token=>$self->token];
  my $ua=LWP::UserAgent->new;
  my $response=$ua->request($request);
  $self->{timer}=undef;
  if($response->code==200) {
     my $data=eval { from_json($response->decoded_content) };
     if($@) {
       return $self->new_false("Failed to decode response, error was: $@");
     }
     unless(exists $data->{url} and $data->{self}) {
       my $msg=exists $data->{error} ? $data->{error} : 'unknown slack error';
       return $self->new_false("Failed to get valid connection info, error was: $msg");
     }

     $self->build_connection($data);
  } else {
    return $self->new_false("Failed to get conenction info from slack, error was: ".$response->status_line);
  }
}

=item * my $id=$self->next_id

Provides an id for the next message.

=cut

sub next_id {
  my ($self)=@_;
  return ++$self->{next_id}
}

=item * if($self->is_connected) { ... }

Denotes if we are currently connected to slack

=cut

sub is_connected {
  return defined($_[0]->connection)
}

=item * $self->send($ref)

Converts $ref to json and sends it on the session.

=cut

sub send {
  my ($self,$ref)=@_;
  my $json=to_json($ref);
  if($self->connection) {
    $self->connection->send($json);
    ++$self->stats->{total_messages_sent};
  } else {
    push @{$self->{backlog}},$json;
  }
}

=item * $self->send_typing($json)

Given $json sends a currently typing reply

=cut

sub send_typing {
  my ($self,$json)=@_;
  my $id=$self->next_id;
  my $msg={
    bot_id=>$self->bot_id,
    channel=>$json->{channel},
    id=>$id,
    type=>'typing',
  };
  $self->send($msg);
}

=item * $self->post_to_web($msg,$endpoint|undef,"FORM"|"JSON"|undef)

Posts the to the given REST Endpoint outside of the WebSocket.

  msg:
    Hash ref representing the requrest being sent
      token: set to $self->token if not set
      scope: set to: 'chat:write:bot' if not set

  endpoint:
    The Rest xxx endpint, the default is 'chat.postMessage'

  type:
    Sets how the data will be sent over
    Supported options are:
      - FORM: posts the data using form encoding
      - JSON: converts $msg to a json string and posts

=cut

sub post_to_web {
  my ($self,$msg,$endpoint,$type)=@_;
  $endpoint='chat.postMessage' unless defined($endpoint);
  $type='FORM';

  $self->stats->{running_posts}++;
  my $url="https://slack.com/api/$endpoint";


  $msg->{token}=$self->token unless exists $msg->{token};
  $msg->{scope}='chat:write:bot'  unless exists $msg->{scope};

  my $request;

  if($type eq 'FORM') {
    $request=POST $url,[%{$msg}];
  } else {
    $request=POST $url,'Conent-Type'=>'application/json',Content=>to_json($msg);
  }

  $self->agent->add_cb($request,sub {
    my ($agent,$request,$response)=@_;
    ++$self->stats->{http_posts_sent};
    $self->stats->{running_posts}--;
    if($response->code!=200) {
      $self->log_error("Failed to send Message,error was: ".$response->status_line) ;
    } else {
      my $json=eval { from_json($response->decoded_content) };
      if($@) {
        $self->log_error("Failed to parse json response, error was: $@") 
      } else {
        $self->{ignore}->{$json->{ts}}++;
        $self->log_error("Slack Responded with an eror: $json->{error}".Dumper($json)) unless $json->{ok};
      }
    }

    if($self->stats->{running_posts}==0) {
      # some times we get a response from the websocet before
      # the http request completes

      BACKLOG: while(my $args=shift @{$self->unknown_que}) {
        my (undef,$ref,$data)=@{$args};
	$self->log_info("processing backlog event");

	next if $self->we_sent_msg($ref);

	$self->on_event->($self,$ref,$data);
      }
    }
  });
  $self->agent->run_next;
}

=item * if($self->we_sent_msg($json,$connection_data)) { ... }

When true, $json is a duplicate from something we sent

=cut

sub we_sent_msg {
  my ($self,$ref,$data)=@_;
  if(exists $ref->{msg}) {
    my $sent=delete $self->{ignore}->{$ref->{msg}};
    if(defined($sent)) {
      $self->info("This is a message we sent");
      $self->on_reply->($self,$ref,$data);
      return 1;;
    }
  } elsif(exists $ref->{reply_to}) {
    $self->info("This is a message we sent");
    $self->on_reply->($self,$ref,$data);
    return 1;
  } else {
    $self->debug(Dumper($ref));
  }
  return 0;
}

=item * $self->build_connection($connection_details)

Internal Method used for buiding connections.

=cut

sub build_connection {
  my ($self,$data)=@_;
  my $url=$data->{url};
  $self->bot_id($data->{self}->{id});

  my $client=AnyEvent::WebSocket::Client->new;
  $client->connect($url)->cb(sub {
    my $connection=eval { shift->recv };
    $self->connection($connection);

    if($@) {
      $self->log_error("Failed to cnnect to our web socket, error was: $@");
      return $self->handle_reconnect;
    }
    $self->stats->{last_connected_on}=time;
    $self->stats->{total_connections}++;
    $self->stats->{last_msg_on}=time;
    $self->{timer}=AnyEvent->timer(
       interval=>$self->keep_alive_timeout,
       after=>$self->keep_alive_timeout,
       cb=>sub {
         my $max_timeout=$self->stats->{last_msg_on} + 3 * $self->keep_alive_timeout;
         if(time < $max_timeout) {
           if(time > $self->stats->{last_msg_on} + $self->keep_alive_timeout) {
	     $self->log_info("sending keep alive to server");
             $connection->send(to_json({
	       id=>$self->next_id,
	       type=>'ping',
	       timestamp=>time,
	     }));
	     %{$self->{ignore}}=();
             $self->on_idle->($self);
             $self->stats->{last_idle_on}=time;
           }
         } else {
           return $self->handle_reconnect;
         }
      }
    );

    $self->connection->on(finish=>sub {
      return $self->handle_reconnect;
    });
    $self->connection->on(each_message=> sub {
      my ($connection,$message)=@_;
      $self->stats->{last_msg_on}=time;
      $self->stats->{total_messages_recived}++;
      if($message->is_text) {
        my $ref=eval { from_json($message->body) };
	if($@) {
	    $self->log_error("Failed to parse json body, error was: $@");
	    return $self->handle_reconnect;
	  }
	  if(exists $ref->{type} and $ref->{type} eq 'pong') {
	    $self->log_info("got keep alive response from server");
	  } else {
	    if($self->stats->{running_posts}!=0) {
	      # Don't try to handle unknown commands while we are waiting on a post to go out!
	      push @{$self->unknown_que},[$self,$ref,$data];
	      $self->log_info("HTTP Post response pending.. will hold off on responding to commands until we know if we sent it or not");
	      return;
	    } else {
	      return if $self->we_sent_msg($ref,$data);
	      $self->log_info("real time response");
	      $self->debug('Inbound message: ',Dumper($ref));
	      $self->on_event->($self,$ref,$data);
	    }
	  }
       }
    });

  });

}

=item * $self->handle_reconnect

Internal method used to reconnect.

=cut

sub handle_reconnect {
  my ($self)=@_;
  $self->connection->close if $self->connection;
  $self->{connection}=undef;
  if($self->auto_reconnect) {
    my $result=$self->connect_and_run;
    if($result) {
      $self->log_info("auto reconnected without an error, flushing backlog of outbound messages");
      while(my $msg=shift @{$self->{backlog}}) {
        $self->send($msg);
      }
    } else {
      $self->log_error("Failed to reconnect will try again in 15 seconds, error was: $result");
      $self->{timer}=AnyEvent->timer(
        interval=>$self->keep_alive_timeout,
        after=>$self->keep_alive_timeout,
        cb=>sub { $self->handle_reconnect },
      );
    }
  }
}

=back

=head1 See Also

The slack api documentation - L<https://api.slack.com/rtm>

The AnyEvent WebSocket Client library - L<AnyEvent::WebSocket::Client>

The AnyEvent HTTP Client library - L<AnyEvent::HTTP::MultiGet>

=head1 AUTHOR

Michael Shipper L<mailto:AKALINUX@CPAN.ORG>

=cut

1;
