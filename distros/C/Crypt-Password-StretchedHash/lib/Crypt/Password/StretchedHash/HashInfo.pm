package Crypt::Password::StretchedHash::HashInfo;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub delimiter {
    my $self = shift;
    die "This is abstract method. You have to return delimiter string.";
}

sub identifier {
    my $self = shift;
    die "This is abstract method. You have to return identifier of your HashInfo.";
}

sub hash {
    my $self = shift;
    die "This is abstract method. You have to return Digest::SHA or Digest::SHA3 object.";
}

sub salt {
    my $self = shift;
    die "This is abstract method. This is called at the time of first crypt. You have to return randomized salt string for each users.";
}

sub stretch_count {
    my $self = shift;
    die "This is abstract method. You have to return stretch count.";
}

sub format {
    my $self = shift;
    die "This is abstract method. You have to return format for hashed password representation.";
}

1;

__END__

=encoding utf-8

=head1 NAME

Crypt::Password::StretchedHash::HashInfo - Base class that specifies accessor for password information.

=head1 DESCRIPTION

Crypt::Password::StretchedHash::HashInfo is base class that specifies accessor for password information.
You have to inherit this, and implements subroutines according to the interface contract.

=head1 SYNOPSIS

You implement your HashInfo class as follows.

    package Your::Password::HashInfo;
    use parent 'Crypt::Password::StretchedHash::HashInfo';
    use Digest::SHA;
    use Crypt::OpenSSL::Random;
    use constant STRETCH_COUNT => 5000;
    
    sub delimiter {
        my $self = shift;
        return q{$};
    }
    
    sub identifier {
        my $self = shift;
        return q{1};
    }
    
    sub hash {
        my $self = shift;
        return Digest::SHA->new("sha256");
    }
    
    sub salt {
        my $self = shift;
        return Crypt::OpenSSL::Random::random_pseudo_bytes(32);
    }
    
    sub stretch_count {
        my $self = shift;
        return STRETCH_COUNT;
    }
   
    sub format {
        my $self = shift;
        return q{base64};
    }

By passing your hashinfo to Crypt::Password::StretchedHash::crypt_with_hashinfo method,
you obtain the hashed password with identifier and salt.

    use Crypt::Password::StretchedHash qw(
        crypt_with_hashinfo
    );
    use Your::Password::HashInfo;
    
    my $password = ...;
    my $hash_info = Your::Password::HashInfo->new;
    my $pwhash_with_hashinfo = crypt_with_hashinfo(
        password    => $password,
        hash_info   => $hash_info,
    );

It is similar at the time of the verification,
you pass your hashinfo to Crypt::Password::StretchedHash::verify_with_hashinfo method.

    use Crypt::Password::StretchedHash qw(
        verify_with_hashinfo
    );
    use Your::Password::HashInfo;
    
    my $password = ...;
    my $pwhash_with_hashinfo = ...;
    my $hash_info = Your::Password::HashInfo->new;
    my $is_valid = verify_with_hashinfo(
        password        => $password,
        password_hash   => $pwhash_with_hashinfo,
        hash_info   => $hash_info,
    );

=head1 METHODS

=head2 new : Object

constructor

=head2 delimiter : String

It returns delimiter string.
If delimiter is "$", generated string is as follows.

    $(identifier)$(salt)$(hashed password)

=head2 identifier : String

It returns identifier of hashinfo.
If delimiter is "$" and identifier is "1", generated string is as follows.

    $1$(salt)$(hashed password)

=head2 hash : Object

It returns hash object.
In the current version, only Digest::SHA and Digest::SHA3 are allowed.

=head2 stretch_count : Int

It returns stretching count, and if has to be an integer bigger than 0.

=head2 format : String

It returns hash object.
In the current version, only "hex" and "base64" are allowed.

=head2 salt : String

It returns salt string.
It may be binary strings.
If delimiter is "$" ,identifier is "1", format is "base64", salt is "test12345" generated string is as follows.

    $1$dGVzdDEyMzQ1$(hashed password)

=head1 LICENSE

Copyright (C) Ryo Ito.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ryo Ito E<lt>ritou.06@gmail.comE<gt>

=cut

