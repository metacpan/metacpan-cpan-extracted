# Copyright (c) 2015 Jerry Lundström <lundstrom.jerry@gmail.com>
# Copyright (c) 2015 .SE (The Internet Infrastructure Foundation)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package Crypt::PKCS11::Attributes;

use common::sense;
use Carp;
use Scalar::Util qw(blessed);

use Crypt::PKCS11 qw(:constant);
use Crypt::PKCS11::Attribute::Value;

our %ATTRIBUTE_MAP = (
    CKA_CLASS() => 'Crypt::PKCS11::Attribute::Class',
    CKA_TOKEN() => 'Crypt::PKCS11::Attribute::Token',
    CKA_PRIVATE() => 'Crypt::PKCS11::Attribute::Private',
    CKA_LABEL() => 'Crypt::PKCS11::Attribute::Label',
    CKA_APPLICATION() => 'Crypt::PKCS11::Attribute::Application',
    CKA_VALUE() => 'Crypt::PKCS11::Attribute::Value',
    CKA_OBJECT_ID() => 'Crypt::PKCS11::Attribute::ObjectId',
    CKA_CERTIFICATE_TYPE() => 'Crypt::PKCS11::Attribute::CertificateType',
    CKA_ISSUER() => 'Crypt::PKCS11::Attribute::Issuer',
    CKA_SERIAL_NUMBER() => 'Crypt::PKCS11::Attribute::SerialNumber',
    CKA_AC_ISSUER() => 'Crypt::PKCS11::Attribute::AcIssuer',
    CKA_OWNER() => 'Crypt::PKCS11::Attribute::Owner',
    CKA_ATTR_TYPES() => 'Crypt::PKCS11::Attribute::AttrTypes',
    CKA_TRUSTED() => 'Crypt::PKCS11::Attribute::Trusted',
    CKA_CERTIFICATE_CATEGORY() => 'Crypt::PKCS11::Attribute::CertificateCategory',
    CKA_JAVA_MIDP_SECURITY_DOMAIN() => 'Crypt::PKCS11::Attribute::JavaMidpSecurityDomain',
    CKA_URL() => 'Crypt::PKCS11::Attribute::Url',
    CKA_HASH_OF_SUBJECT_PUBLIC_KEY() => 'Crypt::PKCS11::Attribute::HashOfSubjectPublicKey',
    CKA_HASH_OF_ISSUER_PUBLIC_KEY() => 'Crypt::PKCS11::Attribute::HashOfIssuerPublicKey',
    CKA_NAME_HASH_ALGORITHM() => 'Crypt::PKCS11::Attribute::NameHashAlgorithm',
    CKA_CHECK_VALUE() => 'Crypt::PKCS11::Attribute::CheckValue',
    CKA_KEY_TYPE() => 'Crypt::PKCS11::Attribute::KeyType',
    CKA_SUBJECT() => 'Crypt::PKCS11::Attribute::Subject',
    CKA_ID() => 'Crypt::PKCS11::Attribute::Id',
    CKA_SENSITIVE() => 'Crypt::PKCS11::Attribute::Sensitive',
    CKA_ENCRYPT() => 'Crypt::PKCS11::Attribute::Encrypt',
    CKA_DECRYPT() => 'Crypt::PKCS11::Attribute::Decrypt',
    CKA_WRAP() => 'Crypt::PKCS11::Attribute::Wrap',
    CKA_UNWRAP() => 'Crypt::PKCS11::Attribute::Unwrap',
    CKA_SIGN() => 'Crypt::PKCS11::Attribute::Sign',
    CKA_SIGN_RECOVER() => 'Crypt::PKCS11::Attribute::SignRecover',
    CKA_VERIFY() => 'Crypt::PKCS11::Attribute::Verify',
    CKA_VERIFY_RECOVER() => 'Crypt::PKCS11::Attribute::VerifyRecover',
    CKA_DERIVE() => 'Crypt::PKCS11::Attribute::Derive',
    CKA_START_DATE() => 'Crypt::PKCS11::Attribute::StartDate',
    CKA_END_DATE() => 'Crypt::PKCS11::Attribute::EndDate',
    CKA_MODULUS() => 'Crypt::PKCS11::Attribute::Modulus',
    CKA_MODULUS_BITS() => 'Crypt::PKCS11::Attribute::ModulusBits',
    CKA_PUBLIC_EXPONENT() => 'Crypt::PKCS11::Attribute::PublicExponent',
    CKA_PRIVATE_EXPONENT() => 'Crypt::PKCS11::Attribute::PrivateExponent',
    CKA_PRIME_1() => 'Crypt::PKCS11::Attribute::Prime1',
    CKA_PRIME_2() => 'Crypt::PKCS11::Attribute::Prime2',
    CKA_EXPONENT_1() => 'Crypt::PKCS11::Attribute::Exponent1',
    CKA_EXPONENT_2() => 'Crypt::PKCS11::Attribute::Exponent2',
    CKA_COEFFICIENT() => 'Crypt::PKCS11::Attribute::Coefficient',
    CKA_PRIME() => 'Crypt::PKCS11::Attribute::Prime',
    CKA_SUBPRIME() => 'Crypt::PKCS11::Attribute::Subprime',
    CKA_BASE() => 'Crypt::PKCS11::Attribute::Base',
    CKA_PRIME_BITS() => 'Crypt::PKCS11::Attribute::PrimeBits',
    CKA_SUBPRIME_BITS() => 'Crypt::PKCS11::Attribute::Subprime::Bits',
    CKA_SUB_PRIME_BITS() => 'Crypt::PKCS11::Attribute::SubPrimeBits',
    CKA_VALUE_BITS() => 'Crypt::PKCS11::Attribute::ValueBits',
    CKA_VALUE_LEN() => 'Crypt::PKCS11::Attribute::ValueLen',
    CKA_EXTRACTABLE() => 'Crypt::PKCS11::Attribute::Extractable',
    CKA_LOCAL() => 'Crypt::PKCS11::Attribute::Local',
    CKA_NEVER_EXTRACTABLE() => 'Crypt::PKCS11::Attribute::NeverExtractable',
    CKA_ALWAYS_SENSITIVE() => 'Crypt::PKCS11::Attribute::AlwaysSensitive',
    CKA_KEY_GEN_MECHANISM() => 'Crypt::PKCS11::Attribute::KeyGenMechanism',
    CKA_MODIFIABLE() => 'Crypt::PKCS11::Attribute::Modifiable',
    CKA_COPYABLE() => 'Crypt::PKCS11::Attribute::Copyable',
    CKA_ECDSA_PARAMS() => 'Crypt::PKCS11::Attribute::EcdsaParams',
    CKA_EC_PARAMS() => 'Crypt::PKCS11::Attribute::EcParams',
    CKA_EC_POINT() => 'Crypt::PKCS11::Attribute::EcPoint',
    CKA_SECONDARY_AUTH() => 'Crypt::PKCS11::Attribute::SecondaryAuth',
    CKA_AUTH_PIN_FLAGS() => 'Crypt::PKCS11::Attribute::AuthPinFlags',
    CKA_ALWAYS_AUTHENTICATE() => 'Crypt::PKCS11::Attribute::AlwaysAuthenticate',
    CKA_WRAP_WITH_TRUSTED() => 'Crypt::PKCS11::Attribute::WrapWithTrusted',
    CKA_WRAP_TEMPLATE() => 'Crypt::PKCS11::Attribute::WrapTemplate',
    CKA_UNWRAP_TEMPLATE() => 'Crypt::PKCS11::Attribute::UnwrapTemplate',
    CKA_DERIVE_TEMPLATE() => 'Crypt::PKCS11::Attribute::DeriveTemplate',
    CKA_OTP_FORMAT() => 'Crypt::PKCS11::Attribute::OtpFormat',
    CKA_OTP_LENGTH() => 'Crypt::PKCS11::Attribute::OtpLength',
    CKA_OTP_TIME_INTERVAL() => 'Crypt::PKCS11::Attribute::OtpTimeInterval',
    CKA_OTP_USER_FRIENDLY_MODE() => 'Crypt::PKCS11::Attribute::OtpUserFriendlyMode',
    CKA_OTP_CHALLENGE_REQUIREMENT() => 'Crypt::PKCS11::Attribute::OtpChallengeRequirement',
    CKA_OTP_TIME_REQUIREMENT() => 'Crypt::PKCS11::Attribute::OtpTimeRequirement',
    CKA_OTP_COUNTER_REQUIREMENT() => 'Crypt::PKCS11::Attribute::OtpCounterRequirement',
    CKA_OTP_PIN_REQUIREMENT() => 'Crypt::PKCS11::Attribute::OtpPinRequirement',
    CKA_OTP_COUNTER() => 'Crypt::PKCS11::Attribute::OtpCounter',
    CKA_OTP_TIME() => 'Crypt::PKCS11::Attribute::OtpTime',
    CKA_OTP_USER_IDENTIFIER() => 'Crypt::PKCS11::Attribute::OtpUserIdentifier',
    CKA_OTP_SERVICE_IDENTIFIER() => 'Crypt::PKCS11::Attribute::OtpServiceIdentifier',
    CKA_OTP_SERVICE_LOGO() => 'Crypt::PKCS11::Attribute::OtpServiceLogo',
    CKA_OTP_SERVICE_LOGO_TYPE() => 'Crypt::PKCS11::Attribute::OtpServiceLogoType',
    CKA_GOSTR3410_PARAMS() => 'Crypt::PKCS11::Attribute::Gostr3410Params',
    CKA_GOSTR3411_PARAMS() => 'Crypt::PKCS11::Attribute::Gostr3411Params',
    CKA_GOST28147_PARAMS() => 'Crypt::PKCS11::Attribute::Gost28147Params',
    CKA_HW_FEATURE_TYPE() => 'Crypt::PKCS11::Attribute::HwFeatureType',
    CKA_RESET_ON_INIT() => 'Crypt::PKCS11::Attribute::ResetOnInit',
    CKA_HAS_RESET() => 'Crypt::PKCS11::Attribute::HasReset',
    CKA_PIXEL_X() => 'Crypt::PKCS11::Attribute::PixelX',
    CKA_PIXEL_Y() => 'Crypt::PKCS11::Attribute::PixelY',
    CKA_RESOLUTION() => 'Crypt::PKCS11::Attribute::Resolution',
    CKA_CHAR_ROWS() => 'Crypt::PKCS11::Attribute::CharRows',
    CKA_CHAR_COLUMNS() => 'Crypt::PKCS11::Attribute::CharColumns',
    CKA_COLOR() => 'Crypt::PKCS11::Attribute::Color',
    CKA_BITS_PER_PIXEL() => 'Crypt::PKCS11::Attribute::BitsPerPixel',
    CKA_CHAR_SETS() => 'Crypt::PKCS11::Attribute::CharSets',
    CKA_ENCODING_METHODS() => 'Crypt::PKCS11::Attribute::EncodingMethods',
    CKA_MIME_TYPES() => 'Crypt::PKCS11::Attribute::MimeTypes',
    CKA_MECHANISM_TYPE() => 'Crypt::PKCS11::Attribute::MechanismType',
    CKA_REQUIRED_CMS_ATTRIBUTES() => 'Crypt::PKCS11::Attribute::RequiredCmsAttributes',
    CKA_DEFAULT_CMS_ATTRIBUTES() => 'Crypt::PKCS11::Attribute::DefaultCmsAttributes',
    CKA_SUPPORTED_CMS_ATTRIBUTES() => 'Crypt::PKCS11::Attribute::SupportedCmsAttributes',
    CKA_ALLOWED_MECHANISMS() => 'Crypt::PKCS11::Attribute::AllowedMechanisms',
    CKA_VENDOR_DEFINED() => 'Crypt::PKCS11::Attribute::VendorDefined',
);

