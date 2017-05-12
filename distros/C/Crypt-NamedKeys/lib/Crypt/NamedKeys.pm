package Crypt::NamedKeys;

use strict;
use warnings;
use Moo;

=head1 NAME

Crypt::NamedKeys - A Crypt::CBC wrapper with key rotation support

=head1 SYNOPSYS

    use Crypt::NamedKeys;
    my $crypt = Crypt::NamedKeys->new(keyname => 'href');
    my $encrypted = $crypt->encrypt_data(data => $href);
    my $restored_href = $crypt->decrypt_data(
        data => $encrypted->{data},
        mac  => $encrypted->{mac},
    );

=head1 DESCRIPTION

This module provides functions to serialize data for transfer via non-protected
channels with encryption and data integrity protection.  The module tracks key
number used to encrypt information so that keys can be rotated without making
data unreadable.

=head1 CONFIGURATION AND KEY ROTATION

The keys are stored in the keyfile, configurable as below.  Keys are numbered
starting at 1.  Numbers must never be reused.  Typically key rotation will be
done in several steps, each with its own rollout.  These steps MUST be done as
separate releases because otherwise keys may not be available to decrypt data,
and so things may not work.

=head2 keyfile location

The keyfile can be set using the keyfile($path) function.  There is no default.

=head2 keyfile format

The format of the keyfile is YAML, following a basic structure of

 keyname:
    [keyhashdef]

so for example:

 cryptedfeed:
    default_keynum: 9
    none: queith7eeTh0teejaichoodobooX9ceechee9Sai9gauChiengaeraew3aDiehei
    1: aePh8ahBaNg1bee6ohj3er5cuzeepoophai1oogohpoixothah4AuYiongu4ahta
    2: oht1eep8uxoo1eeshaSaemee9aem5chahqueu0Aedaa7eeXae9aeghe5umoNah6a
    3: chigh4veifoofe0Vohphee4ohkaef9giz2iaje2ahF4ohboSh6ifaiNgohwohchi
    4: Ahphahmisaingo5Ietheangeegi5ia1uuF9taerooShaitoh1Eophig3ohziejet
    5: oe5wi2equee6FeiZohjah2peas6Ahquohniefeimai0beip2waxeizoo1OhthohN
    6: eigaezee3CeuC8phae4giph6Miqu6piy3Eideipahticesheij7se9eecai9fiez
    7: DuuGhohViGh0Sheihahr6ce4Phuin7ahpaiSa5jaiphie3eiz8oa3dohrohghuow
    8: ahfoniemah4boemeN8seJ7hohhualeetei7aegohhai5ohwahlohnah2Ee2Ewal1
    9: Ceixei4shelohxee1ohdoochuliebael1kae8eit0Geeth1so9fohZi0cohs8go4
    10: boreiDe0shueNgie7shai7ooc1yaeveiKeihuox0xahp1hai8phe7aephiel2oob

In general we assume key spefications to use numeric keys within the named
key hash.  This makes key rotation a lot easier and prevents reusing key
numbers.

Key names may not contain = or -.

All keys listed can be used for decryption (with the special 'none' key used if
no key number is specified in the cyphertex), but by default only the default
keynumber (default_keynum, in this case 9) is used for encrypting.

The keynumber is specified in the resulting cyphertext so we know which key
to use for decrypting the cyphertext even if we don't try to decrypt it.  This
allows:

=over

=item Key checking

If you store cyphertext in your rdbms, you can check which keys are used before
you remove decryption support for a key.

=item Orderly key rotation

You can add a key, and later depricate it, managing the transition (and perhaps
even using logging to know when the old key is no longer needed).

=back

=head2 Step 1:  Adding a New Key

In many cases you need to be able to add and remove keys without requiring that
everything gets the new keys at the same time.  For example if you have multiple
production systems, they are likely to get updated in series, and if you expect
that everyone gets the keys at the same time, timing issues may occur.

For this reason, we recommend breaking up the encryption key rollout into a
number of steps.  The first one is making sure that everyone can use the
new key to decrypt before anyone uses it to encrypt.

The first release is by adding a new key so that it is available for decryption.

