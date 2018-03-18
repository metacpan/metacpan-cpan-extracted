package AnyEvent::SparkBot;

our $VERSION=1.009;
use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Scalar::Util qw( looks_like_number);
use Data::Dumper;
use namespace::clean;
use AnyEvent::HTTP::MultiGet;
use AnyEvent::WebSocket::Client;
use MIME::Base64;
use JSON;
use AnyEvent::HTTP::Spark;

BEGIN { 
  no namespace::clean;
  with 'HTTP::MultiGet::Role', 'AnyEvent::SparkBot::SharedRole';
}

=head1 NAME

AnyEvent::SparkBot - Cisco Spark WebSocket Client for the AnyEvent Loop

=head1 SYNOPSIS

  use Modern::Perl;
  use Data::Dumper;
  use AnyEvent::SparkBot;
  use AnyEvent::Loop;
  $|=1;

  our $obj=new AnyEvent::SparkBot(token=>$ENV{SPARK_TOKEN},on_message=>\&cb);

  $obj->que_getWsUrl(sub { 
    my ($agent,$id,$result)=@_;

    # start here if we got a valid connection
    return $obj->start_connection if $result;
    $obj->handle_reconnect;
  });
  $obj->agent->run_next;
  AnyEvent::Loop::run;

  sub cb {
    my ($sb,$result,$eventType,$verb,$json)=@_;
    return unless $eventType eq 'conversation.activity' and $verb eq 'post';

    # Data::Result Object is False when combination of EvenType and Verb are unsupprted
    if($result) {
      my $data=$result->get_data;
      my $response={
        roomId=>$data->{roomId},
        personId=>$data->{personId},
        text=>"ya.. ya ya.. I'm on it!"
      };
      # Proxy our lookup in a Retry-After ( prevents a lot of errors )
      $obj->run_lookup('que_createMessage',(sub {},$response);
    } else {
      print "Error: $result\n";
    }
  }

=head1 DESCRIPTION

Connects to cisco spark via a websocket.  By itself this class only provides connectivty to Spark, the on_message callback is used to handle events that come in.  By default No hanlder is provided.

=head1 Moo Role(s)

This module uses the following Moo role(s)

  HTTP::MultiGet::Role
  AnyEvent::SparkBot::SharedRole

=cut

has retryTimeout=>(
  is=>'ro',
  isa=>Int,
  default=>10,
  lazy=>1,
);

has retryCount=>(
  is=>'ro',
  isa=>Int,
  default=>1,
  lazy=>1,
);

has retries=>(
  is=>'ro',
  isa=>HashRef,
  lazy=>1,
  default=>sub { {} },
  required=>0,
);

has reconnect_sleep=>(
  is=>'ro',
  isa=>Int,
  default=>10,
  required=>1,
);

has reconnect=>(
  is=>'ro',
  isa=>Bool,
  default=>1,
  required=>1,
);

has pingEvery=>(
  is=>'ro',
  isa=>Int,
  default=>60,
);

has pingWait=>(
  is=>'ro',
  isa=>Int,
  default=>10,
);

has ping=>(
  is=>'rw',
);

has lastPing=>(
  is=>'rw',
  isa=>Str,
  lazy=>1,
);

has connInfo=>(
  is=>'rw',
  lazy=>1,
  default=>sub { {} },
);

has deviceDesc=>(
  is=>'ro',
  isa=>Str,
  default=>'{"deviceName":"perlwebscoket-client","deviceType":"DESKTOP","localizedModel":"nodeJS","model":"nodeJS","name":"perl-spark-client","systemName":"perl-spark-client","systemVersion":"'.$VERSION.'"}',
);

has defaultUrl=>(
  is=>'ro',
  isa=>Str,
  default=>'https://wdm-a.wbx2.com/wdm/api/v1/devices',
);

has lastConn=>(
  isa=>Str,
  is=>'ro',
  required=>1,
  default=>'/tmp/sparkBotLastConnect.json',
);

has connection=>(
  is=>'rw',
  isa=>Object,
  required=>0,
);

has on_message=>(
  is=>'ro',
  isa=>CodeRef,
  required=>1,
);

has spark=>(
  is=>'rw',
  isa=>Object,
  required=>0,
  lazy=>1,
);

has currentUser=>(
  is=>'rw',
  isa=>HashRef,
  required=>0,
  lazy=>1,
  default=>sub {return {}}
);

=head1 OO Arguments and accessors

Required Argument(s)

  token: The token used to authenticate the bot
  on_message: code ref used to handle incomming messages

Optional Arguments

  reconnect: default is true
  logger: null(default) or an instance of log4perl::logger
  lastConn: location to the last connection file
    # it may be a very good idea to set this value
    # default: /tmp/sparkBotLastConnect.json
  defaultUrl: https://wdm-a.wbx2.com/wdm/api/v1/devices
    # this is where we authenticate and pull the websocket url from
  deviceDesc: JSON hash, representing the client description
  agent: an instance of AnyEvent::HTTP::MultiGet
  retryTimeout: default 10, sets how long to wait afer getting a 429 error
  retryCount: default 1, sets how many retries when we get a 429 error

Timout and retry values:

  pingEvery: 60 # used to check how often we run a ping
    # pings only happen if no inbound request has come in for 
    # the interval
  pingWait: 10 
    # how long to wait for a ping response
  reconnect_sleep: 10
    # how long to wait before we try to reconnect

Objects set at runtime:

  lastConn: sets the location of the last connection file
  ping: sets an object that will wake up and do something
  lastPing: contains the last ping string value
  connection: contains the current websocket connection if any
  spark: Instance of AnyEvent::HTTP::Spark
  currentUser: Hash ref representing the current bot user

=cut

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;

  my $sb=new AnyEvent::HTTP::Spark(agent=>$self->agent,token=>$self->token);
  $self->spark($sb);
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};

