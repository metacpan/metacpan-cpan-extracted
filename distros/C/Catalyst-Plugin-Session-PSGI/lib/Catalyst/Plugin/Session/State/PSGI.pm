package Catalyst::Plugin::Session::State::PSGI;
{
  $Catalyst::Plugin::Session::State::PSGI::VERSION = '0.0.2';
}
{
  $Catalyst::Plugin::Session::State::PSGI::DIST = 'Catalyst-Plugin-Session-PSGI';
}
use strict;
use warnings;

use Catalyst::Plugin::Session::PSGI;


use base qw/Catalyst::Plugin::Session::State/;






sub prepare_action {
    my $c = shift;
    # we don't actually need to do anything here
    $c->maybe::next::method( @_ );
}

sub get_session_id {
    my $c = shift;
    my $psgi_env = Catalyst::Plugin::Session::PSGI::_psgi_env($c);

    return
        unless defined $psgi_env;

    my $sid = $psgi_env->{'psgix.session.options'}{id};
    return $sid if $sid;

    $c->maybe::next::method( @_ );
}

sub get_session_expires {
    my $c = shift;
    my $expires = $c->_session_plugin_config->{expires} || 0;
    return time() + $expires;
}

sub set_session_id      { } # unsupported

sub set_session_expires { } # unsupported

sub delete_session_id   { } # unsupported

__END__

=pod

=head1 NAME

Catalyst::Plugin::Session::State::PSGI

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::State::PSGI
        Session::Store::PSGI
    /;

=head1 DESCRIPTION

An alternative session state plugin that allows session-id retrieval from the
PSGI/Plack session information.

=head1 EXPERIMENTAL

This distribution should be considered B<experimental>. Although functional, it
may break in currently undiscovered use cases.

=head1 METHODS

The plugin provides the following methods:

=head2 prepare_action

This method may not be required. It's almost a NOOP and may be removed in a
future release.

=head2 get_session_id

This method retrieves the session-id from the PSGI/Plack environment information.

=head2

This methis returns the time, in epoch seconds, when the session expires.

B<NOTE>: This is a small hack that just returns a time far enough into the
future for the session not to expire every time you attempt to access it.
Actual expiry should be handled by L<Plack::Middleware::Session>.

=head2 set_session_id

NOOP - unsupported

=head2 set_session_expires

NOOP - unsupported

=head2 delete_session_id

NOOP - unsupported

=head1 SEE ALSO

L<Catalyst::Plugin::Session::PSGI>,

1;
# ABSTRACT: Session plugin for access to PSGI/Plack session
__END__
# vim: ts=8 sts=4 et sw=4 sr sta

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
