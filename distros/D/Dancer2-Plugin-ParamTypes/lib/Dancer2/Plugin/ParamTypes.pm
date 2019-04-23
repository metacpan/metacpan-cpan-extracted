package Dancer2::Plugin::ParamTypes;
# ABSTRACT: Parameter type checking plugin for Dancer2
$Dancer2::Plugin::ParamTypes::VERSION = '0.006';
use strict;
use warnings;
use constant {
    'ARGS_NUM_BASIC'    => 3,
    'ARGS_NUM_OPTIONAL' => 4,
    'HTTP_BAD_REQUEST'  => 400,
};

use Carp ();
use Dancer2::Plugin;
use Scalar::Util ();
use Ref::Util qw< is_ref is_arrayref >;

plugin_keywords(qw<register_type_check register_type_action with_types>);

has 'type_checks' => (
    'is'      => 'ro',
    'default' => sub { +{} },
);

has 'type_actions' => (
    'is'      => 'ro',
    'builder' => '_build_type_actions',
);

sub _build_type_actions {
    my $self = shift;
    Scalar::Util::weaken( my $plugin = $self );
    return {
        'error' => sub {
            my ( $self, $details ) = @_;
            my ( $type, $name )    = @{$details}{qw<type name>};

            $plugin->dsl->send_error(
                "Parameter $name must be $type",
                HTTP_BAD_REQUEST(),
            );
        },

        'missing' => sub {
            my ( $self, $details ) = @_;
            my ( $name, $type )    = @{$details}{qw<name type>};

            $self->dsl->send_error(
                "Missing parameter: $name ($type)",
                HTTP_BAD_REQUEST(),
            );
        },
    };
}

sub register_type_check {
    my ( $self, $name, $cb ) = @_;
    $self->type_checks->{$name} = $cb;
    return;
}

sub register_type_action {
    my ( $self, $name, $cb ) = @_;
    $self->type_actions->{$name} = $cb;
    return;
}

sub with_types {
    my ( $self, $full_type_details, $cb ) = @_;
    my %params_to_check;

    is_arrayref($full_type_details)
        or Carp::croak('Input for with_types must be arrayref');

    ## no critic qw(ControlStructures::ProhibitCStyleForLoops)
    for ( my $idx = 0; $idx <= $#{$full_type_details}; $idx++ ) {
        my $item = $full_type_details->[$idx];
        my ( $is_optional, $type_details )
            = is_arrayref($item)   ? ( 0, $item )
            : $item eq 'optional'  ? ( 1, $full_type_details->[ ++$idx ] )
            : Carp::croak("Unsupported type option: $item");

        my ( $sources, $name, $type, $action ) = @{$type_details};

        @{$type_details} == ARGS_NUM_BASIC() ||
        @{$type_details} == ARGS_NUM_OPTIONAL()
            or Carp::croak("Incorrect number of elements for type ($name)");

        # default action
        defined $action && length $action
            or $action = 'error';

        if ( is_ref($sources) ) {
            is_arrayref($sources)
                or Carp::croak("Source cannot be of @{[ ref $sources ]}");

            @{$sources} > 0
                or Carp::croak('You must provide at least one source');
        } else {
            $sources = [$sources];
        }

        foreach my $src ( @{$sources} ) {
            $src eq 'route' || $src eq 'query' || $src eq 'body'
                or Carp::croak("Type $name provided from unknown source '$src'");
        }

        defined $self->type_checks->{$type}
            or Carp::croak("Type $name provided unknown type '$type'");

        defined $self->type_actions->{$action}
            or
            Carp::croak("Type $name provided unknown action '$action'");

        defined $self->type_actions->{'missing'}
            or Carp::croak('You need to provide a "missing" action');

        my $src = join ':', sort @{$sources};
        $params_to_check{$src}{$name} = {
            'optional' => $is_optional,
            'source'   => $src,
            'name'     => $name,
            'type'     => $type,
            'action'   => $action,
        };
    }

    # Couldn't prove yet that this is required, but it makes sense to me
    Scalar::Util::weaken( my $plugin = $self );

    return sub {
        my @route_args = @_;

        # Hash::MultiValue has "each" method which we could use to
        # traverse it in the opposite direction (for each parameter sent
        # we find the appropriate value and check it), but that could
        # possibly introduce an attack vector of sending a lot of
        # parameters to force longer loops. For now, the loop is based
        # on how many parameters to added to be checked, which is a known
        # set. (GET has a max limit, PUT/POST...?) -- SX

        # Only check if anything was supplied
        foreach my $source ( keys %params_to_check ) {
            foreach my $name ( keys %{ $params_to_check{$source} } ) {
                my @sources = split /:/xms, $source;
                my $details = $params_to_check{$source}{$name};

                if ( @sources == 1 ) {
                    $plugin->run_check($details)
                        or
                        $self->type_actions->{'missing'}->( $self, $details );
                } else {
                    my $found;
                    foreach my $single_source (@sources) {
                        $details->{'source'} = $single_source;
                        if ( $plugin->run_check($details) ) {
                            $found++;
                            last;
                        }
                    }

                    $found
                        or
                        $self->type_actions->{'missing'}->( $self, $details );
                }
            }
        }

        $cb->(@route_args);
    };
}

sub run_check {
    my ( $self, $details ) = @_;

    my ( $source, $name, $type, $action, $optional )
        = @{$details}{qw<source name type action optional>};

    my $app     = $self->app;
    my $request = $app->request;

    my $params
        = $source eq 'route' ? $request->route_parameters
        : $source eq 'query' ? $request->query_parameters
        :                      $request->body_parameters;

    # No parameter value, is this okay or not?
    if ( !exists $params->{$name} ) {
        # It's okay, ignore
        $optional
            and return 1;

        # Not okay, missing when it's required!
        return;
    }

    my @param_values = $params->get_all($name);
    my $check_cb     = $self->type_checks->{$type};

    foreach my $param_value (@param_values) {
        if ( ! $check_cb->($param_value) ) {
            my $action_cb
                = $self->type_actions->{$action};

            return $action_cb->( $self, $details );
        }
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Plugin::ParamTypes - Parameter type checking plugin for Dancer2

=head1 VERSION

version 0.006

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This is a simple module that allows you to provide a stanza of parameter
type checks for your routes.

It supports all three possible sources: C<route>, C<query>, and
C<body>.

Currently no types are available in the system, so you will need to
write your own code to add them. See the following methods below.

=head2 Methods

=head3 C<register_type_check>

First you must register a type check, allowing you to test stuff:

    register_type_check 'Int' => sub {
        return Scalar::Util::looks_like_number( $_[0] );
    };

=head3 C<register_type_action>

    register_type_action 'MyError' => sub {
        my ( $self, $details ) = @_;

        my $source = $details->{'source'};
        my $name   = $details->{'name'};
        my $type   = $details->{'type'};
        my $action = $details->{'action'};

        send_error("Type check failed for $name ($type)");
    }

=head3 C<with_types>

C<with_types> defines checks for parameters for a route request.

    get '/:name' => with_types [

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

=head2 Connecting existing type systems

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

=head2 Creating your own pre-defined type checks

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

=head1 AUTHOR

Sawyer X

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Sawyer X.

This is free software, licensed under:

  The MIT (X11) License

=cut
