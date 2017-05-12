# NAME

Conductrics Agent

# DESCRIPTION

With the first release I've got php agent API from conductrics github (https://github.com/conductrics/conductrics-php) 
and I've rewritten it in Modern Perl, then I've improved it.

I've substituted rand() calls with less cpu expensive Time::Hires to unvalidate cache.

The release 0.04 has a Conductrics::Client object that cache authentication data and
now you can define and create agents using Admin API interface.



I'll use this module for a new Catalyst model.

# SYNOPSIS

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

# METHODS

## decide()

Whenever in your code you want to act using decision evaluated by Conductrics you just call decide in
a proper form, simple, multiple with names or nameless.

## decide($sessionId, @choices)

Conductrics will compute the decision and this returns which $choice.

## decide($sessionId, {decisionN1=>\[ qw/option1 option2 option3/ \]}, {decisionN2=>\[ qw/anotherOpt oneMoreOpt / \]})

## decide($sessionId, \[ qw/option1 option2 option3/ \], \[ qw/anotherOpt oneMoreOpt / \] )

decisionN1 is only a placeholder for name you have choose for this decision point as well as decisionN2 is another name you like.

Here is how to use Multi-Faceted Decisions, with or without name: you are asking at the server more than one 
Here some words from the conductrics help: 
"Whenver you ask us for a decision, we'll pick one option from each list, and send them back to you in one answer."
"We're basically doing multivariate testing ("MVT") for you, tracking the success of combinations of options rather than each option individually."

## get\_decision($session, $pointCode)

If you have defined more decision points for your agent, you can get decisions from Conductrics using 'point code'.
While decide() needs more information, with this call you have already provided those information to the server
during agent's definition.

To define agents see Conductrics::API::Client.

## reward($sessionId, $goalCode, \[$value\])

Conductrics will collect the numeric value about the goalCode. This is the way it learn whick decisions are winning.

## expire($sessionId)

You are notifing that this session has been closed, for example on user logout action.

http://www.conductrics.com/ for more info about their analysis service.

# TESTS

## Execute full test suite

First you have to create a free and try Conductrics.com account then you have to set some ENV variables
required during the 'make test':

export Conductrics_ownerCode='youraccount_ownercode'
export Conductrics_apikey='youraccount_apikey'
export Conductrics_Mng_apikey='youraccount_admin_apikey'

Conductrics::Client will create test agents for you, it's required by Conductrics::Agent tests.

two test agents following these description:

{
  "code": "test-agent",
  "owner": "$your\_ownerCode",

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
  "owner": "$your\_ownerCode",

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

You have to set some env to execute t/02-real\_test.t
You will find your data into Account/Keys and Users page.

Required env for execute full test's suite:

       Conductrics_apikey
       Conductrics_ownerCode
       Conductrics_agent_name=test-agent
       Conductrics_mvt_agent_name=mvt-agent

Test's sources are good examples about how to use this API, so "Use The Source Luke".

# MORE INFO

Conductrics has many help pages available from the console, so signup and read it.

http://conductrics.com/

There are also Report API, Management API and Targetting Rule API.

## ToDo

I wuold like to return promises for handling non blocking request to conductrics server.

# AUTHORS

    Ferruccio Zamuner - nonsolosoft@diff.org

# COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

