package AnyEvent::HTTP::Spark;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);
use Data::Dumper;
use JSON qw(to_json from_json);
use HTTP::Request::Common qw(POST);
use Ref::Util qw(is_plain_arrayref is_plain_hashref);
use URI::Escape qw(uri_escape_utf8);
use namespace::clean;
use Scalar::Util qw(looks_like_number);
use AnyEvent;

BEGIN { 
  no namespace::clean;
  with 'HTTP::MultiGet::Role','Log::LogMethods','AnyEvent::SparkBot::SharedRole';
}

has api_url=>(
  isa=>Str,
  is=>'ro',
  lazy=>1,
  default=>'https://api.ciscospark.com/v1/',
);

has retryCount=>(
  isa=>Int,
  is=>'ro',
  default=>1,
);

has retryAfter=>(
  isa=>Int,
  is=>'ro',
  default=>10,
);

has retries=>(
  isa=>HashRef,
  is=>'ro',
  default=>sub { return {} },
);

=head1 NAME

AnyEvent::HTTP::Spark - Syncrnous/Asyncrnous HTTP Rest Client for Cisco Spark

=head1 SYNOPSIS

  use AnyEvent::HTTP::Spark;
  my $obj=new AnyEvent::HTTP::Spark(token=>$ENV{SPARK_TOKEN});

=head1 DESCRIPTION

Dual Nature Syncrnous/Asyncrnous AnyEvent friendly Spark v1 HTTP Client library.

=head1 Moo Roles Used

This class uses the following Moo Roles

  HTTP::MultiGet::Role
  Log::LogMethods
  Data::Result::Moo
  AnyEvent::SpakBot::SharedRole

=head1 OO Arguments and accessors

Required OO Arguments

  token: required for spark authentication

Optional OO Arguments

  logger: sets the logging object
  agent: AnyEvent::HTTP::MultiGet object
  api_url: https://api.ciscospark.com/v1/
    # sets the web service the requests point to
  retryCount: 1, how many retries to attempt when getting a 429 error

Options set at runtime

  retries: anymous hash, used to trak AnyEvent->timer objects

=cut

# This method runs after the new constructor
sub BUILD {
  my ($self)=@_;
}

# this method runs before the new constructor, and can be used to change the arguments passed to the module
around BUILDARGS => sub {
  my ($org,$class,@args)=@_;
  
  return $class->$org(@args);
};

=head1 OO Web Methods and special Handlers

Each web method has a blocking and a non blocking context.

Any Method with a prefix of que_ can be called in either a blocking or a non blocking context.  Most people will use the blocking interface of the client.

Non Blocking context for use with AnyEvent Loops

  my $cb=sub {
    my ($self,$id,$result,$request,$response)=@_;
    if($result) {
      print Dumper($result->get_data);
    } else {
      ...
    }
  };
  my $id=$self->que_listPeople($cb,$args);
  $self->agent->run_next;

Blocking Context

  my $result=$self->listPeople($args);
  if($result) {
    print Dumper($result->get_data);
  } else {
    die $result;
  }


=head1 People

=head2 Get Me

=over 4

=item * Blocking my $result=$self->getMe() 

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getMe($cb) 

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=cut

sub que_getMe {
  my ($self,$cb)=@_;
  return $self->que_get($cb,"people/me");
}

=back

=head2 List People

=over 4