=head1 OO Methods

=over 4

=item * my $result=$self->new_true({qw( some data )});

Returns a new true Data::Result object.

=item * my $result=$self->new_false("why this failed")

Returns a new false Data::Result object

=item * my $self->start_connection() 

Starts the bot up.

=cut

sub start_connection : BENCHMARK_DEBUG {
  my ($self)=@_;

  my $url=$self->connInfo->{webSocketUrl};

  $self->run_lookup('que_getMe',sub {
    my ($sb,$id,$result)=@_;
    return $self->log_error("Could not get spark Bot user info?") unless $result;

    $self->currentUser($result->get_data);
  });
  $self->agent->run_next;
  my $client=AnyEvent::WebSocket::Client->new;

  $client->connect($url)->cb(sub {
    my $conn=eval { shift->recv };

    if($@) {
      $self->log_error("Failed to cnnect to our web socket, error was: $@");
       return $self->handle_reconnect;
    }

    $self->connection($conn);
    $conn->on(finish=>sub { $self->handle_reconnect() });
    $self->setPing();


    $conn->send(to_json({
      id=>$self->uuidv4,
      type=>'authorization',
      data=>{
        token=>'Bearer '.$self->token,
      }
    }));

    $conn->on(each_message=>sub { $self->handle_message(@_) });
  });

}


=item * $self->handle_message($connection,$message)

Handles incoming messages 

=cut

