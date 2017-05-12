package Catalyst::Plugin::Session::State::Stash; # git description: 0.12-14-g745a242
# ABSTRACT: Maintain session IDs using the stash

use Moose;
use 5.008;
use MRO::Compat;
use namespace::autoclean;

extends 'Catalyst::Plugin::Session::State';

our $VERSION = '0.14';

has _deleted_session_id => ( is => 'rw' );
has _prepared => ( is => 'rw' );

sub _stash_key_components {
    my ($c) = @_;
    my $config = $c->_session_plugin_config;
    return ($config->{stash_delim}) ?
        split $config->{stash_delim}, $config->{stash_key} :
        $config->{stash_key};
}

sub _get_session {
    my ($c) = @_;
    # This turns the list of path components into a nested tree of hashrefs for obtaining info/storing in: 123/456 = {123}->{456}
    my $ref = $c->stash;
    $ref = ($ref->{$_} ||= {}) foreach $c->_stash_key_components;
    $ref;
}

sub _set_session {
    my ( $c,$key,$value) = @_;
    $c->_get_session->{$key} = $value;
}

sub setup_session {
    my $c = shift;

    $c->maybe::next::method(@_);

    $c->_session_plugin_config->{stash_key} ||= '_session';
}

sub prepare_action {
    my $c = shift;
    my $id = $c->get_session_id;
    $c->_prepared(1);
    if ( $id ) {
        $c->sessionid( $id );
    }
    $c->maybe::next::method( @_ );
}

sub get_session_id {
    my $c = shift;
    if(!$c->_deleted_session_id and my $session = $c->_get_session) {
        my $sid = $session->{id};
        return $sid if $sid;
    }
    $c->maybe::next::method(@_);
}

sub set_session_id {
    my ( $c, $sid ) = @_;
    $c->_set_session(id => $sid);
    $c->maybe::next::method($sid);
}

sub get_session_expires {
    my $c = shift;
    my $session = $c->_get_session;
    defined $session->{expires} ? $session->{expires} : undef;
}

sub set_session_expires {
    my ( $c, $expires ) = @_;
    $c->_set_session(expires => time() + $expires);
    $c->maybe::next::method($expires)
}

sub delete_session_id {
    my ($c, $sid ) = @_;
    $c->_deleted_session_id(1);
    #Empty the tip
    %{$c->_get_session} = ();
    $c->maybe::next::method($sid);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catalyst::Plugin::Session::State::Stash - Maintain session IDs using the stash

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use Catalyst qw/Session Session::State::Stash Session::Store::Foo/;

=head1 DESCRIPTION

An alternative state storage plugin that allows you some more flexibility in
dealing with session storage. This plugin loads and saves the session ID from
and to the stash.

=head1 METHODS

=over 4

=item delete_session_id

Deletes the session. Unfortunately I've been unable to squash a bug that will
stop you from opening a new session in the same execution, however.
Patches welcome!

=item get_session_id

Gets the current session id.

=item set_session_id

Sets the session id to the C<shift>.

=item get_session_expires

Gets when the current session expires.

=item set_session_expires

Sets how many seconds from now the session should expire.

=back

=head1 EXTENDED METHODS

=over 4

=item prepare_action

Loads the id off the stash.

=item setup_session

Defaults the C<stash_key> parameter to C<_session>.

=back

=head1 CONFIGURATION

=over 4

=item stash_key

The name of the hash key to use. Defaults to C<_session>.

=item stash_delim

If present, splits C<stash_key> at this character to nest. E.g. a C<delim> of '/'
and C<stash_key> of '123/456' will store it as $c->stash->{123}->{456}

=item expires

How long the session should last in seconds.

=back

For example, you could stick this in F<MyApp.pm>:

  __PACKAGE__->config( 'Plugin::Session' => {
     stash_key  => 'session_id',
  });

=head1 BUGS

You can't delete a session then create a new one. If this is important to you,
patches welcome!

=head1 CAVEATS

Manual work may be involved to make better use of this.

=for stopwords stateful

If you are writing a stateful web service with
L<Catalyst::Plugin::Server::XMLRPC>, you will probably only have to deal with
loading, as when saving, the ID will already be on the stash.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Catalyst::Plugin::Session::State>,
L<Catalyst::Plugin::Session::State::Cookie> (what you probably want).

=head1 AUTHOR

James Laver <perl -e 'printf qw/%s@%s.com cpan jameslaver/'>

=head1 CONTRIBUTORS

=over 4

=item *
This module is derived from L<Catalyst::Plugin::Session::State::Cookie> code.
Thanks to anyone who wrote code for that.

=item *
Thanks to Kent Fredric for a patch for nested keys

=back

=for stopwords Florian Ragwitz Karen Etheridge Tomas Doran James Laver

=over 4

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Tomas Doran <bobtfish@bobtfish.net>

=item *

James Laver <jjl@baozi.local>

=item *

James Laver <james@jameslaver.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by James Laver.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