sub new {
    my $this = CORE::shift;
    my $class = ref($this) || $this;
    my $self = {
        attributes => []
    };
    bless $self, $class;

    return $self;
}

sub push {
    my ($self) = CORE::shift;

    CORE::foreach (@_) {
        unless (blessed($_) and $_->isa('Crypt::PKCS11::Attribute')) {
            confess 'Value to push is not a Crypt::PKCS11::Attribute object';
        }
    }
    CORE::push(@{$self->{attributes}}, @_);

    return $self;
}

sub pop {
    return CORE::pop(@{$_[0]->{attributes}});
}

sub shift {
    return CORE::shift(@{$_[0]->{attributes}});
}

sub unshift {
    my ($self) = CORE::shift;

    CORE::foreach (@_) {
        unless (blessed($_) and $_->isa('Crypt::PKCS11::Attribute')) {
            confess 'Value to unshift is not a Crypt::PKCS11::Attribute object';
        }
    }
    CORE::unshift(@{$self->{attributes}}, @_);

    return $self;
}

sub foreach {
    my ($self, $cb) = @_;

    unless (ref($cb) eq 'CODE') {
        confess '$cb argument is not CODE';
    }
    CORE::foreach (@{$self->{attributes}}) {
        $cb->($_);
    }

    return $self;
}