sub handle_message : BENCHMARK_INFO {
  my ($self,$conn,$message)=@_;
  my $json=eval { from_json($message->body) };
  $self->ping(undef);
  if($@) {
    $self->log_error("Failed to parse message, error was: $@");
    $self->handle_reconnect;
    return;
  }

  if(exists $json->{type} && $json->{type} eq 'pong') {
    if($json->{id} ne $self->lastPing) {
      $self->log_error('Got a bad ping back?');
      return $self->handle_reconnect;
    } else {
      $self->log_debug("got a ping response");
      return $self->setPing();
    }
  } else {
    if(exists $json->{data} and exists $json->{data}->{eventType} and exists $json->{data}->{activity} ) {
      my $activity=$json->{data}->{activity};
      my $eventType=$json->{data}->{eventType};
      $eventType='unknown' unless defined $eventType;
      if(exists $activity->{verb}) {
        my $verb=$activity->{verb};
        $verb='unknown' unless defined($verb);
        if($eventType eq 'conversation.activity') {
          if($verb=~ /post|share/) {
            if(exists $activity->{actor}) {
	      my $actor=$activity->{actor};

	      if($self->currentUser->{displayName} eq $actor->{displayName}) {
	        $self->log_debug("ignoring message because we sent it");
                $self->setPing();
	        return;
	      }
  	      $self->run_lookup('que_getMessage',sub {
	        my ($agent,$id,$result,$req,$resp)=@_;
                $self->on_message->($self,$result,$eventType,$verb,$json);
	      },$activity->{id});
	    } 
	  } elsif($verb eq 'add' and $activity->{object}->{objectType} eq 'person') {
	    my $args={
	      roomId=>$activity->{target}->{id},
	      personEmail=>$activity->{object}->{emailAddress},
	    };
	    $self->run_lookup('que_listMemberships',sub {
	      my ($agent,$id,$result,$req,$resp)=@_;
              $self->on_message->($self,$result,$eventType,$verb,$json);
	    },$args);
	  } elsif($verb eq 'create') {
	    my $args={
	      personId=>$self->currentUser->{id},
	    };
	    $self->run_lookup('que_listMemberships',sub {
	      my ($agent,$id,$result,$req,$resp)=@_;
              $self->on_message->($self,$result,$eventType,$verb,$json);
	    },$args);
	  } elsif($verb=~ /lock|unlock|update/) {
	    $self->run_lookup('que_getRoom',sub {
	      my ($agent,$id,$result,$req,$resp)=@_;
              $self->on_message->($self,$result,$eventType,$verb,$json);
	    },$activity->{object}->{id});
	  } else {
            $self->on_message->($self,$self->new_false("Unsupported EventType: [$eventType] and Verb: [$verb]"),$eventType,$verb,$json);
	  }
        } else {
          $self->on_message->($self,$self->new_false("Unsupported EventType: [$eventType] and Verb: [$verb]"),$eventType,$verb,$json);
        }
      } else {
        my $eventType=defined($json->{data}->{eventType}) ? $json->{data}->{eventType} : 'unknown';
        my $verb=defined($json->{data}->{activity}->{verb}) ? $json->{data}->{activity}->{verb} : 'unknown';
        $self->on_message->($self,$self->new_false("Unsupported EventType: [$eventType] and Verb: [$verb]"),$eventType,'unknown',$json);
      }
    } else {
      my $eventType=defined($json->{data}->{eventType}) ? $json->{data}->{eventType} : 'unknown';
      my $verb=defined($json->{data}->{activity}->{verb}) ? $json->{data}->{activity}->{verb} : 'unknown';
      $self->on_message->($self,$self->new_false("Unsupported EventType: [$eventType] and Verb: [$verb]"),$eventType,$verb,$json);
    }
  }
  $self->setPing();
}

=item * $self->run_lookup($method,$cb,@args);

Shortcut for:

  $self->spark->$method($cb,@args);
  $self->agent->run_next;

=cut

sub run_lookup {
  my ($self,$method,$cb,@args)=@_;
  
  $self->spark->$method($cb,@args);
  $self->agent->run_next;
}


=item * $self->handle_reconnect() 

Handles reconnecting to spark

=cut

sub handle_reconnect : BENCHMARK_INFO {
  my ($self)=@_;
  $self->ping(undef);
  $self->connection->close if $self->connection;

  my $ping=AnyEvent->timer(after=>$self->reconnect_sleep,cb=>sub {
    $self->que_getWsUrl(sub { $self->start_connection });
    $self->agent->run_next;
  });
  $self->ping($ping);
}

=item * $self->setPing()

