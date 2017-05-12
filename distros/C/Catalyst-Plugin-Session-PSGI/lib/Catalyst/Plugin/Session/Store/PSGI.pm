package Catalyst::Plugin::Session::Store::PSGI;
{
  $Catalyst::Plugin::Session::Store::PSGI::VERSION = '0.0.2';
}
{
  $Catalyst::Plugin::Session::Store::PSGI::DIST = 'Catalyst-Plugin-Session-PSGI';
}
use strict;
use warnings;

use Catalyst::Plugin::Session::PSGI;


use base qw/Catalyst::Plugin::Session::Store/;




sub get_session_data {
    my ($c, $id) = @_;

    # grab the PSGI environment
    my $psgi_env = Catalyst::Plugin::Session::PSGI::_psgi_env($c);
    return
        unless defined $psgi_env;

    # TODO: work out correct place to initialise this
    $psgi_env->{'psgix.session.expires'}
        ||= $c->get_session_expires;

    # grab the relevant data from the PSGI environment
    my $data = $psgi_env->{_psgi_section($id)};
    return $data if $data;

    # no session retrieved - hope this isn't too painful
    return;
}

sub store_session_data {
    my ($c, $id, $data) = @_;

    # grab the PSGI environment
    my $psgi_env = Catalyst::Plugin::Session::PSGI::_psgi_env($c);
    return
        unless defined $psgi_env;

    # grab the relevant data from the PSGI environment
    $psgi_env->{_psgi_section($id)} = $data;
}

sub delete_session_data     { } # unsupported

sub delete_expired_sessions { } # unsupported

sub _psgi_section {
    my $id = shift;

    # default to using 'psgi.session'
    my $psgi_section = 'psgix.session';
    # add supposert for things like expire: and flash:
    if (my ($section, $sid) = ($id =~ m{\A(\w+):(\w+)\z})) {
        if ('session' ne $section) {
            $psgi_section .= ".${section}";
        }
    }

    return $psgi_section;
}

1;
# ABSTRACT: Session plugin for access to PSGI/Plack session

=pod

=head1 NAME

Catalyst::Plugin::Session::Store::PSGI - Session plugin for access to PSGI/Plack session

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use Catalyst qw/
        Session
        Session::State::PSGI
        Session::Store::PSGI
    /;

=head1 DESCRIPTION

An alternative session storage plugin that allows sharing of the PSGI/Plack session information.

=head1 EXPERIMENTAL

This distribution should be considered B<experimental>. Although functional, it
may break in currently undiscovered use cases.

=head1 METHODS

The plugin provides the following methods:

=head2 get_session_data

=head2 store_session_data

=head2 delete_session_data

This method is NOOP - session data should be deleted by L<Plack::Middleware::Session>

=head2 delete_expired_sessions

This method is NOOP - sessions should be expired by L<Plack::Middleware::Session>

=head1 AUTHOR

Chisel <chisel@chizography.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Chisel Wright.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__
# vim: ts=8 sts=4 et sw=4 sr sta
