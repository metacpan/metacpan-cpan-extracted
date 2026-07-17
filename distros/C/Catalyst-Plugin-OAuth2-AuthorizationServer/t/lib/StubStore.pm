package StubStore;
use v5.36;
use Moo;
with 'Catalyst::Plugin::OAuth2::AuthorizationServer::Role::Store';

has clients  => ( is => 'ro', default => sub { {} } );
has requests => ( is => 'ro', default => sub { {} } );
has codes    => ( is => 'ro', default => sub { {} } );
has refresh  => ( is => 'ro', default => sub { {} } );

has revoked_families => ( is => 'ro', default => sub { {} } );

sub create_client ( $self, $client ) {
    $self->clients->{ $client->{client_id} } = $client;
    return $client;
}
sub find_client ( $self, $id ) { return $self->clients->{$id} }

sub save_authorization_request ( $self, $rid, $data, $exp ) {
    $self->requests->{$rid} = { data => $data, exp => $exp };
    return 1;
}
sub take_authorization_request ( $self, $rid ) {
    my $row = delete $self->requests->{$rid} or return undef;
    return undef if $row->{exp} < time;
    return $row->{data};
}

sub create_auth_code ( $self, $code, $binding, $exp ) {
    $self->codes->{$code} = { binding => $binding, exp => $exp };
    return 1;
}
sub consume_auth_code ( $self, $code ) {
    my $row = delete $self->codes->{$code} or return undef;
    return undef if $row->{exp} < time;
    return $row->{binding};
}

sub create_refresh_token ( $self, $hash, $binding, $exp ) {
    # A successor must not be born into a family that has been revoked. The
    # check and the insert are one Store call, so this is atomic by
    # construction; the engine cannot provide that across two calls.
    return 0 if $self->revoked_families->{ $binding->{family_id} // '' };
    $self->refresh->{$hash}
        = { binding => $binding, exp => $exp, revoked => 0 };
    return 1;
}
sub rotate_refresh_token ( $self, $hash ) {
    my $row = $self->refresh->{$hash} or return undef;
    return undef if $row->{exp} < time;
    return { binding => $row->{binding}, reused => 1 } if $row->{revoked};
    $row->{revoked} = 1;    # tombstone: retained until exp, never deleted
    return { binding => $row->{binding} };
}
sub revoke_family ( $self, $family_id ) {
    # Mark the FAMILY, not just the rows that exist right now: a rotation in
    # flight may still create a successor after this returns.
    $self->revoked_families->{$family_id} = 1;
    my $n = 0;
    for my $h ( keys %{ $self->refresh } ) {
        my $row = $self->refresh->{$h};
        next if $row->{revoked};
        next unless ( $row->{binding}{family_id} // '' ) eq $family_id;
        $row->{revoked} = 1;
        $n++;
    }
    return $n;
}
sub revoke_refresh_tokens_for_subject ( $self, $subject ) {
    my $n = 0;
    for my $h ( keys %{ $self->refresh } ) {
        my $row = $self->refresh->{$h};
        next if $row->{revoked};
        next unless ( $row->{binding}{subject} // '' ) eq $subject;
        $row->{revoked} = 1;
        $n++;
    }
    return $n;
}

1;
