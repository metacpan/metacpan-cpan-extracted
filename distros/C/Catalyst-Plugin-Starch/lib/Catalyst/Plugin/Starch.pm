package Catalyst::Plugin::Starch;

$Catalyst::Plugin::Starch::VERSION = '0.04';

=head1 NAME

Catalyst::Plugin::Starch - Catalyst session plugin via Starch.

=head1 SYNOPSIS

    package MyApp;
    
    use Catalyst qw(
        Starch::Cookie
        Starch
    );
    
    __PACKAGE__->config(
        'Plugin::Starch' => {
            cookie_name => 'my_session',
            store => { class=>'::Memory' },
        },
    );

=head1 DESCRIPTION

Integrates L<Starch> with L<Catalyst> providing a compatible replacement
for L<Catalyst::Plugin::Session>.

Is is recommended that as part of implementing this module in your site
that you also create an in-house unit test using L<Test::Starch>.

Note that this plugin is a L<Moose::Role> which means that Catalyst will
apply the plugin to the Catalyst object in reverse order than that listed
in the C<use Catalyst> stanza.  This may not matter for you, but to be safe,
declare the C<Starch> plugin B<after> any other Starch plugins or any other
plugins that depend on sessions.

=head1 CONFIGURATION

Configuring Starch is a matter of setting the C<Plugin::Starch> configuration
key in your root Catalyst application class:

    __PACKAGE__->config(
        'Plugin::Starch' => {
            store => { class=>'::Memory' },
        },
    );

In addition to the arguments you would normally pass to L<Starch> you
can also pass a C<plugins> argument which will be combined with the plugins
from L</default_starch_plugins>.

See L<Starch> for more information about configuring Starch.

=cut

use Starch;
use Types::Standard -types;
use Types::Common::String -types;
use Catalyst::Exception;
use Scalar::Util qw( blessed );
use Class::Method::Modifiers qw( fresh );

use Moose::Role;
use MooseX::ClassAttribute;
use strictures 2;
use namespace::clean;

=head1 COMPATIBILITY

This module is mostly API compliant with L<Catalyst::Plugin::Session>.  The way you
configure this plugin will be different, but all your code that uses sessions, or
other plugins that use sessions, should not need to be changed unless they
depend on undocumented features.

Everything documented in the L<Catalyst::Plugin::Session/METHODS> section is
supported except for:

=over

=item *

The C<flash>, C<clear_flash>, and C<keep_flash> methods are not implemented
as its really a terrible idea.  If this becomes a big issue for compatibility
with existing code and plugins then this may be reconsidered.

=item *

The C<session_expire_key> method is not supported, but can be if it is deemed
a good feature to port.

=back

Everything in the L<Catalyst::Plugin::Session/INTERNAL METHODS> section is
supported except for:

=over

=item *

The
C<check_session_plugin_requirements>, C<setup_session>, C<initialize_session_data>,
C<validate_session_id>, C<generate_session_id>, C<session_hash_seed>,
C<calculate_extended_session_expires>, C<calculate_initial_session_expires>,
C<create_session_id_if_needed>, C<delete_session_id>, C<extend_session_expires>,
C<extend_session_id>, C<get_session_id>, C<reset_session_expires>,
C<set_session_id>, and C<initial_session_expires>
methods are not supported.  Some of them could be, if a good case for their
existence presents itself.

=item *

The C<setup>, C<prepare_action>, and C<finalize_headers> methods are not altered
because they do not need to be.

=back

The above listed unimplemented methods and attributes will throw an exception
if called.

=head1 PERFORMANCE

Benchmarking L<Catalyst::Plugin::Session> and L<Catalyst::Plugin::Starch>
it was found that Starch is 1.5x faster (or, ~65% the run-time).  While this
is a fairly big improvement, the difference in real-life should be a savings
of one or two millisecond per request.

Most of this performance gain is made by the fact that Starch does not use
L<Moose> and instead it uses L<Moo> which has many run-time performance
benefits.

=cut

foreach my $method (qw(
    flash clear_flash keep_flash
    session_expire_key
    check_session_plugin_requirements setup_session initialize_session_data
    validate_session_id generate_session_id session_hash_seed
    calculate_extended_session_expires calculate_initial_session_expires
    create_session_id_if_needed delete_session_id extend_session_expires
    extend_session_id get_session_id reset_session_expires
    set_session_id initial_session_expires
)) {
    fresh $method => sub{
        Catalyst::Exception->throw( "The $method method is not implemented by Catalyst::Plugin::Starch" );
    };
}

=head1 ATTRIBUTES

=head2 sessionid

The ID of the session.

=cut

has sessionid => (
    is        => 'ro',
    init_arg  => undef,
    writer    => '_set_sessionid',
    clearer   => '_clear_sessionid',
    predicate => '_has_sessionid',
);

=head2 session_expires

Returns the time when the session will expire (in epoch time).  If there
is no session then C<0> will be returned.

=cut

sub session_expires {
    my ($self) = @_;
    return 0 if !$self->_has_sessionid();
    my $session = $self->starch_state();
    return $session->modified() + $session->expires();
}

=head2 session_delete_reason

Returns the C<reason> value passsed to L</delete_session>.
Two common values are:

=over

=item *

C<address mismatch>

=item *

C<session expired>

=back

=cut

has session_delete_reason => (
    is       => 'ro',
    isa      => NonEmptySimpleStr,
    init_arg => undef,
    writer   => '_set_session_delete_reason',
    clearer  => '_clear_session_delete_reason',
);

