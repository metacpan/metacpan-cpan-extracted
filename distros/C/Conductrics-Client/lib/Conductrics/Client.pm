package Conductrics::Client;

=encoding utf-8

=head1 NAME

Conductrics Client

=head1 DESCRIPTION

This class give access to Conductrics Management API to:

 - define
 - create 
 - delete

an agent.

At start, I've written this class to automate tests of Conductrics::Agent, 
the user has not to learn how to create agent in Conductrics console before 
to run tests of Conductrics::Agent.

With this class you can automate the agent definition, 
use your data to create them in programmatic way, 
and I'm sure that it's better and powerfull.

=head1 SYNOPSIS

    use Conductrics::Client;

    my $client = Conductrics::Client->new(
	apiKey=>'',    # place your managent (admin) apikey here
	ownerCode=>'', # place your ownerCode here
	baseUrl=>'http://api.conductrics.com',
    );

    #
    # An agent will make decisions on the conductrics server.
    #

    my $decision_points = [
	$client->define_decision_point(
	    'home_page',
	    $client->define_decision( 'colour', qw/red green blue/ ),
	    $client->define_decision( 'font', qw/arial verdana/ )
	),
	$client->define_decision_point(
	    'auction',
	    $client->define_decision( 'message_mood', qw/estatic happy gambling/ ),
	    $client->define_decision( 'sort_by', qw/price time/ )
	),
    ];

    my $goals = $client->define_goals(qw/ registration bet sold subscription /);

    my $main_site_definition = $client->define_agent('main_site', $goals, $decision_points);

    unless ($client->validate_agent($client->get_json_schema, $main_site_definition)) {
         die("agent defition is not valid for agent json schema");
    }

    if ($client->create_agent('main_site', $main_site_definition)) {
        ... # success: agent is ready on conductrics server
    }


From another script/program you can then use the agent:
    

    my $agent = Conductrics::Agent->new(
        name=>'main_site',
	apiKey=>'',    # place your runtime apikey here
	ownerCode=>'', # place your ownerCode here
	baseUrl=>'http://api.conductrics.com',
    );

    ... see Conductrics::Agent documentation

=head1 METHODS

=cut

use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Types::Moose qw( Str );
use MooseX::Types::URI qw(Uri);
use URI;
use URI::QueryParam;
use JSON::MaybeXS;
use JSON::Schema;
use Time::HiRes;
use LWP::UserAgent;
use HTTP::Request;

our $VERSION = '0.003';
$VERSION = eval $VERSION;

sub build_uri { 
    my($self)=@_;
    return URI->new($self->baseUrl); 
}

has 'apiKey' => (is=>'ro', isa=>Str, required=>1);
has 'ownerCode' => (is=>'ro', isa=>Str, required=>1);
has 'baseUrl' => (is=>'ro', isa=>Str, required=>1);
has 'baseUri' => (is=>'ro', isa=>Uri, lazy=>1, builder=>'build_uri');

my $ua = LWP::UserAgent->new();
$ua->agent('Perl Conductrics::Agent');
$ua->timeout(2);
$ua->env_proxy;
my $json = JSON::MaybeXS->new;


=head2 create_agent( $agent_name, $content)

=head2 create_agent($agent_name, $hashref_definition)

=head2 create_agent($agent_name, $json_definition)



$content can be a json description of the Agent according the agent json schema.


  create_agent('test-agent', $json);


$json contains json agent description


  create_agent('test-agent', $hashref);


$hashref contains agent descrition as Perl structure that will be encoded to json.

=cut

sub create_agent {
    my ($self, $agent_name, $content) = @_;
    my $uri = $self->baseUri->clone;
    $uri->path_segments($self->ownerCode, $agent_name);
    my %parameters = (apikey=>$self->apiKey);
    for my $k (keys %parameters) {
	$uri->query_param_append($k, $parameters{$k});
    }
    if ('HASH' eq ref $content) {
	$content=JSON::MaybeXS::encode_json($content);
    }
    my $request = HTTP::Request->new("PUT", $uri, undef, $content);
    $request->header(Content_Type => 'application/json');
    #use Data::Dumper;
    #print Dumper($request);
    my $response = $ua->request($request);
    if ($response->is_success) {
	return JSON::MaybeXS::decode_json($response->decoded_content);
    } else {
	warn "Content: ", $response->decoded_content;  # or whatever
	warn "Code: ", $response->code;
	warn "Err:", $response->message;
	die $response->status_line;
    }
}

