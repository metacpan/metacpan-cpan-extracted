package Conductrics::Agent;

use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw( Str );
use MooseX::Types::URI qw(Uri);
use URI;
use URI::QueryParam;
use JSON::MaybeXS;
use Time::HiRes;
use LWP::UserAgent;
use Data::Dumper;

our $VERSION = '0.004';
$VERSION = eval $VERSION;

sub build_uri { 
    my($self)=@_;
    return URI->new($self->baseUrl); 
}

has 'apiKey' => (is=>'ro', isa=>Str, required=>1);
has 'ownerCode' => (is=>'ro', isa=>Str, required=>1);
has 'baseUrl' => (is=>'ro', isa=>Str, required=>1);
has 'baseUri' => (is=>'ro', isa=>Uri, lazy=>1, builder=>'build_uri');
has 'sessionId' => (is=>'rw', isa=>Str);
has 'name' => (is=>'rw', isa=>Str, required=>1);

my $ua = LWP::UserAgent->new();
$ua->agent('Perl Conductrics::Agent');
$ua->timeout(2);
$ua->env_proxy;

sub _request {
    my ($self, $uri, @params) = @_;
    my ($seconds, $microseconds) = Time::HiRes::gettimeofday;
    my %parameters = (nocache=>"$seconds$microseconds", apikey=>$self->apiKey, session=>$self->sessionId, @params);
    for my $k (keys %parameters) {
	$uri->query_param_append($k, $parameters{$k});
    }

    my $response = $ua->get($uri);
    if ($response->is_success) {
	if ($response->code != 200) {
	    warn "Content: ", $response->decoded_content;  # or whatever
	    warn "Code: ", $response->code;
	    warn "Err:", $response->message;
	    warn "Something get wrong on response";
	    warn Dumper($response);
	}

	JSON::MaybeXS::decode_json($response->decoded_content);
    } else {
	warn "Content: ", $response->decoded_content;  # or whatever
	warn "Code: ", $response->code;
	warn "Err:", $response->message;
	die $response->status_line;
    }
}

sub decide {
    my ($self, $session, @choices) = @_;
    my $uri = $self->baseUri->clone;
    $self->sessionId($session);
    my ($answer, $kind);
    if ('ARRAY' eq ref $choices[0]) {
	# Multi decisions request simple  ([ qw/ red black green / ], [ qw/ verdana arial /] )
	$uri->path_segments($self->ownerCode, $self->name, "decisions", map { join(',', @{$_}) } @choices );
    } elsif ('HASH' eq ref $choices[0]) {
	# Multi decision request with names ( {colour=>[qw/red black green/] }, { font=>[qw/ verdana arial /] })
	$uri->path_segments($self->ownerCode, $self->name, "decisions", map { my ($k) = keys %{$_}; "$k:" . join (",", map {$_} @{$_->{$k}} ) } @choices );
    } else {
	# single decision
	$kind = 'single';
	$uri->path_segments($self->ownerCode, $self->name, "decision", join(',', @choices));
    }
    # handle multidecision answer
    eval {
	$answer = $self->_request(
	    $uri,
	    );
    };
    if ($@) {
	die('Not able to get decision');
    }
    return $answer->{decision} if ( 'single' eq $kind );
    return $answer;
}


sub get_decisions {
    my ($self, $session, $point) = @_;
    my $uri = $self->baseUri->clone;
    $self->sessionId($session);
    $uri->path_segments($self->ownerCode, $self->name, "decisions" );
    # handle multidecision answer
    my $answer;
    eval {
	$answer = $self->_request(
	    $uri,
	    point=>$point,
	    );
    };
    if ($@) {
	die('Not able to get decision');
    }
    return $answer;
}



sub reward {
    my ($self, $session, $goalCode, $value) = @_;
    $value = 1 unless (defined $value);
    my $uri = $self->baseUri->clone;
    $uri->path_segments($self->ownerCode, $self->name, 'goal', $goalCode);
    $self->sessionId($session);
    my $answer;
    eval {
	$answer = $self->_request(
	    $uri,
	    reward=>$value,
	    );
    };
    if ($@) {
	die("Not able to set reward");
    }
    return $answer;
}

