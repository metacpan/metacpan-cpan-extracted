package Catalyst::Plugin::Session::PSGI;
{
  $Catalyst::Plugin::Session::PSGI::VERSION = '0.0.2';
}
{
  $Catalyst::Plugin::Session::PSGI::DIST = 'Catalyst-Plugin-Session-PSGI';
}
use strict;
use warnings;


sub _psgi_env {
    my ( $c ) = @_;

    return $c->request->can('env') ? $c->request->env : $c->request->{_psgi_env};
}







1;
# ABSTRACT: minimal configuration access to PSGI/Plack session (EXPERIMENTAL)

=pod

=head1 NAME

Catalyst::Plugin::Session::PSGI - minimal configuration access to PSGI/Plack session (EXPERIMENTAL)

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

When running under PSG/Plack with Session middeware enabled you can use the
PSGI session as follows:

    use Catalyst qw/
        Session
        Session::State::PSGI
        Session::Store::PSGI
    /;

=head2 _psgi_env

Fetches the psgi env globally from the request env

=head1 EXPERIMENTAL

This distribution should be considered B<experimental>. Although functional, it
may break in currently undiscovered use cases.

=head1 SUMMARY

If you are running your L<Catalyst> application in a Plack/PSGI environment and
using L<Plack::Middleware::Session> you might want to consider using the
session information in the PSGI environment.

The L<Catalyst::Plugin::Session::State::PSGI> and
L<Catalyst::Plugin::Session::Store::PSGI> modules access the
I<psgix.session.options> and I<psgix.session> data to provide the Catalyst
session.

=head1 AREAS OF CONCERN

As this is an early, experimental release I thought it only fair to share the
glaring areas of concern:

=over 4

=item session expiry

I currently believe that it should be the responsibility of the L<Plack>
middleware to expire and clear session data. As far as possible this
functionality is unimplemented and unsupported in this distribution.

=item session expiry value initialisation

There was a problem with the session expiry value being unset in the Catalyst
related code. This led to sessions always being deleted/expired and never
working properly.

There are a couple of dubious areas to resolve this.

    sub get_session_data {
        # ...

        # TODO: work out correct place to initialise this
        $psgi_env->{'psgix.session.expires'}
            ||= $c->get_session_expires;

        # ...
    }

is almost certainly the wrong time and place to be initialising this value, but
it works and I'm open to clue-sticks and patches.

    sub get_session_expires {
        my $c = shift;
        my $expires = $c->_session_plugin_config->{expires} || 0;
        return time() + $expires;
    }

worries me because I have no idea where the value for
C<< $c->_session_plugin_config->{expires} >> is being initialised. I'm concerned
that this may become C<0> when you least expect it and start expiring all
sessions.

=item (lack of) test coverage

Other than basic sanity tests provided by L<Dist::Zilla> this distribution B<has no tests>!

I haven't found the time to mock up a plack-catalyst test suite to ensure the
session is doing the right thing. Once again I'm open to clue-sticks and
patches.

=back

=head1 SEE ALSO

L<Catalyst>,
L<Catalyst::Plugin::Session>,
L<Plack::Middleware::Session>,
L<Catalyst::Plugin::Session::State::PSGI>,
L<Catalyst::Plugin::Session::Store::PSGI>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# vim: ts=8 sts=4 et sw=4 sr sta