=head2 define_agent($agent_name, $goals_list, $decisionpoints_list)
=cut

sub define_agent {
    my ($self, $agent_name, $goals, $points)=@_;
    
    return {
	code    => $agent_name,
	owner   => $self->ownerCode,
	created => time,
	
	goals   => $goals,
	points  => $points,
    };
}

=head2 define_goals(@goals)

=head2 define_goals({},{});

you can provide list of names: 
    $client->define_goals('micky mouse','pluto');

or can provide a list of hashref:
    $client->define_goals({name=>'micky mouse'}.{name=>'pluto'});

with codes too:
    $client->define_goals({code=>1, name=>'micky mouse'}.{code=>2, name=>'pluto'});

or calling define_goal()

    $client->define_goals($client->define_goal('micky mouse', 1),
			  $client->define_goal('pluto', 2));

or calling define_goal() with settings

    $client->define_goals($client->define_goal('micky mouse', 1, {min=>1, max=>5, default=>0, limit=>3}),
			  $client->define_goal('pluto', 2, {min=>1, max=>2, default=>1, limit=>5}));

Look for goal's setting in help conductrics manual, for more info and their meanings.

=cut

sub define_goals {
    my ($self, @goal_names)=@_;
    my @goals = ();
    if ('HASH' eq ref $goal_names[0]) {
        return \@goal_names;
    } else {
	return [map {{code=>$_}} @goal_names];
    }
}

=head2 define_goal($name, $code)

=head2 define_goal($name, $code, {min=>1, max=>3, default=>0, limit=>0})

You can define a goals with more details.

=cut

sub define_goal {
    my ($self, $name, $code, $settings)=@_;
    if (defined $settings && 'HASH' eq ref $settings) {
	return {name=>$name, code=>$code, settings=>$settings};
    }
    return {name=>$name, code=>$code};
}

sub define_decision_point {
    my ($self, $point_name, @decisions)=@_;
    my $res = {
	code      => $point_name,
	decisions => \@decisions,
    };
    return $res;
}

sub define_decision {
    my ($self, $decision_name, @choices)=@_;
    return {
	code => $decision_name,
	choices => [map {{code=>$_}} @choices],
    };
}

=head2 delete_agent($agent_name)

=cut

sub delete_agent {
    my ($self, $agent_name) = @_;
    my $uri = $self->baseUri->clone;
    $uri->path_segments($self->ownerCode, $agent_name);
    my %parameters = (apikey=>$self->apiKey);
    for my $k (keys %parameters) {
	$uri->query_param_append($k, $parameters{$k});
    }

    my $request = HTTP::Request->new("DELETE", $uri);
    my $response = $ua->request($request);
    if ($response->is_success) {
	return JSON::MaybeXS::decode_json($response->decoded_content);
    } else {
	warn "Content: ", $response->decoded_content;  # or whatever
	warn "Code: ", $response->code;
	warn "Err:", $response->message;
	die $response->status_line;
    }
}

=head2 get_json_schema

It gets json schema for agent definition.

=cut 

sub get_json_schema {
    my($self, $url) = @_;
    unless (defined $url) {
	$url = 'http://api.conductrics.com/' . $self->ownerCode . '/schema/agent';
    }
    my $response = $ua->get($url);
    if ($response->is_success) {
	return $response->decoded_content;
    } 
    warn "Content: ", $response->decoded_content;  # or whatever
    warn "Code: ", $response->code;
    warn "Err:", $response->message;
    die $response->status_line;
}

=head2 validate_agent

It validates json against json schema.

=cut

sub validate_agent {
    my ($self, $schema, $json) = @_;
    my %options;
    my $validator = JSON::Schema->new($schema, %options);
    my $result    = $validator->validate($json);
 
    if ($result) {
	return $json;
    }
    else
    {
	print "Errors\n";
	print " - $_\n" foreach $result->errors;
    }
}

1;

=head1 TESTS


You have to set some env to execute t/02-define_agent.t
You will find your data into Account/Keys and Users page.

Required env for execute full test's suite:

       Conductrics_apikey
       Conductrics_ownerCode
       Conductrics_Mng_apikey  admin/management apikey

Test's sources are good examples about how to use this API, so "Use The Source Luke".


=head1 MORE INFO

Conductrics has many help pages available from the console, so signup and read it.

http://conductrics.com/

There are also Report API, Management API and Targetting Rule API.


=head1 AUTHORS

 Ferruccio Zamuner - nonsolosoft@diff.org

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