sub expire {
    my ($self, $session) = @_;
    my $uri = $self->baseUri->clone;
    $uri->path_segments($self->ownerCode, $self->name, "expire");
    $self->sessionId($session);
    my $answer;
    eval {
	$answer = $self->_request($uri);
    };
    if ($@) {
	die("Not able to expire");
    }
    return $answer;
}

1;

=encoding utf-8

=head1 NAME

Conductrics Agent

=head1 DESCRIPTION

First I've got php agent API from conductrics github (https://github.com/conductrics/conductrics-php) 
and I've rewritten it in Modern Perl, then I've improved it.

I've substituted rand() calls with less cpu expensive Time::Hires to unvalidate cache.

I'll use this module for a new Catalyst model.


=head1 SYNOPSIS

    use Conductrics::Agent;

    my $agent = Conductrics::Agent->new(
	name=>'', # your conductrics agent
	apiKey=>'',    # place your apikey here
	ownerCode=>'', # place your ownerCode here
	baseUrl=>'http://api.conductrics.com',
    );

    #
    # $agent will ask for a decision the conductrics server about which colour
    #
    my $choice = $agent->decide($userSessionid, qw/red jellow green blue/);
    print "$choice\n";


=head1 METHODS


=head2 decide()

Whenever in your code you want to act using decision evaluated by Conductrics you just call decide in
a proper form, simple, multiple with names or nameless.

=head2 decide($sessionId, @choices)

Conductrics will compute the decision and this returns which $choice.

=head2 decide($sessionId, {decisionN1=>[ qw/option1 option2 option3/ ]}, {decisionN2=>[ qw/anotherOpt oneMoreOpt / ]})

=head2 decide($sessionId, [ qw/option1 option2 option3/ ], [ qw/anotherOpt oneMoreOpt / ] )

decisionN1 is only a placeholder for name you have choose for this decision point as well as decisionN2 is another name you like.

Here is how to use Multi-Faceted Decisions, with or without name: you are asking at the server more than one 
Here some words from the conductrics help: 
"Whenver you ask us for a decision, we'll pick one option from each list, and send them back to you in one answer."
"We're basically doing multivariate testing ("MVT") for you, tracking the success of combinations of options rather than each option individually."


=head2 get_decision($session, $pointCode)

If you have defined more decision points for your agent, you can get decisions from Conductrics
using 'point code'.
While decide() needs more information, with this call you have already provided those information to the server
during agent's definition.

To define agents see Conductrics::API::Client.


=head2 reward($sessionId, $goalCode, [$value])

Conductrics will collect the numeric value about the goalCode. This is the way it learn whick decisions are winning.

=head2 expire($sessionId)

You are notifing that this session has been closed, for example on user logout action.

http://www.conductrics.com/ for more info about their analysis service.


=head1 TESTS


=head2 Execute full test suite

First you have to create two test agents following these description:

{
  "code": "test-agent",
  "owner": "$your_ownerCode",

  "goals": [
    {"code": "goal-1"}
  ],

  "points": [
    {
    "code": "point-1",
    "decisions": [
        {
          "code": "colori",
          "choices": [
            {"code": "rosso"},
            {"code": "giallo"}
          ]
        }
      ]
    }
  ]
}

and

{
  "code": "mvt-agent",
  "owner": "$your_ownerCode",

  "goals": [
    {"code": "goal-2"}
  ],

  "points": [
    {
    "code": "point-2",
    "decisions": [
        {
          "code": "colour",
          "choices": [
            {"code": "red"},
            {"code": "black"},
            {"code": "green"}
          ]
        },
        {
          "code": "font",
          "choices": [
            {"code": "Helvetica"},
            {"code": "Times"}
          ]
        }
      ]
    }
  ]
}


You have to set some env to execute t/02-real_test.t
You will find your data into Account/Keys and Users page.

Required env for execute full test's suite:

       Conductrics_apikey
       Conductrics_ownerCode
       Conductrics_agent_name=test-agent
       Conductrics_mvt_agent_name=mvt-agent

Test's sources are good examples about how to use this API, so "Use The Source Luke".


=head1 MORE INFO

Conductrics has many help pages available from the console, so signup and read it.

http://conductrics.com/

There are also Report API, Management API and Targetting Rule API.

=head2 ToDo

I wuold like to return promises for handling non blocking request to conductrics server.


=head1 AUTHORS

 Ferruccio Zamuner - nonsolosoft@diff.org

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.


=cut


