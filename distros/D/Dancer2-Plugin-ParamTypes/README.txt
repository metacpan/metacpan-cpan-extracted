SYNOPSIS
        package MyApp;
        use Dancer2;
        use Dancer2::Plugin::ParamTypes;

        # First we define some type checks
        # Read below for explanation
        register_type_check 'Int' => sub {...};
        register_type_check 'Str' => sub {...};

        get '/:id' => with_types [
            # Required
            [ 'route', 'id',  'Int' ],
            [ 'query', 'num', 'Int' ],

            # Optional, either as query or body
            'optional' => [ [ 'query', 'body' ], 'name', 'Str' ],
        ] => sub {
            my $id  = route_parameters->{'id'};
            my @num = query_parameters->get_all('num');
            ...
        };

        # If we define our own action
        register_type_action 'SpecialError' => sub {...};

        # We can now use it in the type check
        get '/' => with_types [
            [ 'query', 'id', 'Int', 'SpecialError' ]
        ] => sub {
            ...
        };

DESCRIPTION
    This is a simple module that allows you to provide a stanza of parameter
    type checks for your routes.

    It supports all three possible sources: "route", "query", and "body".

    Currently no types are available in the system, so you will need to
    write your own code to add them. See the following methods below.

  Methods
   "register_type_check"
    First you must register a type check, allowing you to test stuff:

        register_type_check 'Int' => sub {
            return Scalar::Util::looks_like_number( $_[0] );
        };

   "register_type_action"
        register_type_action 'MyError' => sub {
            my ( $self, $details ) = @_;

            my $source = $details->{'source'};
            my $name   = $details->{'name'};
            my $type   = $details->{'type'};
            my $action = $details->{'action'};

            send_error("Type check failed for $name ($type)");
        }

   "with_types"
    "with_types" defines checks for parameters for a route request.

        get '/:name' => with_request [

            # Basic usage
            [ SOURCE, NAME, TYPE ]

            # Provide a custom action
            [ SOURCE, NAME, TYPE, ACTION ]

            # Provide multiple sources (either one will work)
            [ [ SOURCE1, SOURCE2 ], NAME, TYPE ],

            # Optional type check
            # (if available will be checked, otherwise ignored)
            'optional' => [ SOURCE, NAME, TYPE ]

        ] => sub {
            ...
        };

    Above are all the options, but they will also work in any other
    combination.

  Connecting existing type systems
    Because each type check is a callback, you can connect these to other
    type systems:

        register_type_check 'Str' => sub {
            require MooX::Types::MooseLike::Base;

            # This call will die when failing,
            # so we put it in an eval
            eval {
                MooX::Types::MooseLike::Base::Str->( $_[0] );
                1;
            } or return;

            return 1;
        };

  Creating your own pre-defined type checks
    The following is a simple example of introducing a subclass of this
    plugin in order to create your own version with pre-defined checks.

        package Dancer2::Plugin::MyParamTypes;
        use strict;
        use warnings;
        use Dancer2::Plugin;

        # subclass
        extends('Dancer2::Plugin::ParamTypes');

        # define our own plugin keyword
        plugin_keywords('with_types');

        # which simply calls the parent
        sub with_types {
            my $self = shift;
            return $self->SUPER::with_types(@_);
        }

        sub BUILD {
            my $self = shift;

            # register our own type checks
            $self->register_type_check(
                'Int' => sub { Scalar::Util::looks_like_number( $_[0] ) },
            );
        }

    Later, the application can simply use this module:

        package MyApp;
        use Dancer2;
        use Dancer2::Plugin::MyParamTypes;

        get '/' => with_types [
            [ 'query', 'id', 'Int' ],
        ] => sub {...};

