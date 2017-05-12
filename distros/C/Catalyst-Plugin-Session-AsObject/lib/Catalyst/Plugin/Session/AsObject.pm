package Catalyst::Plugin::Session::AsObject;
{
  $Catalyst::Plugin::Session::AsObject::VERSION = '0.05';
}

use strict;
use warnings;

use Catalyst::Plugin::Session 0.27;
use base 'Catalyst::Plugin::Session';

use MRO::Compat;

sub setup {
    my $self = shift;

    $self->maybe::next::method(@_);

    my $class = $self->_session_plugin_config()->{object_class};

    die 'Must provide an object_class in the session config when using '
        . __PACKAGE__
        unless defined $class;

    die
        "The object_class in the session config is either not loaded or does not have a new() method"
        unless $class->can('new');
}

sub has_session_object {
    my $self = shift;

    return $self->sessionid() && $self->session()->{__object};
}

sub session_object {
    my $self = shift;

    my $session = $self->session();

    $session->{__object}
        ||= $self->_session_plugin_config()->{object_class}->new();

    return $self->session()->{__object};
}

1;

# ABSTRACT: Make your session data an object



=pod

=head1 NAME

Catalyst::Plugin::Session::AsObject - Make your session data an object

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    package MyApp;

    use MyApp::Session;

    use Catalyst qw(
        Session
        Session::AsObject
        Session::Store::DBI
        Session::State::Cookie
    );

    __PACKAGE__->config(
        'Plugin::Session' => {
            ...,
            object_class => 'MyApp::Session',
        },
    );

    sub foo : Global {
        my $self = shift;
        my $c    = shift;

        my $session = $c->session_object();

        if ( $session->has_error_messages() ) {...}
    }

=head1 DESCRIPTION

This class makes it easier to treat the session as an object rather
than a plain hash reference. This is useful if you want to ensure that
the session only contains specific pieces of data.

However, because of implementation details, we cannot override the
existing C<< $c->session() >> method, so you need to use the new C<<
$c->session_object() >> method provided by this plugin.

=head1 METHODS

This class provides the following methods:

=head2 $c->session_object()

Returns the object stored in the session. If needed, a new object is
created.

=head2 $c->has_session_object()

Returns true if there is an object already in the session.

=head1 CONFIG

This plugin has only configuration key, "object_class". This key
should appear under the existing top-level "session" configuration
key.

The "object_class" must already be loaded, and must have a C<new()>
method as its constructor. This constructor must not require any
parameters, as it will be called without any arguments.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalyst-plugin-sessionasobject@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>.  I will be notified, and then
you'll automatically be notified of progress on your bug as I make
changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Dave Rolsky, E<gt>autarch@urth.orgE<lt>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__END__

