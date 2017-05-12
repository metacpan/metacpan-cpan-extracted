package Catalyst::Plugin::Session::Store::CDBI;

use strict;
use base qw/Catalyst::Plugin::Session::Store/;
use NEXT;
use Catalyst::Exception ();
use Class::DBI;
use MIME::Base64;
use Storable qw/freeze thaw/;

our $VERSION = '0.03';

=head1 NAME

Catalyst::Plugin::Session::Store::CDBI - CDBI sessions for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/Session Session::Store::CDBI Session::State::Cookie/;
    
    MyApp->config->{session} = {
        storage_class => 'MyApp::M::CDBI::Session',
        id_field      => 'id',
        storage_field => 'storage',
        expires_field => 'expires',
        expires       => 3600,
        need_commit   => 0,
    };

    # ... in an action:
    $c->session->{foo} = 'bar'; # will be saved

=head1 DESCRIPTION

C<Catalyst::Plugin::Session::Store::CDBI> is a session storage plugin
for Catalyst that uses Class::DBI.

=head2 METHODS

=over 4

=item get_session_data

=item store_session_data

=item delete_session_data

=item delete_expired_sessions

=item setup_actions

=item setup_session

These are implementations of the required methods for a store. See
L<Catalyst::Plugin::Session::Store>.

=item serialize

Returns the serialized form of the data passed in.

=item deserialize

Returns the deserialized data.

=cut

sub get_session_data {
    my ( $c, $sid ) = @_;

    return unless $sid;

    my $cfg           = $c->config->{session};
    my $storage_class = $c->_verify_storage_class( $cfg->{storage_class} );

    my $storage_field = $cfg->{storage_field} || 'storage';
    my $id_field      = $c->_get_session_id_field();
    my $expires_field = $cfg->{expires_field} || 'expires';

    my $want_expires = 0;

    if ( $sid =~ /^expires:/ ) {
        my ($key) = $sid =~ /^expires:(.*)/;
        $sid = "session:$key";
        $want_expires = 1;
    }

    if ( my $s = $storage_class->search( $id_field => $sid )->first ) {
        if ( $want_expires ) {
            $c->log->debug("returning expires for $sid") if $c->debug;
            return $s->get($expires_field);
        }
        else {
          if ( my $data = $s->get($storage_field) ) {
              $c->log->debug("Deserializing session data for $sid") if $c->debug;
              return $c->deserialize($data);
          }
          else {
              return;
          }
        }
    }
    $c->log->debug("Could not find session for $sid") if $c->debug;

    return;
}

sub store_session_data {
    my ( $c, $sid, $data ) = @_;

    return unless $sid;

    my $cfg           = $c->config->{session};
    my $storage_class = $c->_verify_storage_class( $cfg->{storage_class} );

    my $storage_field = $cfg->{storage_field} || 'storage';
    my $id_field      = $c->_get_session_id_field();
    my $expires_field = $cfg->{expires_field} || 'expires';
    my $expires       = $cfg->{expires}       || 3600;
    my $need_commit   = $cfg->{need_commit}   || 0;

    my $want_expires = 0;

    if ( $sid =~ /^expires:/ ) {
        my ($key) = $sid =~ /^expires:(.*)/;
        $sid = "session:$key";
        $want_expires = 1;
    }

    if ( my $s = $storage_class->find_or_create( $id_field => $sid ) ) {

        if ( $want_expires ) {
            $s->set( $expires_field, $c->session_expires );
            $s->update;
        }
        else {
            $c->log->debug("Serializing session data for $sid") if $c->debug;
            $s->set( $storage_field, $c->serialize($data) );
            if ( $sid =~ /^(?:session|flash):/ ) {
                $s->set( $expires_field, $c->session_expires );
            }
            $s->update;
        }

    }
    else {

        $c->log->debug("Could not find session for $sid") if $c->debug;

    }

    $storage_class->dbi_commit if $need_commit;

    return;
}

sub delete_session_data {
    my ( $c, $sid ) = @_;

    return unless $sid;
    return if $sid =~ /^expires/;

    my $cfg           = $c->config->{session};
    my $storage_class = $c->_verify_storage_class( $cfg->{storage_class} );

    my $id_field      = $c->_get_session_id_field();

    $storage_class->search( $id_field => $sid )->delete_all();
    $storage_class->dbi_commit if ( $cfg->{need_commit} );

    $c->log->debug("Deleted session for $sid") if $c->debug;

    return;
}

sub delete_expired_sessions {
    my $c = shift;

    my $cfg           = $c->config->{session};
    my $storage_class = $c->_verify_storage_class( $cfg->{storage_class} );

    my $expires_field = $cfg->{expires_field} || 'expires';

    $storage_class->db_Main->do( sprintf "DELETE FROM %s WHERE %s < %d",
        $storage_class->table, $expires_field, time );
    $c->log->debug("Deleted expired sessions") if $c->debug;

    return;
}

sub _verify_storage_class {
    my ( $c, $storage_class ) = @_;

    $storage_class->require;
    if ($@) {
        Catalyst::Exception->throw(
            qq/Failed to require "$storage_class", "$@"/);
    }
    unless ( $storage_class->isa('Class::DBI') ) {
        Catalyst::Exception->throw(
            qq/Session-Class should be made with Class::DBI./);
    }

    return $storage_class;
}

sub serialize {
    my ( $c, $data ) = @_;
    encode_base64( freeze($data) );
}

sub deserialize {
    my ( $c, $data ) = @_;
    thaw( decode_base64($data) );
}

sub setup_session {
    my $c = shift;
    $c->NEXT::setup_session(@_);
}

sub setup_actions {
    my $c = shift;
    $c->NEXT::setup_actions(@_);
}

sub _get_session_id_field {
    my $c = shift;
    
    my $cfg = $c->config->{session};
    return $cfg->{id_field} if $cfg->{id_field};
    
    my $storage_class = $c->_verify_storage_class( $cfg->{storage_class} );

    my @pkeys = $storage_class->columns('Primary');
    if(scalar(@pkeys) > 1)
    {
        $c->error("More than one primary key setup on the session table.");
    }

    return $pkeys[0]->name;
}


=back

=head1 CONFIGURATION

These parameters are placed in the hash under the C<session> key in the
configuration hash.

=over 4

=item storage_class

CDBI-subclass that represents the table that stores session-data.

=item id_field

Column name for the primary key.  Defaults to 'id'.

=item storage_field

Column name used to store the serialized session data.  Defaults to 'storage'.

=item expires_field

Column name to store the expire time.  Defaults to 'expires'.

=item expires

Session time to live.  Defaults to 3600.

=item need_commit 

Defaults to 0.  Set to 1 when the CDBI class has AutoCommit turned off.

=back

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::Plugin::Session>, L<Class::DBI>.

=head1 AUTHOR

Jason Woodward E<lt>C<woodwardj@jaos.org>E<gt>

Based on work by
Lyo Kato E<lt>lyo.kato@gmail.comE<gt>
Yuval Kogman E<lt>C<nothingmuch@woobling.org>E<gt>
Sebastian Riedel E<lt>C<sri@cpan.org>E<gt>,
Marcus Ramberg E<lt>C<mramberg@cpan.org>E<gt>,
Andrew Ford E<lt>C<andrewf@cpan.org>E<gt>,

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
