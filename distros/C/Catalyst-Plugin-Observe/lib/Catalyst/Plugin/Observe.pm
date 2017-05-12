package Catalyst::Plugin::Observe;

use strict;
use base 'Class::Publisher';

our $VERSION='0.02';

{
    my @observable = qw[
        dispatch
        finalize
        finalize_body
        finalize_cookies
        finalize_error
        finalize_headers
        forward
        prepare
        prepare_action
        prepare_body
        prepare_connection
        prepare_cookies
        prepare_headers
        prepare_parameters
        prepare_path
        prepare_request
        prepare_uploads
    ];

    no strict 'refs';

    for my $observe ( @observable ) {

        eval sprintf( <<'', ($observe) x 3 );
        sub %s {
            my $c = shift;
            $c->notify_subscribers( %s, @_ );
            return $c->NEXT::%s(@_);
        }

    }
}

1;

__END__

=head1 NAME

Catalyst::Plugin::Observe - Observe Engine Events

=head1 SYNOPSIS

    use Catalyst qw[Observe];

    # register the observer method as a callback to prepare_path
    MyApp->add_subscriber( 'prepare_path', \&observer );

    # write callback to describe what happened
    sub observer {
        my ( $c, $event, @args ) = @_;
        $c->log->info( "observed " . $event . " with arguments " . join( '\n', @args ) );
    }


=head1 DESCRIPTION

Observe Engine events, for debugging purposes. Subclasses
L<Class::Publisher>.

C<Catalyst::Plugin::Observe> allows you to register your own callbacks
to specific Engine events (method calls), and to be notified through the
callback when they occur. When the Engine calls the event, your callback
will be called with the same arguments, which you can then display (etc.)
as necessary.

=head1 CALLBACK VARIABLES

=over 4

=item C<$event>

The Engine event to which the callback is registered. See L</OBSERVABLE EVENTS> below.

=item C<@args>

The arguments passed to the Engine event.

=back

=head1 OBSERVABLE EVENTS

=over 4

=item dispatch

=item finalize

=item finalize_body

=item finalize_cookies

=item finalize_error

=item finalize_headers

=item forward

=item prepare

=item prepare_action

=item prepare_body

=item prepare_connection

=item prepare_cookies

=item prepare_headers

=item prepare_parameters

=item prepare_path

=item prepare_request

=item prepare_uploads

=back

=head1 SEE ALSO

L<Class::Publisher>, L<Catalyst::Dispatch>, L<Catalyst::Engine>.

=head1 AUTHOR

Christian Hansen, C<ch@ngmedia.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.

=cut