sub toArray {
    my ($self) = @_;
    my @array;

    CORE::foreach (@{$self->{attributes}}) {
        CORE::push(@array, { type => $_->type, pValue => $_->pValue });
    }

    return \@array;
}

sub fromArray {
    my ($self, $array) = @_;
    my @attributes;

    unless (ref($array) eq 'ARRAY') {
        confess '$array argument is not ARRAY';
    }

    CORE::foreach (@{$array}) {
        unless (ref($_) eq 'HASH'
            and defined($_->{type})
            and defined($_->{pValue})
            and exists($ATTRIBUTE_MAP{$_->{type}}))
        {
            confess 'invalid $array';
        }

        my $attribute = $ATTRIBUTE_MAP{$_->{type}}->new;
        $attribute->{pValue} = $_->{pValue};
        CORE::push(@attributes, $attribute);
    }

    $self->{attributes} = \@attributes;

    return $self;
}

sub all {
    return @{$_[0]->{attributes}};
}

package Crypt::PKCS11::Attribute::Class;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CLASS }

package Crypt::PKCS11::Attribute::Token;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_TOKEN }

package Crypt::PKCS11::Attribute::Private;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIVATE }

package Crypt::PKCS11::Attribute::Label;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_LABEL }

package Crypt::PKCS11::Attribute::Application;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_APPLICATION }

