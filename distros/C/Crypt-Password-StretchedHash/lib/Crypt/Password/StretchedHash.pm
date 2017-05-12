package Crypt::Password::StretchedHash;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.05";

use Exporter qw(
    import
);
use Carp qw(
    croak
);
use MIME::Base64 qw(
    encode_base64
    decode_base64
);
use Params::Validate qw(
    SCALAR
);

our @EXPORT_OK = qw(
    crypt
    verify
    crypt_with_hashinfo
    verify_with_hashinfo
);

sub crypt {

    my %params = Params::Validate::validate(@_, {
        password        => { type => SCALAR },
        hash            => 1,
        salt            => { type => SCALAR },
        stretch_count   => { type => SCALAR, regex => qr/\A[0-9]+\z/,},
        format          => { type => SCALAR, optional => 1 },
    });

    my $salt = $params{salt};
    croak "\$params{hash} must be Digest::SHAx Object"
        unless ( $params{hash}->isa("Digest::SHA") || 
                $params{hash}->isa("Digest::SHA3"));

    my $hash = $params{hash};

    croak "\$params{stretch_count} must be more than 1"
        unless ($params{stretch_count} > 0);

    my $pwhash = q{};
    for (1..$params{stretch_count}) {
        $hash->add( $pwhash, $params{password}, $salt );
        $pwhash = $hash->digest;
    }

    if ( exists $params{format} && $params{format} eq q{hex} ){
        $pwhash = unpack("H*", $pwhash);
    }elsif( exists $params{format} && $params{format} eq q{base64} ){
        $pwhash = encode_base64 $pwhash;
        $pwhash =~ s/\n//;
        chomp($pwhash);
    }

    return $pwhash;
}

sub verify {

    my %params = Params::Validate::validate(@_, {
        password        => { type => SCALAR },
        password_hash   => { type => SCALAR },
        hash            => 1,
        salt            => { type => SCALAR },
        stretch_count   => { type => SCALAR, regex => qr/\A[0-9]+\z/,},
        format          => { type => SCALAR, optional => 1 },
    });

    my $pwhash = $params{password_hash};
    delete $params{password_hash};
    my $calculated_pwhash = Crypt::Password::StretchedHash::crypt( %params );
    return ( $calculated_pwhash eq $pwhash );
}

sub crypt_with_hashinfo {

    my %params = Params::Validate::validate(@_, {
        password    => { type => SCALAR },
        hash_info   => 1,
    });

    # validate hashinfo object
    my $hash_info = $params{hash_info};
    croak "\$params{hash_info} must be Crypt::Password::StretchedHash::HashInfo Object"
        unless ( $hash_info->isa("Crypt::Password::StretchedHash::HashInfo") );

    my $salt = $hash_info->salt;

    my $pwhash = Crypt::Password::StretchedHash::crypt(
        password        => $params{password},
        hash            => $hash_info->hash,
        salt            => $salt,
        stretch_count   => $hash_info->stretch_count,
        format          => $hash_info->format,
    );

    if ( $hash_info->format eq q{hex} ){
        $salt = unpack("H*", $salt);
    }elsif( $hash_info->format eq q{base64} ){
        $salt = encode_base64 $salt;
        chomp($salt);
    }
    
    return  $hash_info->delimiter . 
            $hash_info->identifier.
            $hash_info->delimiter.
            $salt.
            $hash_info->delimiter.
            $pwhash;

}

sub verify_with_hashinfo {

    my %params = Params::Validate::validate(@_, {
        password        => { type => SCALAR },
        password_hash   => { type => SCALAR },
        hash_info       => 1,
    });

    # validate hashinfo object
    my $hash_info = $params{hash_info};
    croak "\$params{hash_info} must be Crypt::Password::StretchedHash::HashInfo Object"
        unless ( $hash_info->isa("Crypt::Password::StretchedHash::HashInfo") );

    # split password hash
    my $delimiter = quotemeta($hash_info->delimiter);
    my $identifier = $hash_info->identifier;
    my ( $pwhash, $salt );

    my @split_password_hash = split( /$delimiter/, $params{password_hash} );
    if ($params{password_hash} =~ /\A$delimiter/ &&  
        scalar @split_password_hash == 4 &&
        $split_password_hash[0] eq q{} &&
        $identifier eq $split_password_hash[1] ){
        $salt = $split_password_hash[2];
        $pwhash = $split_password_hash[3];
    } else {
        return;
    }

    # obtain law_salt string
    if ( $hash_info->format eq q{hex} ){
        $salt = pack("H*", $salt);
    }elsif( $hash_info->format eq q{base64} ){
        $salt = decode_base64 $salt;
    }

    # generate hashed password
    my $expected_pwhash = Crypt::Password::StretchedHash::crypt(
        password        => $params{password},
        hash            => $hash_info->hash,
        salt            => $salt,
        stretch_count   => $hash_info->stretch_count,
        format          => $hash_info->format,
    );
    return ( $expected_pwhash eq $pwhash );

}

