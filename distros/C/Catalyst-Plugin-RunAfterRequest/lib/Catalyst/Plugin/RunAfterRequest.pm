package Catalyst::Plugin::RunAfterRequest;
BEGIN {
  $Catalyst::Plugin::RunAfterRequest::AUTHORITY = 'cpan:FLORA';
}
BEGIN {
  $Catalyst::Plugin::RunAfterRequest::VERSION = '0.04';
}
# ABSTRACT: run code after the response has been sent.

use Moose::Role;
use MooseX::Types::Moose qw/ArrayRef CodeRef/;

use namespace::autoclean;

has callbacks => (
    traits  => ['Array'],
    isa     => ArrayRef[CodeRef],
    default => sub { [] },
    handles => {
        run_after_request => 'push',
        _callbacks        => 'elements',
    },
);

after finalize => sub {
    my $self = shift;

    for my $callback ($self->_callbacks) {
        $self->$callback;
    }
};


1;

__END__
=pod

=encoding utf-8

=head1 NAME

Catalyst::Plugin::RunAfterRequest - run code after the response has been sent.

=head1 SYNOPSIS

    #### In MyApp.pm
    use Catalyst qw(RunAfterRequest);

    #### In your controller
    sub my_action : Local {
        my ( $self, $c ) = @_;

        # do your normal processing...

        # add code that runs after response has been sent to client
        $c->run_after_request(    #
            sub { $self->do_something_slow(); },
            sub { $self->do_something_else_as_well(); }
        );

        # continue handling the request
    }


    #### Or in your Model:

    package MyApp::Model::Foo;

    use Moose;
    extends 'Catalyst::Model';
    with 'Catalyst::Model::Role::RunAfterRequest';

    sub some_method {
        my $self = shift;

        $self->_run_after_request(
            sub { $self->do_something_slow(); },
            sub { $self->do_something_else_as_well(); }
        );
    }

=head1 DESCRIPTION

Sometimes you want to run something after you've sent the reponse back to the
client. For example you might want to send a tweet to Twitter, or do some
logging, or something that will take a long time and would delay the response.

This module provides a conveniant way to do that by simply calling
C<run_after_request> and adding a closure to it.

=head1 METHODS

=head2 run_after_request

    $c->run_after_request(            # '_run_after_request' in model
        sub {
            # create preview of uploaded file and store to remote server
            # etc, etc
        },
        sub {
            # another closure...
        }
    );

Takes one or more anonymous subs and adds them to a list to be run after the
response has been sent back to the client.

The method name has an underscore at the start in the model to indicate that it
is a private method. Really you should only be calling this method from within
the model and not from other code.

=head1 AUTHORS

=over 4

=item *

Matt S Trout <mst@shadowcat.co.uk>

=item *

Edmund von der Burg <evdb@ecclestoad.co.uk>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Pedro Melo <melo@simplicidade.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Matt S Trout.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

