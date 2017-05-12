package Catalyst::Controller::MessageDriven;
use Moose;
use Data::Serializer;
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw/Str/;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

=head1 NAME

Catalyst::Controller::MessageDriven

=head1 SYNOPSIS

  package MyApp::Controller::Queue;
  use Moose;
  BEGIN { extends 'Catalyst::Controller::MessageDriven' }

  sub some_action : Local {
      my ($self, $c, $message) = @_;

      # Handle message

      # Reply with a minimal response message
      my $response = { type => 'testaction_response' };
      $c->stash->{response} = $response;
  }

=head1 DESCRIPTION

A Catalyst controller base class for use with Catalyst::Engine::Stomp,
which handles YAML-serialized messages. A top-level "type" key in the
YAML determines the action dispatched to.

=head1 METHODS

=head2 begin

Deserializes the request into C<< $c->stash->{request} >>

=head2 default

Dispatches to method named by the key C<< $c->stash->{request}->{type} >>

=head2 end

Serializes the response from C<< $c->stash->{response} >>

=head1 CONFIGURATION

In the configuration file add the following to set the value for a parameter

  <MessageDriven>
    type_key foo
  </MessageDriven>

=head2 type_key

The hash key the module will try to pull out the received message to call
within the controller. This defaults to 'type'.

=head2 serializer

The serializer used to serialiser/deserialise. See Data::Serializer to see
what is available. Defaults to YAML. JSON is anotther that is available.


=cut

class_type 'Data::Serializer';
my $serializer_t = subtype 'Data::Serializer', where { 1 };
coerce $serializer_t, from 'Str',
    via { Data::Serializer->new( serializer => $_ ) };

has serializer => (
    isa => $serializer_t, is => 'ro', required => 1,
    default => 'YAML', coerce => 1,
);

has type_key => (
    is => 'ro', required =>1,
    default => 'type',
);

has trust_jmstype => (
    is => 'ro', required => 1,
    default => 0,
);


sub begin : Private {
    my ($self, $c) = @_;

    # Deserialize the request message
    my $message;
    my $s = $self->serializer;
    eval {
        my $body = $c->request->body;
        open my $IN, "$body" or die "can't open temp file $body";
        my $raw_request = do { local $/; <$IN> };
        $c->stash->{raw_request} = $raw_request;
        $message = $s->raw_deserialize($raw_request);
    };
    if ($@) {
        # can't reply - reply_to is embedded in the message
        $c->error("exception in deserialize: $@");
    }
    else {
        $c->stash->{request} = $message;
    }
}

sub _errors_to_response {
    my ($self, $c) = @_;

    if ( scalar(@{$c->error}) == 1 && ref($c->error->[0]) ) {
        # A single object exists as an error, throw that back as is
        $c->log->error('Exception thrown: ' . $c->error->[0]);
        return $c->error->[0];
    }
    else {
        $c->log->error($_) for @{$c->error}; # Log errors in Catalyst
        my $error = join "\n", @{$c->error}; # Stringyfy them
        return { status => 'ERROR', error => $error};
    }

    return;
}

sub end : Private {
    my ($self, $c) = @_;

    # Engine will send our reply based on the value of this header.
    $c->response->headers->header( 'X-Reply-Address' => $c->stash->{request}->{reply_to} );

    # The wire response
    my $output;

    # Load a serializer
    my $s = $self->serializer;

    # Custom error handler - steal errors from catalyst and dump them into
    # the stash, to get them serialized out as the reply.
    if (scalar @{$c->error}) {
        $c->stash->{response} = $self->_errors_to_response($c);
        $c->clear_errors;
        $c->response->status(400);
    }

    # Serialize the response
    eval {
        $output = $s->raw_serialize( $c->stash->{response} );
    };
    if ($@) {
         my $error = "exception in serialize: $@";
         $c->stash->{response} = { status => 'ERROR', error => $error };
         $output = $s->serialize( $c->stash->{response} );
        $c->response->status(400);
    }

    $c->response->output( $output );

}

sub default : Private {
    my ($self, $c) = @_;

    # Forward the request to the appropriate action, based on the
    # message type.
    my $action;
    if ( !defined $self->type_key
             or $self->trust_jmstype ) {
        $action = $c->request->headers->header('JMSType')
               || $c->request->headers->header('type');
    }
    else {
        $action = $c->stash->{request}->{ $self->type_key };
    }
    if (defined $action) {
        $c->forward($action, [$c->stash->{request},$c->request->headers]);
    }
    else {
         $c->error('no message type specified');
    }
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR AND CONTRIBUTORS

See information in L<Catalyst::Engine::Stomp>

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2009 Venda Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