For example, in the keyfile suppose one has:

  mykey:
    default_keynum: 1
    none: rsdfagtiaueIUPOIUYHH
    1: rsdfagtiaueIUPOIUYHH

We might add another line

    2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

Once this file is released, the key number 2 will be available globally for
decryption purposes, but everything will still be encrypted using key number 1.

This means it is safe then to go onto the second step.

=head2 Step 2:  Setting the new key as default

Once the new keys have been released, the next step is to change the default
keynumber.  Data encrypted in this way will be available even to servers waiting
to be updated because the keys have previously been rolled out.  To do this,
simply change the default_keynum:

  mykey:
    default_keynum: 1
    1: rsdfagtiaueIUPOIUYHH
    2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

becomes:

  mykey:
    default_keynum: 2
    1: rsdfagtiaueIUPOIUYHH
    2: IRvswqerituq-HPIOHJHGdeewrwyugfrGRSe3eyy6te

Now all new data will be encrypted using keynumber 2.

=head2 Step 3:  Retiring the old key

Once the old key is no longer being used, it can be retired by deleting the
row.

=head2 The Special 'none' keynum

For aes keys before the key versioning was introduced, there is no keynum
associated with the cyphertext, so we use this key.

=cut

use Carp;
use Crypt::CBC;
use Digest::SHA qw(hmac_sha256_base64 sha256);
use JSON;
use MIME::Base64;
use String::Compare::ConstantTime;
use Try::Tiny;
use YAML::XS;

our $VERSION = '1.1.2';

=head1 CONFIGURATION PARAMETERS

=head2 $Crypt::NamedKeys::Escape_Eq;

Set to true, using local or not, if you want to encode with - instead of =

Note that on decryption both are handled.

=cut

our $Escape_Eq = 0;

=head1 PROPERTIES

=head2 keynum

Defaults to the default keynumber specified in the keyfile (for encryption)

=cut

has keynum => (
    is      => 'ro',
    lazy    => 1,
    builder => '_default_keynum',
);

=head2 keyname

The name of the key in the keyfile.

=cut

has keyname => (
    is       => 'ro',
    required => 1,
);

my $keyfile;

=head1 METHODS AND FUNCTIONS

=cut

=head2 Crypt::NamedKeys->keyfile($path)

Can also be called as Crypt::NamedKeys::keyfile($path)