Sets the next ping object

=cut

sub setPing {
  my ($self)=@_;

  $self->ping(undef);
  my $ping=AnyEvent->timer(after=>$self->pingEvery,cb=>sub {

    unless($self->connection) {
      $self->ping(undef);
      $self->log_error('current conenction is not valid?');
      return;
    }
    my $id=$self->uuidv4;
    $self->lastPing($id);
    $self->connection->send(to_json({ type=>'ping', id=> $id, }));
    $self->setPingWait;
  });
  $self->ping($ping);
}

=item * $self->setPingWait() 

This method is called by ping, sets a timeout to wait for the response.

=cut

sub setPingWait {
  my ($self)=@_;
  $self->ping(undef);
  my $wait=AnyEvent->timer(after=>$self->pingWait,cb=>sub {
    $self->ping(undef);
    $self->handle_reconnect;
  });
  $self->ping($wait);
}

=item * my $result=$self->getLastConn() 

Fetches the last connection info

Returns a Data::Result Object, when true it contains the hash, when false it contains why it failed.

=cut

sub getLastConn : BENCHMARK_DEBUG {
  my ($self)=@_;

  my $lc=$self->lastConn;
  if(-r $lc) {
    my $fh=IO::File->new($lc,'r');
    return $self->new_false("Could not open file: $lc, error was: $!") unless $fh;

    my $str=join '',$fh->getlines;
    $fh->close;

    my $json=eval { from_json($str) };
    if($@) {
      return $self->new_false("Could not parse $lc, error was: $@");
    }

    return $self->new_true($json);
  }

  return $self->new_false("Could not read $lc");
}

=item * my $result=$self->saveLastConn($ref) 

Saves the last conenction, returns a Data::Result Object

$ref is assumed to be the data strucutre intended to be serialzied into json

=cut

sub saveLastConn : BENCHMARK_DEBUG {
  my ($self,$ref)=@_;
  my $json=to_json($ref,{pretty=>1});

  my $fh=IO::File->new($self->lastConn,'w');
  return $self->new_false("Failed to create: [".$self->lastConn."] error was: [$!]") unless $fh;

  $fh->print($json);

  return $self->new_true($json);
}

=item * my $job_id=$self->que_deleteLastUrl($cb) 

Returns a Data::Result Object, when true it contains the url that was deleted, when false it contains why it failed.

=cut

sub que_deleteLastUrl : BENCHMARK_INFO {
  my ($self,$cb)=@_;
  my $result=$self->getLastConn();

  return $self->queue_result($cb,$result) unless $result;

  my $json=$result->get_data;
  return $self->queue_result($cb,$self->new_false('URL not found in json data strucutre')) unless exists $json->{url};
  my $url=$json->{url};

  my $req=new HTTP::Request(DELETE=>$url,$self->default_headers);
  return $self->queue_request($req,$cb);
}

=item * my $job_id=$self->que_getWsUrl($cb) 

Gets the WebSocket URL

Returns a Data::Result Object: When true it contains the url. When false it contains why it failed.

=cut

sub que_getWsUrl  : BENCHMARK_INFO {
  my ($self,$cb)=@_;
  
  $self->que_deleteLastUrl(\&log_delete_call);

  my $run_cb=sub {
    my ($self,$id,$result)=@_;

    if($result) {
      my $json=$result->get_data;
      $self->connInfo($json);
      $self->saveLastConn($json);
    }
    
    $cb->(@_);
  };
  my $req=new HTTP::Request(POST=>$self->defaultUrl,$self->default_headers,$self->deviceDesc);
  return $self->queue_request($req,$run_cb);
}

=item * $self->log_delete_call($id,$result)

Call back to handle logging clean up of previous session

=cut

sub log_delete_call : BENCHMARK_INFO { 
  my ($self,$id,$result)=@_;
  if($result) {
    $self->log_always("Removed old device object without error");
  } else {
    $self->log_always("Failed to remove old device, error was: $result");
  }
}

=back

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
