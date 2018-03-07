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

=head1 NAME

AnyEvent::HTTP::Spark - HTTP Rest Client for Cisco Spark

=head1 SYNOPSIS

  use AnyEvent::HTTP::Spark;

  my $obj=new AnyEvent::HTTP::Spark(token=>$ENV{SPARK_TOKEN});

=head1 DESCRIPTION

THe HTTP Rest client used to interact with the Cisco Spark Web Service.

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

=head1 OO Methods

=over 4

=item * my $id=$self->que_listPeople($cb,$args);

Ques a request to list people.

$args is assumed to be a hash ref

Default arguments
  maxResults: 100, sets the number of results

Search arguments ( use one set )

Email Search
  email: Someoen@somewhere.com

Display Name Search

  displayName: firstname lastname

In theory you can paginate with this api call, although there is no documentation from cisco to validate this.  
 
=cut

sub que_listPeople {
  my ($self,$cb,$args)=@_;
  my $url="people";

  my $search={
    maxResults=>100,
    %{$args},
  };
  return $self->que_get($cb,$url,$search);
}

=item * my $id=$self->que_createPerson($cb,$data);

Que's the creation of a person

$data is expected to be an anonymous hash ref

  emails:  string[]	
  displayName:  string	
  firstName:  string	
  lastName:  string	
  avatar:  string	
  orgId:  string	
  roles:  string[]	
  licenses:  string[]

=cut

sub que_createPerson {
  my ($self,$cb,$data)=@_;
  return $self->que_post_json($cb,"people",$data);
}

=item * my $id=$self->que_getPerson($cb,$personId);

Que's up a personId lookup.

=cut

sub que_getPerson {
  my ($self,$cb,$personid)=@_;

  return $self->que_get($cb,"people/$personid");
}

=item my $id=$self->que_getMe() 

Que's a request to identify this current user.

=cut

sub que_getMe {
  my ($self,$cb)=@_;
  return $self->que_get($cb,"people/me");
}

=item * my $id=$self->que_getMessage($cb,$messageId)

Que's a request for a given messageId

=cut

sub que_getMessage {
  my($self,$cb,$id)=@_;
  return $self->que_get($cb,"messages/$id");
}

=item * my $id=$self->que_createMessage($cb,$data)

Creates a message

$data is assumed to be an anonymous hash ref

keys/Values:

 roomId:	string	
 toPersonId:    string	
 toPersonEmail: string	
 text:          string	
 markdown:      string	
 files:         string[] 

=cut

sub que_createMessage {
  my ($self,$cb,$data)=@_;

  return $self->que_post_json($cb,"messages",$data);
}

=back

=head2 Low Level Request functions

This section documents low level request functions.

=over 4

=cut

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

  return $self->que_result($cb,$result) unless $result;
  my $request=$result->get_data;

  return $self->queue_request($request,$cb);
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

  my $request=new HTTP::Request(POST=>$uri,$self->default_headers,$json);
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
  return $self->queue_request($cb,$req);
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
    $cb->($id,$self->new_true({message=>'Deleted'}),$request,$response);
  } else {
    $cb->($id,$self->new_false("Delete Failed, error was: ".$response->status_line),$request,$response);
  }
}

=back

=head1 AUTHOR

Michael Shipper <AKALINUX@CPAN.ORG>

=cut

1;