Sets the path of the keyfile.  It does not load or reload it (that is done on
demand or by reload_keyfile() below

=cut

sub keyfile {
    my $file = shift;
    $file = shift if $file eq __PACKAGE__;
    return $keyfile unless $file;
    $keyfile = $file;
    return $keyfile;
}

my $keyhash;

my $get_keyhash = sub {
    return $keyhash if $keyhash;
    reload_keyhash();
    return $keyhash;
};

=head2 reload_keyhash

Can be called as an object method or function (i.e.
Crypt::NamedKeys::reload_keyhash()

Loads or reloads the keyfile.  Can be used via event handlers to reload
confguration as needed

=cut

sub reload_keyhash {
    croak 'No keyfile defined (use keyfile() to set)' unless $keyfile;
    $keyhash = YAML::XS::LoadFile($keyfile);
    return scalar keys %$keyhash;
}

my $get_secret = sub {
    my %args = @_;
    croak 'No key name specified'   unless $args{keyname};
    croak 'No key number specified' unless $args{keynum};
    my $keytab = &$get_keyhash()->{$args{keyname}};
    return $keytab->{$args{keynum}};
};

sub _default_keynum {
    my $self   = shift;
    my $keytab = &$get_keyhash()->{$self->keyname};
    warn 'No default key found for ' . $self->keyname
        unless $keytab->{default_keynum};
    return $keytab->{default_keynum};
}

my $mac_secret = sub {
    my %args = @_;
    return sha256(&$get_secret(@_));    ## nocritic
};

=head2 $self->encrypt_data(data => $data)

Serialize I<$data> to JSON, encrypt it, and encode as base64. Also compute HMAC
code for the encrypted data. Returns hash reference with 'data' and 'mac'
elements.

Args include

=over

=item data

Data structure reference to be encrypted

=item cypher

Cypher to use (default: Rijndael)

=back

=cut

sub encrypt_data {
    my ($self, %args) = @_;
    croak "data argument is required and must be a reference" unless $args{data} and ref $args{data};
    my $json_data = encode_json($args{data});
    my $cypher = $args{cypher} || 'Rijndael';
    # Crypt::CBC generates random 8 bytes salt that it uses to
    # derive IV and encryption key from $args{secret}. It uses
    # the same algorythm as OpenSSL, the output is identical to
    # openssl enc -e -aes-256-cbc -k $args{secret} -salt
    my $cbc = Crypt::CBC->new(
        -key => &$get_secret(
            keyname => $self->keyname,
            keynum  => $self->keynum,
        ),
        -cipher => $cypher,
        -salt   => 1,
    );
    my $data = encode_base64($cbc->encrypt($json_data), '');
    my $mac = hmac_sha256_base64(
        $data,
        &$mac_secret(
            keyname => $self->keyname,
            keynum  => $self->keynum
        ));
    $data =~ s/=/-/g if $Escape_Eq;
    $mac =~ s/=/-/g  if $Escape_Eq;
    return {
        data => $self->keynum . '*' . $data,
        mac  => $mac,
    };
}

=head2 $self->decrypt_data(data => $data, mac => $mac)

Decrypt data encrypted using I<encrypt_data>. First checks HMAC code for data.
If data was not tampered, decrypts it and decodes from JSON. Returns data, or
undef if decryption failed.

=cut

sub decrypt_data {
    my ($self, %args) = @_;
    croak "method requires data and mac arguments" unless $args{data} and $args{mac};
    # if the data was tampered do not try to decrypt it

    $args{data} =~ s/-/=/g;
    $args{mac} =~ s/-/=/g;
    my ($keynum, $cyphertext) = split /\*/, $args{data}, 2;

    if (!$cyphertext) {
        $cyphertext = $keynum;
        $keynum     = 'none';
    }
    my $secret = &$get_secret(
        keynum  => $keynum,
        keyname => $self->keyname
    );
    return unless ($cyphertext and $secret);
    my $msg_mac = hmac_sha256_base64(
        $cyphertext,
        &$mac_secret(
            keynum  => $keynum,
            keyname => $self->keyname,
        ));
    return unless String::Compare::ConstantTime::equals($msg_mac, $args{mac});

    my $cbc = Crypt::CBC->new(
        -key => &$get_secret(
            keynum  => $keynum,
            keyname => $self->keyname
        ),
        -cipher => 'Rijndael',
        -salt   => 1,
    );
    my $decrypted = $cbc->decrypt(decode_base64($cyphertext));
    warn "Unable to decrypt $args{data} with keynum $keynum and keyname " . $self->keyname unless defined $decrypted;
    my $data = decode_json($decrypted);
    return $data;
}

=head2 $self->encrypt_payload(data  => $data)

Encrypts data using I<encrypt_data> and returns result as a string including
both cyphertext and hmac in base-64 format.  This can work on arbitrary data
structures, scalars, and references provided that the data can be serialized
as an attribute on a JSON document.

=cut

sub _to_payload {
    my ($data) = @_;
    return {
        crypt_json_payload => $data,
        crypt_json_version => $VERSION,
    };
}

sub _from_payload {
    my ($payload) = @_;
    return unless defined $payload;
    return $payload->{crypt_json_payload} if exists $payload->{crypt_json_payload};
    return $payload;
}

sub encrypt_payload {
    my ($self, %args) = @_;
    $args{data} = _to_payload($args{data});
    my $enc = $self->encrypt_data(%args);
    my $res = $enc->{data};
    $res .= '.' . $enc->{mac};
    return $res;
}

=head2 $self->decrypt_payload(value => $value)

Accepts payload encrypted with I<encrypt_payload>, checks HMAC and decrypts
the value. Returns decripted value or undef if check or decryption has failed.

=cut

sub decrypt_payload {
    my ($self, %args) = @_;
    return unless $args{value};    # nothing to decrypt
    $args{value} =~ /^([A-Za-z0-9+\/*]+[=-]*)\.([A-Za-z0-9+\/-=]+)$/ or return;
    my ($data, $mac) = ($1, $2);
    return _from_payload(
        $self->decrypt_data(
            data => $data,
            mac  => $mac,
        ));
}

1;
