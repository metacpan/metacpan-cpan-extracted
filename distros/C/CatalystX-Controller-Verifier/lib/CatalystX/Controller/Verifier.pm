package CatalystX::Controller::Verifier;
BEGIN {
  $CatalystX::Controller::Verifier::VERSION = '0.02';
}

use strict;
use warnings;

use Moose::Role;

use Carp;
use Scalar::Util qw/blessed refaddr/;

use Data::Manager;
use Data::Verifier;
use Message::Stack;

# ABSTRACT: Moose Role for verifying request parameters on a per action basis.



has 'verifiers' => (
    is => 'rw',
    isa => 'HashRef'
);

has '_verifier_stash_key' => (
    is      => 'ro',
    isa     => 'Str',
    default => '_verifier_stash'
);


has 'detach_on_failure' => (
    is  => 'rw',
    isa => 'Str',
    clearer   => 'clear_detach_on_failure',
    predicate => 'has_detach_on_failure',
);


sub verify {
    my ( $self, $c, $params ) = @_;
    $params = $c->req->params if not defined $params or ref $params ne 'HASH';

    my $dm      = $self->data_manager($c);
    my $results = $dm->verify($c->action->name, $params);

    if ( not $results->success and $self->has_detach_on_failure ) {
        my $detach = $c->controller->action_for( $self->detach_on_failure );
        if ( not $detach ) {
            croak "Invalid detach action specified, " . $c->controller . " does not have an action '" . $self->detach_on_failure . "'.";
        }
        $c->detach($detach, [ $results ]);
    }

    return $results;
}


sub messages {
    my ( $self, $c ) = @_;
    my $dm = $self->data_manager($c);

    my $scope = undef; # Not sure of syntax here.
    if ( defined $scope and blessed $scope ) {
        if ( $scope->isa('Catalyst') ) {
            $scope = $scope->action->name;
        }
        elsif ( $scope->isa('Catalyst::Action') ) {
            $scope = $scope->name;
        }
    }
    return $scope ? $dm->messages_for_scope($scope) : $dm->messages;
}


sub data_manager {
    my ( $self, $c ) = @_;

    # Should always be blessed, but you never know.
    my $key = blessed $self ? refaddr $self : $self;
    my $dm  = $c->stash->{ $self->_verifier_stash_key }->{ $key };
    if ( not $dm ) {
        $dm = $self->_build_data_manager;
        $c->stash->{ $self->_verifier_stash_key }->{ $key } = $dm;
    }
    return $dm;
}

sub _build_data_manager {
    my ( $self ) = @_;

    my $verifiers = $self->verifiers;
    my %profiles  = ();

    foreach my $scope ( keys %$verifiers ) {
        my $profile = $verifiers->{$scope};
        if ( not ref $profile ) {
            $profile = $verifiers->{$profile};
        }
        if ( not defined $profile or ref $profile ne 'HASH' ) {
            croak "Invalid profile specified: $profile is invalid";
        }
        $profiles{$scope} = Data::Verifier->new( $profile );
    }

    return Data::Manager->new( verifiers => \%profiles );
}

no Moose::Role;
1;

__END__
=pod

=head1 NAME

CatalystX::Controller::Verifier - Moose Role for verifying request parameters on a per action basis.

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    package MyApp::Controller::Foo;

    use Moose;
    BEGIN { extends 'Catalyst::Controller'; }

    with 'CatalystX::Controller::Verifier';

    __PACKAGE__->config(
        'verifiers' => {
            # The action name
            'search' => {
                # Everything here gets passed to Data::Verifier->new for the scope
                filters => [ 'trim' ],
                # Just a plain Data::Verifier profile here:
                profile => {
                    page => {
                        type => 'Int',
                        post_check => sub { shift->get_value('page') > 0 }
                    },
                    query => {
                        type     => 'Str',
                        required => 1,
                    }
                }
            },
        },
        # Additional options can be passed in:
    
        # If verification fails, detach to the 'bad_args' action
        'detach_on_failure' => 'bad_args',
        
        # If you want to override where the Data::Manager objects get tucked away:
            '_verifier_stash_key' => 'a secret garden',
    );
    
    sub search : Local {
        my ( $self, $c ) = @_;
        my $results = $self->verify( $c );
     
        $c->model('Search')->search(
            # If invalid, it will be undef here.
            $results->get_value('page') || 1,
            $results->get_value('query')
        );
    }

If you run C<verify> in an action that does not have a profile, this will
throw an exception informing you of your transgressions.

But wait, there's more! Data::Verifier allows you to also define coercions.

=head1 ATTRIBUTES

=head2 verifiers

This stores the verifier configuration, which should be a hash ref of action
names to verification profiles.

=head2 detach_on_failure

This attribute is used to instruct the verify method to detach to the action
specified. If this is unset, no detaching happens.

=head1 METHODS

=head2 verify

    $self->verify($c);

The heart of the action, the verify method takes the current context object
and verifies based on the profiles supplied in the configuration. If the
L<detach_on_failure> attribute is set, it will detach on an unsuccessful
verification.

Returns a L<Data::Verifier::Results> object.  Note that this can be serialized
and tucked away in the flash for later use.

=head2 messages

    $self->messages($c);

Returns a L<Message::Stack> for the action in question (after verification).

=head2 data_manager

    $self->data_manager($c);

Returns a L<Data::Manager> object that is used for this request (specific to
the controller and the request).

=head1 COERCE YOUR PARAMETERS

So, in the above example lets say you wanted to parse your search query using
L<Search::Query>. Piece of cake!

    use Search::Query;
    
    __PACKAGE__->config(
        'verifiers' => {
            # The action name
            'search' => {
                # ... include the rest from synopsis ...
                query => {
                    type     => 'Search::Query',
                    required => 1,
                    coercion => Data::Verifier::coercion(
                        from => 'Str',
                        via  => sub { Search::Query->parser->parse($_) }
                    )
                }
            },
        }
    );
    
    sub search : Local {
        my ( $self, $c ) = @_;

        my $results = $self->verify( $c );
     
        $results->get_value('query');          # isa Search::Query object now!
        $results->get_original_value('query'); # Still valid
    }

=head1 MESSAGES

Got a validation error? Well, L<Data::Manager> covers that, too.

The messages method will return a L<Message::Stack> specific to that action.

    sub search : Local {
        my ( $self, $c ) = @_;
    
        my $results = $self->verify($c);
        unless ( $results->success ) {
            # Returns a Message::Stack for the action in question
            $self->messages($c);
        
            # You can also get the Data::Manager object 
            $self->data_manager($c);

        }
    }

=head1 LIFECYCLE

Each controller gets its own Data::Manager per request. This is probably not
blindly fast. It lives in the stash

=head1 AUTHOR

J. Shirley <jshirley@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