package Crypt::PKCS11::Attribute::ObjectId;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OBJECT_ID }

package Crypt::PKCS11::Attribute::CertificateType;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CERTIFICATE_TYPE }

package Crypt::PKCS11::Attribute::Issuer;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ISSUER }

package Crypt::PKCS11::Attribute::SerialNumber;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SERIAL_NUMBER }

package Crypt::PKCS11::Attribute::AcIssuer;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_AC_ISSUER }

package Crypt::PKCS11::Attribute::Owner;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OWNER }

package Crypt::PKCS11::Attribute::AttrTypes;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ATTR_TYPES }

package Crypt::PKCS11::Attribute::Trusted;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_TRUSTED }

package Crypt::PKCS11::Attribute::CertificateCategory;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CERTIFICATE_CATEGORY }

package Crypt::PKCS11::Attribute::JavaMidpSecurityDomain;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_JAVA_MIDP_SECURITY_DOMAIN }

package Crypt::PKCS11::Attribute::Url;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_URL }

package Crypt::PKCS11::Attribute::HashOfSubjectPublicKey;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_HASH_OF_SUBJECT_PUBLIC_KEY }

package Crypt::PKCS11::Attribute::HashOfIssuerPublicKey;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_HASH_OF_ISSUER_PUBLIC_KEY }

package Crypt::PKCS11::Attribute::NameHashAlgorithm;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_NAME_HASH_ALGORITHM }

package Crypt::PKCS11::Attribute::CheckValue;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CHECK_VALUE }

package Crypt::PKCS11::Attribute::KeyType;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_KEY_TYPE }

package Crypt::PKCS11::Attribute::Subject;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SUBJECT }

package Crypt::PKCS11::Attribute::Id;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ID }

package Crypt::PKCS11::Attribute::Sensitive;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SENSITIVE }

package Crypt::PKCS11::Attribute::Encrypt;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ENCRYPT }

package Crypt::PKCS11::Attribute::Decrypt;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_DECRYPT }

package Crypt::PKCS11::Attribute::Wrap;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_WRAP }

