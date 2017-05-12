package Catalyst::ControllerRole::CatchErrors;
$Catalyst::ControllerRole::CatchErrors::VERSION = '0.05';
use Moose::Role;

requires qw/ catch_errors end /;

# ABSTRACT: custom error handling in your controller.


before 'end' => sub {
    my ( $self, $c ) = @_;
    if ( scalar @{ $c->error } ) {
        my @errors = @{ $c->error };
        $c->clear_errors;
        $c->forward( $self->action_for('catch_errors'), \@errors );
    }
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::ControllerRole::CatchErrors - custom error handling in your controller.

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package MyApp::Controller::Root;
    use Moose;
    BEGIN { extends 'Catalyst::Controller' }
    with 'Catalyst::ControllerRole::CatchErrors';

    sub catch_errors : Private {
        my ($self, $c, @errors) = @_;
        # stuff
    }

=head1 DESCRIPTION

If an action throws an error the default behaviour of L<Catalyst|Catalyst::Runtime>
is to render a default error page and set the response code to 500.
One usecase where this is problematic is if you have a REST Controller using
L<Catalyst::Action::REST>. C<Catalyst::ControllerRole::CatchErrors> requires
a C<catch_errors> action that receives an array of all errors that occurred
during the request.

You can rethrow the error in C<catch_errors>. C<Catalyst::ControllerRole::CatchErrors> passes a copy of the errors
to your method and clears the original ones before calling C<catch_errors>.

=head2 HTTP::Exception errors

By default, C<Catalyst> does not catch errors confirming to the interface described by
L<Plack::Middleware::HTTPExceptions> and lets the middleware deal with it.
You can enable the C<always_catch_http_exceptions> in your C<Catalyst> configuration to
let C<Catalyst::ControllerRole::CatchErrors> catch these errors as well.

=head1 AUTHOR

David Schmidt <davewood@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