=item * Blocking my $result=$self->listPeople($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listPeople($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Person

=over 4

=item * Blocking my $result=$self->getPerson($personId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getPerson($cb,$personId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$personId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Person

=over 4

=item * Blocking my $result=$self->createPerson($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createPerson($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Person

=over 4

=item * Blocking my $result=$self->deletePerson($personId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deletePerson($cb,$personId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$personId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Person

=over 4

=item * Blocking my $result=$self->updatePerson($personId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updatePerson($cb,$personId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$personId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Rooms

=head2 List Rooms

=over 4

=item * Blocking my $result=$self->listRooms($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listRooms($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Room

=over 4

=item * Blocking my $result=$self->getRoom($roomId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getRoom($cb,$roomId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Room

=over 4

=item * Blocking my $result=$self->createRoom($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createRoom($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Room

=over 4

=item * Blocking my $result=$self->deleteRoom($roomId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteRoom($cb,$roomId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Room

=over 4

=item * Blocking my $result=$self->updateRoom($roomId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateRoom($cb,$roomId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Memberships

=head2 List Memberships

=over 4

=item * Blocking my $result=$self->listMemberships($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listMemberships($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Membership

=over 4

=item * Blocking my $result=$self->getMembership($membershipId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getMembership($cb,$membershipId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$membershipId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Membership

=over 4

=item * Blocking my $result=$self->createMembership($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createMembership($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Membership

=over 4

=item * Blocking my $result=$self->deleteMembership($membershipId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteMembership($cb,$membershipId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$membershipId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Membership

=over 4

=item * Blocking my $result=$self->updateMembership($membershipId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateMembership($cb,$membershipId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$membershipId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Messages

=head2 List Messages

Special Notes on bots for this method, bots can only list messages refering to the bot itself. This means there are 2 manditory arguments when using a bot.  If mentionedPeople is not set to the litteral string 'me' a bot will encounter a 403 error.

$hashRef Required options

  roomId: the id for the room
  mentionedPeople: me

=over 4

=item * Blocking my $result=$self->listMessages($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listMessages($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Message

=over 4

=item * Blocking my $result=$self->getMessage($messageId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getMessage($cb,$messageId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$messageId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Message

=over 4

=item * Blocking my $result=$self->createMessage($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createMessage($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Message

=over 4

=item * Blocking my $result=$self->deleteMessage($messageId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteMessage($cb,$messageId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$messageId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Teams

=head2 List Teams

=over 4

=item * Blocking my $result=$self->listTeams($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listTeams($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Team

=over 4

=item * Blocking my $result=$self->getTeam($teamId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getTeam($cb,$teamId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Team

=over 4

=item * Blocking my $result=$self->createTeam($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createTeam($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Team

=over 4

=item * Blocking my $result=$self->deleteTeam($teamId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteTeam($cb,$teamId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Team

=over 4

=item * Blocking my $result=$self->updateTeam($teamId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateTeam($cb,$teamId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Team Memberships

=head2 List Team Memberships

=over 4

=item * Blocking my $result=$self->listTeamMemberships($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listTeamMemberships($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Team Membership

=over 4

=item * Blocking my $result=$self->getTeamMembership($teamMembershipId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getTeamMembership($cb,$teamMembershipId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamMembershipId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Team Membership

=over 4

=item * Blocking my $result=$self->createTeamMembership($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createTeamMembership($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Team Membership

=over 4

=item * Blocking my $result=$self->deleteTeamMembership($teamMembershipId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteTeamMembership($cb,$teamMembershipId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamMembershipId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Team Membership

=over 4

=item * Blocking my $result=$self->updateTeamMembership($teamMembershipId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateTeamMembership($cb,$teamMembershipId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$teamMembershipId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Webhooks

=head2 List Webhooks

=over 4

=item * Blocking my $result=$self->listWebhooks($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listWebhooks($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Webhook

=over 4

=item * Blocking my $result=$self->getWebhook($webhookId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getWebhook($cb,$webhookId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$webhookId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Webhook

=over 4

=item * Blocking my $result=$self->createWebhook($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createWebhook($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Webhook

=over 4

=item * Blocking my $result=$self->deleteWebhook($webhookId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteWebhook($cb,$webhookId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$webhookId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Webhook

=over 4

=item * Blocking my $result=$self->updateWebhook($webhookId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateWebhook($cb,$webhookId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$webhookId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Organizations

=head2 List Organizations

=over 4

=item * Blocking my $result=$self->listOrganizations($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listOrganizations($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Organization

=over 4

=item * Blocking my $result=$self->getOrganization($organizationId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getOrganization($cb,$organizationId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$organizationId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Licenses

=head2 List Licenses

=over 4

=item * Blocking my $result=$self->listLicenses($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listLicenses($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get License

=over 4

=item * Blocking my $result=$self->getLicense($licenseId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getLicense($cb,$licenseId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$licenseId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Roles

=head2 List Roles

=over 4

=item * Blocking my $result=$self->listRoles($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listRoles($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Role

=over 4

=item * Blocking my $result=$self->getRole($roleId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getRole($cb,$roleId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roleId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Events

=head2 List Events

=over 4

=item * Blocking my $result=$self->listEvents($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listEvents($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Event

=over 4

=item * Blocking my $result=$self->getEvent($eventId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getEvent($cb,$eventId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$eventId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=cut

__PACKAGE__->_build_common("people",qw(list get create delete update));
__PACKAGE__->_build_common("rooms",qw(list get create delete update));
__PACKAGE__->_build_common("meetings",qw(list get create delete update));
__PACKAGE__->_build_common("memberships",qw(list get create delete update));
__PACKAGE__->_build_common("messages",qw(list get create delete));
__PACKAGE__->_build_common("teams",qw(list get create delete update));
__PACKAGE__->_build_common("team/memberships",qw(list get create delete update));
__PACKAGE__->_build_common("webhooks",qw(list get create delete update));
__PACKAGE__->_build_common("organizations",qw(list get));
__PACKAGE__->_build_common("licenses",qw(list get));
__PACKAGE__->_build_common("roles",qw(list get));
__PACKAGE__->_build_common("events",qw(list get));

sub _build_common {
  my ($class,$path,@todo)=@_;
  foreach my $method (@todo) {
    my $label=$path;
    $label=~ s/^(.)/uc($1)/se;
    $label="que_".$method.$label;
    my $code;
    if($method ne 'list') {
      $label=~ s/s$//s ;
      $label=~ s/People/Person/s;
    }
    $label=~ s#/(.)#uc($1)#se;
    
    if($method eq 'list') {
      $code=sub {
        my ($self,$cb,$args)=@_;
        my $url=$path;

        my $run=sub {
          my ($self,$id,$result,$request,$response)=@_;
          $self->handle_paginate($id,$result,$request,$response,$cb);
        };
        return $self->que_get($run,$url,$args);
      };
    } elsif($method eq 'update') {
      $code=sub {
        my ($self,$cb,$targetId,$data)=@_;
	return $self->queue_result($cb,$self->new_false("${method}Id is a requried argument")) unless defined($targetId);
        return $self->que_put_json($cb,"$path/$targetId",$data);
      };
    } elsif($method eq 'get') {
      $code=sub {
        my ($self,$cb,$targetId,$data)=@_;
	return $self->queue_result($cb,$self->new_false("${method}Id is a requried argument")) unless defined($targetId);
        return $self->que_get($cb,"$path/$targetId",$data);
      };
    } elsif($method eq 'delete') {
      $code=sub {
        my ($self,$cb,$targetId,$data)=@_;
	return $self->queue_result($cb,$self->new_false("${method}Id is a requried argument")) unless defined($targetId);
        return $self->que_delete($cb,"$path/$targetId",$data);
      };
    } elsif($method eq 'create') {
      $code=sub {
        my ($self,$cb,$data)=@_;
        return $self->que_post_json($cb,"$path",$data);
      };
    } else {
      die "Er um.. $method isn't supported yet";
    }
    no strict 'refs';
    *{$label}=$code;
  }
}

=head1 Meetingss

=head2 List Meetingss

=over 4

=item * Blocking my $result=$self->listMeetingss($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_listMeetingss($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Get Meetings

=over 4

=item * Blocking my $result=$self->getMeetings($roomId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_getMeetings($cb,$roomId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Create Meetings

=over 4

=item * Blocking my $result=$self->createMeetings($hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_createMeetings($cb,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Delete Meetings

=over 4

=item * Blocking my $result=$self->deleteMeetings($roomId)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_deleteMeetings($cb,$roomId)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head2 Update Meetings

=over 4

=item * Blocking my $result=$self->updateMeetings($roomId,$hashRef)

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $id=$self->que_updateMeetings($cb,$roomId,$hashRef)

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };


=back

=head1 Attaching files to messages

Posting files to channel steps outside of the traditional json data format. 

=over 4 

=item * Blocking my $result=$self->uploadFile('/path/to/file',%args);

Returns a L<Data::Result> Object, when true it contains the data, when false it contains why it failed.

=item * Non-Blocking my $result=$self->que_uploadFile($cb,'/path/to/file',%args);

Example Callback

  $cb=sub {
    my ($self,$id,$result,$request,$response,$roomId,$hashRef)=@_;
      # 0: $self The current AnyEvent::HTTP::Slack object
      # 1: $id the id of the http request
      # 2: Data::Result Object
      # 3: HTTP::Request Object
      # 4: HTTP::Result Object
    };

=back

=cut

sub que_uploadFile {
  my ($self,$cb,$file,%args)=@_;

  my $post=[
    %args,
    files=>[$file],
  ];

  my $url=$self->api_url.'messages';
  my $request=POST($url,Content_type=>'form-data',Content=>$post);
  $request->header(Authorization=>"Bearer ".$self->token);
  return $self->queue_request($request,$cb);
}

=head1 Low Level Request functions

This section documents low level request functions.

=over 4

=cut

=item * $self->handle_paginate($id,$result,$request,$response,$cb) 

Internal Method wrapper for parsing pagination headers.

Example:

  my $code=sub {
    my ($self,$id,$result,$request,$response)=@_;
    $self->handle_paginate($id,$result,$request,$response,$cb);
  };
  return $self->que_get($code,$url,$args);

Pagination information can be found in the following result fields.

  cursorPosition: last|next|prev|first
  pageLink: (undef when cursorPosition eq 'last') Url to the next page

=cut

sub handle_paginate {
  my ($self,$id,$result,$request,$response,$cb)=@_;
   if($result) {
     my $headers={$response->headers->flatten};
     my $data=$result->get_data;
     $data->{cursorPosition}='last';
     $data->{pageLink}='';
     if(exists $headers->{Link}) {
       my $link=$headers->{Link};
       if($link=~ /^<([^>]+)>;\s+rel="(\w+)"\s*$/s) {
         $data->{pageLink}=$1;
         $data->{cursorPosition}=$2;
       }
     } 
  }

  $cb->(@_);
}

=item * my $result=$self->build_post_json($url,$data);

Returns a Data::Result object; When true it contains an HTTP::Request Object For $url, the body will consist of $data converted to json.  When false it contains why it failed.

=cut

sub build_post_json {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url;
  my $json=eval {to_json($data)};
  return $self->new_false("Failed to convert \$data to json, error was $@") if $@;

  my $request=new HTTP::Request(POST=>$uri,$self->default_headers,$json);
  return $self->new_true($request);
}

=item * my $id=$self->queue_builder($cb,$method,$url,$data);

Returns the ID of the object in the request for $method.

=cut

sub queue_builder {
  my ($self,$cb,$method,$url,$data)=@_;

  my $result=$self->$method($url,$data);
  return $self->queue_result($cb,$result) unless $result;
  my $request=$result->get_data;

  my $wrap;
  my $count=$self->retryCount;
  if($self->is_blocking) {
    $wrap=sub {
      my ($self,$id,$result,undef,$response)=@_;

      return $cb->(@_) if $result or !($response->code==429 and $count-- >0);
      my $timeout=looks_like_number($response->header('Retry-After')) ? $response->header('Retry-After') : $self->retryTimeout;
      $self->log_warn("Request: $id recived a 429 response, will retry in $timeout seconds");
      

      if($count>0)  {
        my $next_id=$self->queue_request($request,sub { 
          my ($self,undef,$result,undef,$response)=@_;
	  $wrap->($self,$id,$result,$request,$response);
	});
        $self->add_ids_for_blocking($next_id);
        return $self->agent->run_next;
      }

      sleep $timeout;
      my $code=sub {
        my ($self,undef,$result,undef,$response)=@_;
	$cb->($self,$id,$result,$request,$response);
      };
      
      my $next_id=$self->queue_request($request,$code);
      $self->add_ids_for_blocking($next_id);
      $self->agent->run_next;
    };
  } else {
    $wrap=sub {
      my ($self,$id,$result,undef,$response)=@_;
      return $cb->(@_) if $result or !($response->code==429 and $count-- >0);
      my $timeout=looks_like_number($response->header('Retry-After')) ? $response->header('Retry-After') : $self->retryTimeout;
      $self->log_warn("Request: $id recived a 429 response, will retry in $timeout seconds");

      if($count>0)  {
	my $ae;
	$ae=AnyEvent->timer(after=>$timeout,cb=>sub {
          my $next_id=$self->queue_request($request,sub { 
            my ($self,undef,$result,undef,$response)=@_;
	    $wrap->($self,$id,$result,$request,$response);
	  });
          $self->add_ids_for_blocking($next_id);
          $self->agent->run_next;
	  delete $self->retries->{$ae};
	  undef $ae;
	});
	return $self->retries->{$ae}=$ae;
      }
      my $code=sub {
        my ($self,undef,$result,undef,$response)=@_;
	$cb->($self,$id,$result,$request,$response);
      };

      my $ae;
      $ae=AnyEvent->timer(after=>$timeout,cb=>sub {
        my $next_id=$self->queue_request($request,$code);
        $self->add_ids_for_blocking($next_id);
        $self->agent->run_next;
	delete $self->retries->{$ae};
	undef $ae;
      });
      return $self->retries->{$ae}=$ae;

    };
  }



  return $self->queue_request($request,$wrap);
}


=item * my $id=$self->que_post_json($cb,$url,$data);

Queue's a json post and returns the id

=cut

sub que_post_json {
  my ($self,$cb,$url,$data)=@_;
  return $self->queue_builder($cb,'build_post_json',$url,$data);
}

=item * my $result=$self->build_put_json($url,$data);

Returns a Data::Result object; When true it contains an HTTP::Request Object For $url, the body will consist of $data converted to json.  When false it contains why it failed.

=cut

sub build_put_json {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url;
  my $json=eval {to_json($data)};
  return $self->new_false("Failed to convert \$data to json, error was $@") if $@;

  my $request=new HTTP::Request(PUT=>$uri,$self->default_headers,$json);
  return $self->new_true($request);
}

=item * my $id=$self->que_put_json($cb,$url,$data);

Queue's a json put and returns the id

=cut

sub que_put_json {
  my ($self,$cb,$url,$data)=@_;
  return $self->queue_builder($cb,'build_put_json',$url,$data);
}

=item * my $result=$self->build_post_form($url,$data);

Returns a Data::Result Object, when true it contains the correctly fromatted HTTP::Request Object, when false it contains why it failed.

=cut

sub build_post_form {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url;
  my $form_ref;
  if(is_plain_arrayref($data)) {
    $form_ref=$data;
  } elsif(is_plain_hashref($data)) {
    $form_ref=[%{$data}];
  } else {
    $self->new_failse('Failed to create form post, error was: $data is not a hash or array ref');
  }

  my $headers=$self->default_headers;
  $headers->header('Content-Type', 'multipart/form-data');

  my $post=POST $uri,$data;
  my @list=$headers->flatten;

  while(my ($key,$value)=splice @list,0,2) {
    $post->header($key,$value);
  }

  return $self->new_true($post);
}

=item * my $id=$self->que_post_form($cb,$url,$data);

Queue's a form post and returns the id

=cut

sub que_post_form {
  my ($self,$cb,$url,$data)=@_;
  return $self->queue_builder($cb,'build_post_form',$url,$data);
}

=item * my $result=$self->build_get($url,$data);

Returns a Data::Result Object, when true it contains the correctly fromatted HTTP::Request Object, when false it contains why it failed.

=cut

sub build_get {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url.'?';
  my @list;
  if(is_plain_arrayref($data)) {
    @list=@{$data};
  } elsif(is_plain_hashref($data)) {
    @list=%{$data};
  }

  my $headers=$self->default_headers;

  my @args;
  while(my ($key,$value)=splice @list,0,2) {
    push @args,uri_escape_utf8($key).'='.uri_escape_utf8($value);
  }
  my $args=join '&',@args;
  $uri .=$args;

  my $get=new HTTP::Request(GET=>$uri,$self->default_headers);

  return $self->new_true($get);
}

=item * my $self->que_getRaw($cb,$raw_url) 

Que's a diy get request

=cut

sub que_getRaw {
  my ($self,$cb,$url)=@_;
  my $req=HTTP::Request->new(GET=>$url,$self->default_headers);
  return $self->queue_request($req,$cb);
}

=item * my $id=$self->que_get($cb,$url,$data);

Queue's a form post and returns the id

=cut

sub que_get {
  my ($self,$cb,$url,$data)=@_;
  return $self->queue_builder($cb,'build_get',$url,$data);
}

=item * my $result=$self->build_head($url,$data);

Returns a Data::Result Object, when true it contains the correctly fromatted HTTP::Request Object, when false it contains why it failed.

=cut

sub build_head {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url.'?';
  my @list;
  if(is_plain_arrayref($data)) {
    @list=@{$data};
  } elsif(is_plain_hashref($data)) {
    @list=%{$data};
  }

  my $headers=$self->default_headers;


  my @args;
  while(my ($key,$value)=splice @list,0,2) {
    push @args,uri_escape_utf8($key).'='.uri_escape_utf8($value);
  }
  my $args=join '&',@args;
  $uri .=$args;

  my $get=new HTTP::Request(HEAD=>$uri,$self->default_headers);

  return $self->new_true($get);
}

=item * my $id=$self->que_head($cb,$url,$data);

Queue's a form post and returns the id

=cut

sub que_head{
  my ($self,$cb,$url,$data)=@_;
  return $self->queue_builder($cb,'build_head',$url,$data);
}

=item * my $result=$self->build_delete($url,$data);

Returns a Data::Result Object, when true it contains the delete request, when false it contains why it failed.

=cut

sub build_delete {
  my ($self,$url,$data)=@_;

  my $uri=$self->api_url.$url.'?';
  my @list;
  if(is_plain_arrayref($data)) {
    @list=@{$data};
  } elsif(is_plain_hashref($data)) {
    @list=%{$data};
  }

  my $headers=$self->default_headers;

  my @args;
  while(my ($key,$value)=splice @list,0,2) {
    push @args,uri_escape_utf8($key).'='.uri_escape_utf8($value);
  }
  my $args=join '&',@args;
  $uri .=$args;

  my $get=new HTTP::Request(DELETE=>$uri,$self->default_headers);

  return $self->new_true($get);
}

=item * my $id=$self->que_delete($cb,$url,$data);

Ques a delete to run.

=cut

sub que_delete {
  my ($self,$cb,$url,$data)=@_;

  my $code=sub  {
    my ($self,$id,$result,$request,$response)=@_;
    $self->handle_delete($cb,$id,$result,$request,$response);
  };
  return $self->queue_builder($code,'build_delete',$url,$data);
}

=item * $self->handle_delete($cb,$id,$result,$result)

Internal handler for delete results

=cut

sub handle_delete {
  my ($self,$cb,$id,undef,$request,$response)=@_;
  if($response->code==204) {
    my $result=$self->new_true({message=>'Deleted'});
    $cb->($self,$id,$result,$request,$response);
  } else {
    my $result=$self->new_false("Delete Failed, error was: ".$response->status_line);
    $cb->($self,$id,$result,$request,$response);
  }
}

=back

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
