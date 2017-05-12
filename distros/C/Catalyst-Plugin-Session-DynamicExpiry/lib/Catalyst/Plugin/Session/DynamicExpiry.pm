package Catalyst::Plugin::Session::DynamicExpiry;
use Moose;
use MRO::Compat;
use Try::Tiny;
use namespace::autoclean;

our $VERSION='0.04';

has [qw/_session_time_to_live/] => ( is => 'rw' );

sub session_time_to_live {
    my ( $c, @args ) = @_;

    if ( @args ) {
        $c->_session_time_to_live($args[0]);
        try { $c->_session->{__time_to_live} = $args[0] };
    }

    return $c->_session_time_to_live || eval { $c->_session->{__time_to_live} };
}

sub calculate_initial_session_expires {
    my $c = shift;

    if ( defined( my $ttl = $c->_session_time_to_live ) ) {
        $c->log->debug("Overridden time to live: $ttl") if $c->debug;
        return time() + $ttl;
    }

    return $c->next::method( @_ );
}

sub calculate_extended_session_expires {
    my $c = shift;


    if ( defined(my $ttl = $c->session_time_to_live) ) {
        $c->log->debug("Overridden time to live: $ttl") if $c->debug;
        return time() + $ttl;
    }

    return $c->next::method( @_ );
}

sub _save_session {
    my $c = shift;

    if ( my $session_data = $c->_session ) {
        if ( defined( my $ttl = $c->_session_time_to_live ) ) {
            $session_data->{__time_to_live} = $ttl;
        }
    }

    $c->next::method( @_ );
}

1;

=head1 NAME

Catalyst::Plugin::Session::DynamicExpiry - per-session custom expiry times

=head1 SYNOPSIS

    # put Session::DynamicExpiry in your use Catalyst line
    # note that for this plugin to work it must appear before the Session
    # plugin, since it overrides some of that plugin's methods.
    
    use Catalyst qw/ ...

        Session::DynamicExpiry
        Session
    /;
    
    if ($c->req->param('remember') { 
      $c->session_time_to_live( 604800 ) # expire in one week.
    }

=head1 DESCRIPTION

This module allows you to expire session cookies indvidually per session.

If the C<session_time_to_live> field is defined it will set expiry to that many
seconds into the future. Note that the session cookie is set on every request,
so a expiry of one week will stay as long as the user visits the site at least
once a week.

Once ttl has been set for a session the ttl will be stored in the
C<__time_to_live> key within the session data itself, and reused for subsequent
request, so you only need to set this once per session (not once per request).

This is unlike the ttl option in the config in that it allows different
sessions to have different times, to implement features like "remember me"
checkboxes.

=head1 METHODS

=head2 session_time_to_live $ttl

To set the TTL for this session use this method.

=head1 OVERRIDDEN METHODS

=head2 calculate_initial_session_expires

=head2 calculate_extended_session_expires

Overridden to implement dynamic expiry functionality.

=head1 CAVEATS

When it just doesn't work, it's usually because you put it after
L<Catalyst::Plugin::Session> in the plugin list. It must go before it so that
it can override L<Catalyst::Plugin::Session>'s methods.

=head1 SEE ALSO

=head2 L<Catalyst::Plugin::Session> - The new session framework.

=head2 L<Catalyst> - The Catalyst framework itself.

=head1 AUTHOR

Marcus Ramberg, C<mramberg@cpan.org>
Yuval Kogman

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
