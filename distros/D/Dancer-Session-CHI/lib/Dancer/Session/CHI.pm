package Dancer::Session::CHI;

use strict;
use warnings;
use utf8;
use CHI;
use Dancer ":syntax";
use Dancer::Logger;
use Dancer::ModuleLoader;
use Dancer::Exception qw(raise);
use File::Spec::Functions qw(rel2abs);
use Scalar::Util qw(blessed);

use base "Dancer::Session::Abstract";

our $VERSION = 'v0.1.6'; # VERSION
# ABSTRACT: CHI-based session engine for Dancer

# Class methods:

my $chi;
sub _chi {

    return $chi if blessed($chi);

    my $options = setting("session_CHI");
    if ( ref($options) ne "HASH" ) {
        raise core_session => "CHI session options not found";
    }

    # Don't let CHI determine the absolute path:
    if ( exists $options->{root_dir} ) {
        $options->{root_dir} = rel2abs($options->{root_dir});
    }

    my $use_plugin = delete $options->{use_plugin};
    my $is_loaded = exists setting("plugins")->{"Cache::CHI"};
    if ( $use_plugin && !$is_loaded ) {
        raise core_session => "CHI plugin requested but not loaded";
    }

    $chi = $use_plugin
        ? do {
            my $plugin = "Dancer::Plugin::Cache::CHI";
            unless ( Dancer::ModuleLoader->load($plugin) ) {
                raise core_session => "$plugin is needed and is not installed";
            }
            Dancer::Plugin::Cache::CHI::cache()
        }
        : CHI->new(%$options);
    return $chi;
}

sub create {
    my $self = __PACKAGE__->new->flush;
    Dancer::Logger->debug("Session (id: " . $self->id . " created.");
    return $self;
}

sub retrieve {
    my (undef, $session_id) = @_;
    return _chi->get("session_$session_id");
}

# Object methods:

sub flush {
    my ($self) = @_;
    my $session_id = $self->id;
    _chi->set( "session_$session_id" => $self );
    return $self;
}

sub purge {
    _chi->purge;
    return;
}

#sub reset :method { goto &purge }

sub destroy {
    my ($self) = @_;
    my $session_id = $self->id;
    _chi->remove("session_$session_id");
    cookies->{setting("session_name")}->expires(0);
    Dancer::Logger->debug("Session (id: $session_id) destroyed.");
    return $self;
}

1;
=encoding utf8

=head1 NAME

Dancer::Session::CHI - CHI-based session engine for Dancer

=head1 SYNOPSIS

In a L<Dancer> application:

    set session          => "CHI";
    set session_expires  => "1 hour";
    set session_CHI      => { use_plugin => 1 };

    set plugins          => {
        "Cache::CHI" => {
            driver => 'Memory',
            global => 1
        }
    };

In a F<config.yml>:

    session: CHI
    session_expires: 1 hour
    session_CHI:
        use_plugin: 1

    plugins:
        Cache::CHI:
            driver: Memory
            global: 1

=head1 DESCRIPTION

This module leverages L<CHI> to provide session management for L<Dancer>
applications. Just as L<Dancer::Session::KiokuDB> opens up L<KiokuDB>'s
full range of C<KiokuDB::Backend>::* modules to be used in Dancer session
management, L<Dancer::Session::CHI> makes available the complete
C<CHI::Driver>::* collection.

=head1 CONFIGURATION

Under its C<session_CHI> key, Dancer::Session::CHI accepts a C<use_plugin>
option that defaults to C<0>. If set to C<1>, L<Dancer::Plugin::Cache::CHI>
will be used directly for session management, with no changes made to the
plugin's configuration.

If C<use_plugin> is left false, all other options are passed through to
construct a new L<CHI> object, even if L<Dancer::Plugin::Cache::CHI> is also in
use. This new object needn't use the same L<CHI::Driver> as the plugin.

=head1 METHODS

=for Pod::Coverage BUILD

=head2 CLASS

=over

=item C<create()>

Creates a new session object and returns it.

=item C<retrieve($id)>

Returns the session object containing an ID of $id.

=back

=head2 OBJECT

=over

=item C<flush()>

Writes all session data to the CHI storage backend.

=item C<destroy()>

Ends a Dancer session and wipes the session's data from the CHI storage backend.

=item C<purge()>

Direct access to CHI's C<purge()> method, clearing the data of all expired
sessions from the CHI storage backend.

=back

=head1 CAVEATS

=over

=item *

Some L<CHI::Driver> parameters are sufficiently complex to not be placeable in a F<config.yml>. Session and/or
plugin configuration may instead be needed to be done in application code.

=item *

When using L<CHI::Driver::DBI>, thread/fork safety can be ensured by passing it
a L<DBIx::Connector> object or database handle returned by
L<Dancer::Plugin::Database>'s C<database()> subroutine.

=back

=head1 BUGS

This is an initial I<TRIAL> release, so bugs may be lurking. Please report any issues to this module's
L<GitHub issues page|https://github.com/rsimoes/Dancer-Session-CHI/issues>.

=head1 AUTHOR

Richard Simões <rsimoes at CPAN dot org>

=head1 COPYRIGHT & LICENSE

Copyright © 2013 Richard Simões. This module is released under the terms of the
B<MIT License> and may be modified and/or redistributed under the same or any
compatible license.
