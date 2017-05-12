package Catalyst::Plugin::RedirectAndDetach;

use strict;
use warnings;

our $VERSION = '0.03';

use Params::Validate qw( validate_pos SCALAR OBJECT );


{
    my @spec = ( { type => SCALAR | OBJECT },
                 { type => SCALAR, default => undef } );

    sub redirect_and_detach
    {
        my $self   = shift;
        my ( $uri, $status ) = validate_pos( @_, @spec );

        $self->response()->redirect( $uri, $status );

        $self->detach();
    }
}

1;

__END__

=pod

=head1 NAME

Catalyst::Plugin::RedirectAndDetach - Redirect and detach at the same time

=head1 SYNOPSIS

    # load the plugin

    use Catalyst qw( RedirectAndDetach );

    # in your controller ...

    sub admin
    {
        my $self = shift;
        my $c    = shift;

        $c->redirect_and_detach('/')
            unless $c->stash()->{user}->is_admin();

        ...
    }

=head1 DESCRIPTION

I generally find that if I want to issue a redirect in my web app, I
want to stop processing right there. This plugin adds a ridiculously
simply method to your Catalyst objects to do just that.

The reason to use C<detach()> instead of simply returning from the
current sub is that C<detach()> throws an exception that effectively
aborts all execution, rather than simply exiting the current method.

=head1 METHODS

This class provides one method:

=head2 $c->redirect_and_detach( $uri, $status )

The C<$uri> parameter is required, and C<$status> is
optional. Internally, this just calls C<redirect()> on the Response
object, followed by C<detach()>.

=head1 AUTHOR

Dave Rolsky, C<< <autarch@urth.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-redirectanddetach@rt.cpan.org>, or through the
web interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