=head2 default_starch_plugins

This attribute returns the base set plugins that the L</starch>
object will be built with.  Note that this does not include any
additional plugins you specify in the L</CONFIGURATION>.

The intention of this attribute is for other Catalyst plugins, such as
L<Catalyst::Plugin::Starch::Cookie>, to be able to declare
additional Starch plugins by C<around()>ing this and injecting
their own plugins into the array ref.

=cut

sub default_starch_plugins {
    return [];
}

=head2 starch_state

This holds the underlying L<Starch::State> object.

=cut

has starch_state => (
    is        => 'ro',
    isa        => InstanceOf[ 'Starch::State' ],
    lazy      => 1,
    builder   => '_build_starch_state',
    writer    => '_set_starch_state',
    predicate => '_has_starch_state',
    clearer   => '_clear_starch_state',
);
sub _build_starch_state {
    my ($c) = @_;
    my $state = $c->starch->state( $c->sessionid() );
    $c->_set_sessionid( $state->id() );
    return $state;
}

=head1 CLASS ATTRIBUTES

=head2 starch

The L<Starch::Manager> object.  This gets automatically constructed from
the C<Plugin::Starch> Catalyst configuration key per L</CONFIGURATION>.

=cut

class_has starch => (
    is      => 'ro',
    isa     => InstanceOf[ 'Starch::Manager' ],
    lazy    => 1,
    builder => '_build_starch',
);
sub _build_starch {
    my ($c) = @_;

    my $starch = $c->config->{'Plugin::Starch'};
    Catalyst::Exception->throw( 'No Catalyst configuration was specified for Plugin::Starch' ) if !$starch;
    Catalyst::Exception->throw( 'Plugin::Starch config was not a hash ref' ) if ref($starch) ne 'HASH';

    my $args = Starch::Manager->BUILDARGS( $starch );
    my $plugins = delete( $args->{plugins} ) || [];

    $plugins = [
        @{ $c->default_starch_plugins() },
        @$plugins,
    ];

    return Starch->new(
        plugins => $plugins,
        %$args,
    );
}

=head1 METHODS

=head2 session

    $c->session->{foo} = 45;
    $c->session( foo => 45 );
    $c->session({ foo => 45 });

Returns a hash ref of the session data which may be modified and
will be stored at the end of the request.

A hash list or a hash ref may be passed to set values.

=cut

sub session {
    my $c = shift;

    my $data = $c->starch_state->data();
    return $data if !@_;

    my $new_data;
    if (@_==1 and ref($_[0]) eq 'HASH') {
        $new_data = $_[0];
    }
    else {
        $new_data = { @_ };
    }

    foreach my $key (keys %$new_data) {
        $data->{$key} = $new_data->{$key};
    }

    return $data;
}

=head2 delete_session

    $c->delete_session();
    $c->delete_session( $reason );

Deletes the session, optionally with a reason specified.

=cut

sub delete_session {
    my ($c, $reason) = @_;

    if ($c->_has_starch_state()) {
        $c->starch_state->delete();
    }

    $c->_set_session_delete_reason( $reason );

    return;
}

=head2 save_session

Saves the session to the store.

=cut

sub save_session {
    my ($c) = @_;
    $c->starch_state->save();
    return;
}

=head2 change_session_id

    $c->change_session_id();

Generates a new ID for the session but retains the session
data in the new session.

Some interesting discussion as to why this is useful is at
L<Catalyst::Plugin::Session/METHODS> under the C<change_session_id>
method.

=cut

sub change_session_id {
    my ($c) = @_;

    $c->_clear_sessionid();

    $c->starch_state->reset_id() if $c->_has_starch_state();

    $c->_set_sessionid( $c->starch_state->id() );

    return;
}

=head2 change_session_expires

Sets the expires duration on the session which defaults to the
global expires set in L</CONFIGURATION>.

=cut

sub change_session_expires {
    my $self = shift;
    $self->starch_state->set_expires( @_ );
    return;
}

=head2 session_is_valid

Currently this always returns C<1>.

=cut

sub session_is_valid { 1 }

=head2 delete_expired_sessions

Calls L<Starch::Store/reap_expired> on the store.  This method is
here for backwards compatibility with L<Catalyst::Plugin::Session>
which expects you to delete expired sessions within the context of
an HTTP request.  Since starch is available independently from Catalyst
you should consider calling C<reap_expired> yourself within a cronjob.

If the store does not support expired session reaping then an
exception will be thrown.

=cut

sub delete_expired_sessions {
    my ($self) = @_;

    $self->starch->store->reap_expired();

    return;
}

sub finalize_session {
    my ($c) = @_;

    $c->_clear_sessionid();
    $c->_clear_session_delete_reason();

    return if !$c->_has_starch_state();

    $c->save_session();

    return;
}

after setup_finalize => sub{
    my ($c) = @_;
    $c->starch();
    return;
};

before finalize_body => sub{
    my ($c) = @_;
    $c->finalize_session();
    return;
};

around dump_these => sub{
    my $orig = shift;
    my $c = shift;

    return $c->$orig( @_ ) if !$c->_has_sessionid();

    return(
      $c->$orig( @_ ),
      [ 'SessionID' => $c->sessionid() ],
      [ 'Session'   => $c->session()   ],
    );
};

1;
__END__

=head1 SUPPORT

Please submit bugs and feature requests to the
Catalyst-Plugin-Starch GitHub issue tracker:

L<https://github.com/bluefeet/Catalyst-Plugin-Starch/issues>

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