package Crypt::PKCS11::Attribute::Unwrap;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_UNWRAP }

package Crypt::PKCS11::Attribute::Sign;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SIGN }

package Crypt::PKCS11::Attribute::SignRecover;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SIGN_RECOVER }

package Crypt::PKCS11::Attribute::Verify;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_VERIFY }

package Crypt::PKCS11::Attribute::VerifyRecover;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_VERIFY_RECOVER }

package Crypt::PKCS11::Attribute::Derive;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_DERIVE }

package Crypt::PKCS11::Attribute::StartDate;
use base qw(Crypt::PKCS11::Attribute::CK_DATE);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_START_DATE }

package Crypt::PKCS11::Attribute::EndDate;
use base qw(Crypt::PKCS11::Attribute::CK_DATE);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_END_DATE }

package Crypt::PKCS11::Attribute::Modulus;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_MODULUS }

package Crypt::PKCS11::Attribute::ModulusBits;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_MODULUS_BITS }

package Crypt::PKCS11::Attribute::PublicExponent;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PUBLIC_EXPONENT }

package Crypt::PKCS11::Attribute::PrivateExponent;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIVATE_EXPONENT }

package Crypt::PKCS11::Attribute::Prime1;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIME_1 }

package Crypt::PKCS11::Attribute::Prime2;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIME_2 }

package Crypt::PKCS11::Attribute::Exponent1;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_EXPONENT_1 }

package Crypt::PKCS11::Attribute::Exponent2;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_EXPONENT_2 }

package Crypt::PKCS11::Attribute::Coefficient;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_COEFFICIENT }

package Crypt::PKCS11::Attribute::Prime;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIME }

package Crypt::PKCS11::Attribute::Subprime;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SUBPRIME }

package Crypt::PKCS11::Attribute::Base;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_BASE }

package Crypt::PKCS11::Attribute::PrimeBits;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PRIME_BITS }

package Crypt::PKCS11::Attribute::Subprime::Bits;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SUBPRIME_BITS }

package Crypt::PKCS11::Attribute::SubPrimeBits;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SUB_PRIME_BITS }

package Crypt::PKCS11::Attribute::ValueBits;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_VALUE_BITS }

package Crypt::PKCS11::Attribute::ValueLen;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_VALUE_LEN }

package Crypt::PKCS11::Attribute::Extractable;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_EXTRACTABLE }

package Crypt::PKCS11::Attribute::Local;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_LOCAL }

package Crypt::PKCS11::Attribute::NeverExtractable;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_NEVER_EXTRACTABLE }

package Crypt::PKCS11::Attribute::AlwaysSensitive;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ALWAYS_SENSITIVE }

package Crypt::PKCS11::Attribute::KeyGenMechanism;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_KEY_GEN_MECHANISM }

package Crypt::PKCS11::Attribute::Modifiable;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_MODIFIABLE }

package Crypt::PKCS11::Attribute::Copyable;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_COPYABLE }

package Crypt::PKCS11::Attribute::EcdsaParams;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ECDSA_PARAMS }

package Crypt::PKCS11::Attribute::EcParams;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_EC_PARAMS }

package Crypt::PKCS11::Attribute::EcPoint;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_EC_POINT }

package Crypt::PKCS11::Attribute::SecondaryAuth;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SECONDARY_AUTH }

package Crypt::PKCS11::Attribute::AuthPinFlags;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_AUTH_PIN_FLAGS }

package Crypt::PKCS11::Attribute::AlwaysAuthenticate;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ALWAYS_AUTHENTICATE }

package Crypt::PKCS11::Attribute::WrapWithTrusted;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_WRAP_WITH_TRUSTED }

package Crypt::PKCS11::Attribute::WrapTemplate;
use base qw(Crypt::PKCS11::Attribute::AttributeArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_WRAP_TEMPLATE }

package Crypt::PKCS11::Attribute::UnwrapTemplate;
use base qw(Crypt::PKCS11::Attribute::AttributeArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_UNWRAP_TEMPLATE }

package Crypt::PKCS11::Attribute::DeriveTemplate;
use base qw(Crypt::PKCS11::Attribute::AttributeArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_DERIVE_TEMPLATE }

