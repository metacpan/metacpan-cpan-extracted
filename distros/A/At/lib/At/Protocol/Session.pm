use v5.42;
use feature 'class';
no warnings 'experimental::class';

class At::Protocol::Session {
    field $accessJwt : param : reader //= ();
    field $did          : param : reader;
    field $handle       : param : reader = ();
    field $refreshJwt   : param : reader //= ();
    field $token_type   : param : reader = 'Bearer';
    field $dpop_key_jwk : param : reader = ();
    field $client_id    : param : reader = ();
    field $pds          : param : reader = ();

    # Additional fields returned by server
    field $email           : param : reader = ();
    field $emailConfirmed  : param : reader = ();
    field $emailAuthFactor : param : reader = ();
    field $active          : param : reader = ();
    field $status          : param : reader = ();
    field $didDoc          : param : reader = ();
    field $scope           : param : reader = ();
    ADJUST {
        require At::Protocol::DID;
        $did = At::Protocol::DID->new($did) unless builtin::blessed $did;
    }

    method _raw {
        +{  accessJwt  => $accessJwt,
            did        => $did . "",
            refreshJwt => $refreshJwt,
            defined $handle ? ( handle => $handle . "" ) : (),
            token_type => $token_type,
            defined $dpop_key_jwk ? ( dpop_key_jwk => $dpop_key_jwk ) : (), defined $client_id ? ( client_id => $client_id ) : (),
            defined $pds ? ( pds => $pds . "" ) : (),
        };
    }
}
1;
__END__

=pod

=encoding utf-8

=head1 NAME

At::Protocol::Session - AT Protocol Session Container

=head1 SYNOPSIS

    my $session = At::Protocol::Session->new(
        did       => 'did:plc:...',
        accessJwt => '...',
        handle    => 'user.bsky.social'
    );

    say $session->did;
    say $session->handle;

=head1 DESCRIPTION

C<At::Protocol::Session> stores authentication data for an active session. It supports both legacy password-based
sessions and modern OAuth/DPoP sessions.

=head1 Attributes

=head2 C<accessJwt()>

The access token for the session.

=head2 C<refreshJwt()>

The refresh token for the session.

=head2 C<did()>

The DID of the authenticated user. This is returned as an L<At::Protocol::DID> object.

=head2 C<handle()>

The handle of the authenticated user.

=head2 C<token_type()>

Typically 'Bearer' for legacy sessions or 'DPoP' for OAuth sessions.

=head2 C<scope()>

The scopes granted to this session.

=head2 C<email()>, C<emailConfirmed()>

User's email information, if available.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms found in the Artistic License
2. Other copyrights, terms, and conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

atproto

=end stopwords

=cut
