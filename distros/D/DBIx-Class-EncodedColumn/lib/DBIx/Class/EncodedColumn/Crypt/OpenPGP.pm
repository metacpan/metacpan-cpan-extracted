package DBIx::Class::EncodedColumn::Crypt::OpenPGP;

use strict;
use warnings;

use Carp;
use Crypt::OpenPGP;

our $VERSION = '0.01';

=head1 NAME

DBIx::Class::EncodedColumn::Crypt::OpenPGP - Encrypt columns using Crypt::OpenPGP

=head1 SYNOPSIS

  __PACKAGE__->add_columns(
    'secret_data' => {
        data_type => 'TEXT',
        encode_column => 1,
        encode_class  => 'Crypt::OpenPGP',
        encode_args   => { 
            recipient => '7BEF6294',
        },
        encode_check_method => 'decrypt_data',
 };

 my $row = $schema->resultset('EncryptedClass')
                ->create({ secret_data => 'This is secret' });

 is(
    $row->decrypt_data('Private Key Passphrase'),
        'This is secret',
        'PGP/GPG Encryption works!'
 );

=head1 DESCRIPTION

This is a conduit to working with L<Crypt::OpenPGP>, so that you can encrypt 
data in your database using gpg.  Currently this module only handles encrypting
but it may add signing of columns in the future 

=head1 CONFIGURATION

In the column definition, specify the C<encode_args> hash as listed in the
synopsis.  The C<recipient> is required if doing key exchange encryption, or
if you want to use symmetric key encryption using a passphrase you can
specify a C<passphrase> option:

 encode_args => { passphrase => "Shared Secret" }

If you have a separate path to your public and private key ring file, or if you
have alternative L<Crypt::OpenPGP> configuration, you can specify the
constructor args using the C<pgp_args> configuration key:
 
    encode_args => {
        pgp_args => {
            SecRing => "$FindBin::Bin/var/secring.gpg",
            PubRing => "$FindBin::Bin/var/pubring.gpg",
        }
    }

The included tests cover good usage, and it is advised to briefly browse through
them.

Also, remember to keep your private keys secure!

=cut

my %VALID_ENCODE_ARGS = (
    'compat'   => 'Compat',
    'cipher'   => 'Cipher',
    'compress' => 'Compress',
    'mdc'      => 'MDC',
);

sub make_encode_sub {
    my ( $class, $col, $args ) = @_;

    my ( $method, $method_arg );

    my $armour = defined $args->{armour} ? $args->{armour} : 0;
    if ( defined $args->{passphrase} ) {
        $method     = 'Passphrase';
        $method_arg = $args->{passphrase};
    } elsif ( defined $args->{recipient} ) {
        $method     = 'Recipients';
        $method_arg = $args->{recipient};
    }

    my @other;
    for my $opt (keys %VALID_ENCODE_ARGS) {
        if ( defined $args->{$opt} ) {
            push @other, $VALID_ENCODE_ARGS{$opt} => $args->{$opt};
        }
    }

    my $pgp = _get_pgp_obj_from_args($args);

    my $encoder = sub {
        my ( $plain_text, $settings ) = @_;
        my $val = $pgp->encrypt(
            Data        => $plain_text,
            $method     => $method_arg,
            Armour      => $armour,
            @other,
        );
        croak "Unable to encrypt $col; check $method parameter (is $method_arg) (and that the key is known)" unless $val;
        return $val;
    };
    return $encoder;
}

sub make_check_sub {
    my ( $class, $col, $args ) = @_;

    my $pgp = _get_pgp_obj_from_args($args);

    return sub {
        my ( $self, $passphrase ) = @_;
        my $text = $self->get_column($col);
        my @res;
        if ( defined $passphrase ) {
            @res = $pgp->decrypt( Passphrase => $passphrase, Data => $text );
        } else {
            @res = $pgp->decrypt( Data => $text );
        }
        croak $pgp->errstr unless $res[0];

        # Handle additional stuff in $res[1] and [2]?
        return $res[0];
    };
}

sub _get_pgp_obj_from_args {
    my ( $args ) = @_;
    my $pgp;
    if ( $args->{pgp_args} and ref $args->{pgp_args} eq 'HASH' ) {
        $pgp = Crypt::OpenPGP->new( %{ $args->{pgp_args} } );
    }
    elsif ( $args->{pgp_object} and 
            $args->{pgp_object}->isa('Crypt::OpenPGP') 
    ) {
        $pgp = $args->{pgp_object};
    } else {
        $pgp = Crypt::OpenPGP->new;
    }
    croak "Unable to get initialize a Crypt::OpenPGP object" unless $pgp;

    return $pgp;
}

=head1 AUTHOR

J. Shirley <cpan@coldhardcode.com>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


1;