package Crypt::PKCS11::Attribute::OtpFormat;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_FORMAT }

package Crypt::PKCS11::Attribute::OtpLength;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_LENGTH }

package Crypt::PKCS11::Attribute::OtpTimeInterval;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_TIME_INTERVAL }

package Crypt::PKCS11::Attribute::OtpUserFriendlyMode;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_USER_FRIENDLY_MODE }

package Crypt::PKCS11::Attribute::OtpChallengeRequirement;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_CHALLENGE_REQUIREMENT }

package Crypt::PKCS11::Attribute::OtpTimeRequirement;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_TIME_REQUIREMENT }

package Crypt::PKCS11::Attribute::OtpCounterRequirement;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_COUNTER_REQUIREMENT }

package Crypt::PKCS11::Attribute::OtpPinRequirement;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_PIN_REQUIREMENT }

package Crypt::PKCS11::Attribute::OtpCounter;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_COUNTER }

package Crypt::PKCS11::Attribute::OtpTime;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_TIME }

package Crypt::PKCS11::Attribute::OtpUserIdentifier;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_USER_IDENTIFIER }

package Crypt::PKCS11::Attribute::OtpServiceIdentifier;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_SERVICE_IDENTIFIER }

package Crypt::PKCS11::Attribute::OtpServiceLogo;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_SERVICE_LOGO }

package Crypt::PKCS11::Attribute::OtpServiceLogoType;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_OTP_SERVICE_LOGO_TYPE }

package Crypt::PKCS11::Attribute::Gostr3410Params;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_GOSTR3410_PARAMS }

package Crypt::PKCS11::Attribute::Gostr3411Params;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_GOSTR3411_PARAMS }

package Crypt::PKCS11::Attribute::Gost28147Params;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_GOST28147_PARAMS }

package Crypt::PKCS11::Attribute::HwFeatureType;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_HW_FEATURE_TYPE }

package Crypt::PKCS11::Attribute::ResetOnInit;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_RESET_ON_INIT }

package Crypt::PKCS11::Attribute::HasReset;
use base qw(Crypt::PKCS11::Attribute::CK_BBOOL);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_HAS_RESET }

package Crypt::PKCS11::Attribute::PixelX;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PIXEL_X }

package Crypt::PKCS11::Attribute::PixelY;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_PIXEL_Y }

package Crypt::PKCS11::Attribute::Resolution;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_RESOLUTION }

package Crypt::PKCS11::Attribute::CharRows;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CHAR_ROWS }

package Crypt::PKCS11::Attribute::CharColumns;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CHAR_COLUMNS }

package Crypt::PKCS11::Attribute::Color;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_COLOR }

package Crypt::PKCS11::Attribute::BitsPerPixel;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_BITS_PER_PIXEL }

package Crypt::PKCS11::Attribute::CharSets;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_CHAR_SETS }

package Crypt::PKCS11::Attribute::EncodingMethods;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ENCODING_METHODS }

package Crypt::PKCS11::Attribute::MimeTypes;
use base qw(Crypt::PKCS11::Attribute::RFC2279string);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_MIME_TYPES }

package Crypt::PKCS11::Attribute::MechanismType;
use base qw(Crypt::PKCS11::Attribute::CK_ULONG);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_MECHANISM_TYPE }

package Crypt::PKCS11::Attribute::RequiredCmsAttributes;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_REQUIRED_CMS_ATTRIBUTES }

package Crypt::PKCS11::Attribute::DefaultCmsAttributes;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_DEFAULT_CMS_ATTRIBUTES }

package Crypt::PKCS11::Attribute::SupportedCmsAttributes;
use base qw(Crypt::PKCS11::Attribute::ByteArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_SUPPORTED_CMS_ATTRIBUTES }

package Crypt::PKCS11::Attribute::AllowedMechanisms;
use base qw(Crypt::PKCS11::Attribute::UlongArray);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_ALLOWED_MECHANISMS }

package Crypt::PKCS11::Attribute::VendorDefined;
use base qw(Crypt::PKCS11::Attribute::CK_BYTE);
use Crypt::PKCS11 qw(:constant);
sub type () { CKA_VENDOR_DEFINED }

1;

__END__
