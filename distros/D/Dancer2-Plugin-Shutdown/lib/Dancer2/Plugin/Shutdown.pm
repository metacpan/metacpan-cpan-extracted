use strictures 2;

package Dancer2::Plugin::Shutdown;

# ABSTRACT: Graceful shutdown your Dancer2 application

use Dancer2::Plugin;

with 'Dancer2::Plugin::Role::Shutdown';

our $VERSION = '0.002'; # VERSION

on_plugin_import {
    my $self = shift;
    $self->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub { $self->before_hook(@_) },
        )
    );
};


register shutdown_at => \&_shutdown_at;


register shutdown_session_validator => sub {
    shift->validator(@_)
}, { is_global => 1 };

register_plugin;

1;

__END__

=pod

=head1 NAME

Dancer2::Plugin::Shutdown - Graceful shutdown your Dancer2 application

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Shutdown;

    $SIG{HUP} = sub {
        # on hangup, shutdown in 120 seconds
        shutdown_at(120);
    };

=head1 DESCRIPTION

This plugin gracefully shutdowns your application. This is done by returning a 503 error on every request after L</shutdown_at> is called.

An additional check allows active sessions to proceed normally, but the session cookie expires as soon as possible.

The behaviour can be changed with L<shutdown_session_validator>, the default behaviour is similiar to:

    shutdown_session_validator(sub {
        my ($app, $rest, $sessid) = @_;
        # $sessid is session->id
        # or undef if no active session is detected
        return 0 unless $sessid;
        # $rest is the remaining time in seconds
        # till planned shutdown
        $app->session->expires($rest);
        # let valid sessions survive until shutdown
        return 1;
    });

Additionally a I<Warning> header is added with code I<199> and a message similiar to: I<Application shuts down in 106 seconds>.

Hint: The expiration of the session cookie will not extended.

=head1 FUNCTIONS

=head2 shutdown_at

B<Invokation:> C<shutdown_at( $time )>

C<$time> may be an absolute or a relative timestamp. A relative timestamp is indicated by an integer less than the current timestamp, so:

    shutdown_at(120);

is the same as:

    shutdown_at(time+120);

=head2 shutdown_session_validator

B<Invokation:> C<shutdown_session_validator( sub { ... } )>

Changes the session validator subroutine. The sub will be called before every request with this arguments:

=over 4

=item * C<$app>

An instance of L<Dancer2::Core::App>

=item * C<$rest>

The remaining time in seconds till application shutdown

=item * C<$session>

The session id, but only when a valid and active sesion is detected. Otherwise undefined.

=back

=head1 PROPAGATION

This plugin works only in single-instance environments. With L<Starman> or L<Corona>, the propagation can be done via L<Redis>. There is a plugin that fits this need: L<Dancer2::Plugin::Shutdown::Redis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer2-plugin-shutdown-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