1;
__END__

=encoding utf-8

=head1 NAME

Crypt::Password::StretchedHash - simple library for password hashing and stretching

=head1 SYNOPSIS

This module provides Generation / Verification method for hashed password string.
There are two methods to handle parameters simply.

    use Crypt::Password::StretchedHash qw(
        crypt
        verify
    );
    use Digest::SHA;

    # crypt
    my $pwhash = crypt(
        password        => q{password},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{base64},
    );

    # verify
    my $result = verify(
        password        => q{password},
        password_hash   => q{4hvvzqZio+l9vGifQ7xF2+FKiyWRcb4lV3OSo9PsfUw=},
        hash            => Digest::SHA->new("sha256"),
        salt            => q{salt},
        stretch_count   => 5000,
        format          => q{base64},
    );


if you use class of the hash information(Crypt::Passwoed::SaltedHash::HashInfo),
there are two methods to generate/verify string for DB Store. 

    use Your::Password::HashInfo;
    use Crypt::Password::StretchedHash qw(
        crypt_with_hashinfo
        verify_with_hashinfo
    );
    
    my $hash_info = Your::Password::HashInfo->new;
    # crypt
    my $password = ...;
    my $pwhash_with_hashinfo = crypt_with_hashinfo(
        password    => $password,
        hash_info   => $hash_info,
    );
    
    # verify
    my $password = ...;
    my $pwhash_with_hashinfo = ...;
    my $result = verify_with_hashinfo(
        password        => $password,
        password_hash   => $pwhash_with_hashinfo,
        hash_info   => $hash_info,
    );

=head1 DESCRIPTION

Crypt::Password::StretchedHash is simple library for password hashing and stretching.
This module is available in generation and validation of the stretched password hash.

=head1 METHODS

=head2 crypt( %params ) : String

Generates stretched password hash.
This uses the following hash algorithm.

    for (1..$params{stretch_count}) {
        $hash->add( $pwhash, $params{password}, $salt );
        $pwhash = $hash->digest;
    }

=over
 
=item $params{password}

This is password string.

=item $params{hash}
 
This is a hash function.
This value must be the object of Digest::SHA or Digest::SHA3.

=item $params{salt}
 
This is salt string.

=item $params{stretch_count}

This is stretching count.
The value will depend on a kind of hash function and the server load.

=item $params{format}

This value is optional.
If it has none, the password hash is returned with a binary string.
If it has "hex", the password hash is returned with hexadecimal representation.
If it has "base64", the password hash is returned with base64 representation.

=back

=head2 verify( %params ) : Int

Verifies stretched password hash.
This compares the value of $params{password_hash} with the generated using crypt method.

=head2 crypt_with_hashinfo( %params ) : String

Generates stretched password hash with hash information.

=over

=item $params{password}

This is password string.

=item $params{hash_info}
 
This is a hash information.
You have to inherit L<Crypt::Password::StretchedHash::HashInfo>.

=back

=head2 verify_with_hashinfo( %params ) : Int

Verifies stretched password hash with hash information.
This compares the value of $params{password_hash} with the generated using crypt method.

=over

=item $params{password}

This is password string.

=item $params{password_hash}

This is hashed password to be compared.

=item $params{hash_info}
 
This is a hash information.
You have to inherit L<Crypt::Password::StretchedHash::HashInfo>.

=back

=head1 LICENSE

Copyright (C) Ryo Ito.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ryo Ito E<lt>ritou.06@gmail.comE<gt>

=cut

