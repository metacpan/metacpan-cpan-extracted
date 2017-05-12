# NAME

Conductrics Client

# DESCRIPTION

This class give access to Conductrics Management API to:

    - define
    - create 
    - delete

agents.

At start, I've written this class to automate tests of Conductrics::Agent, and user has not to learn how to create agent in Conductrics console.

Now you can use it to automate and build a powerfull system in programmatic way.


# SYNOPSIS

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
        ... # success create on conductrics server
    }

    my $agent = Conductrics::Agent->new(
        name=>'main_site',
        apiKey=>'',    # place your apikey here
        ownerCode=>'', # place your ownerCode here
        baseUrl=>'http://api.conductrics.com',
    );

    ... see Conductrics::Agent 

# METHODS

## create\_agent( $agent\_name, $content)

## create\_agent($agent\_name, $hashref\_definition)

## create\_agent($agent\_name, $json\_definition)

$content can be a json description of the Agent according the agent json schema.

    create_agent('test-agent', $json);

$json contains json agent description

    create_agent('test-agent', $hashref);

$hashref contains agent descrition as Perl structure that will be encoded to json.

## define\_goals(@goals)

## define\_goals({},{});

you can provide list of names: 
    $client->define\_goals('micky mouse','pluto');

or can provide a list of hashref:
    $client->define\_goals({name=>'micky mouse'}.{name=>'pluto'});

with codes too:
    $client->define\_goals({code=>1, name=>'micky mouse'}.{code=>2, name=>'pluto'});

or calling define\_goal()

    $client->define_goals($client->define_goal('micky mouse', 1),
                          $client->define_goal('pluto', 2));

or calling define\_goal() with settings

    $client->define_goals($client->define_goal('micky mouse', 1, {min=>1, max=>5, default=>0, limit=>3}),
                          $client->define_goal('pluto', 2, {min=>1, max=>2, default=>1, limit=>5}));

Look for goal's setting in help conductrics manual, for more info and their meanings.

## define\_goal($name, $code)

## define\_goal($name, $code, {min=>1, max=>3, default=>0, limit=>0})

You can define a goals with more details.

## delete\_agent($agent\_name)

## get\_json\_schema

It gets json schema for agent definition.

## validate\_agent

It validates json against json schema.

# TESTS

You have to set some env to execute t/02-real\_test.t
You will find your data into Account/Keys and Users page.

Required env for execute full test's suite:

       Conductrics_apikey
       Conductrics_ownerCode
       Conductrics_Mng_apikey  (admin/management apikey)

Test's sources are good examples about how to use this API, so "Use The Source Luke".

# MORE INFO

Conductrics has many help pages available from the console, so signup and read it.

http://conductrics.com/

There are also Report API, Management API and Targetting Rule API.

# AUTHORS

    Ferruccio Zamuner - nonsolosoft@diff.org

# COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.
