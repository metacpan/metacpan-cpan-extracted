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

package Crypt::PKCS11::Session;

use common::sense;
use Carp;
use Scalar::Util qw(blessed);

use Crypt::PKCS11 qw(:constant);
use Crypt::PKCS11::Object;

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {
        pkcs11xs => undef,
        session => undef,
        rv => CKR_OK
    };
    bless $self, $class;

    unless (blessed($self->{pkcs11xs} = shift) and $self->{pkcs11xs}->isa('Crypt::PKCS11::XSPtr')) {
        delete $self->{pkcs11xs};
        confess 'first argument is not a Crypt::PKCS11::XSPtr';
    }
    unless (defined ($self->{session} = shift)) {
        delete $self->{pkcs11xs};
        delete $self->{session};
        confess 'second argument is not a session';
    }

    return $self;
}

sub DESTROY {
    if (exists $_[0]->{session} and defined $_[0]->{pkcs11xs}) {
        $_[0]->{pkcs11xs}->C_CloseSession($_[0]->{session});
    }
}

sub InitPIN {
    my ($self, $pin) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    if (defined $pin) {
        $pin .= '';
        unless (length($pin)) {
            confess '$pin can not be empty if defined';
        }
    }

    $self->{rv} = $self->{pkcs11xs}->C_InitPIN($self->{session}, $pin);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub SetPIN {
    my ($self, $oldPin, $newPin) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    if (defined $oldPin) {
        $oldPin .= '';
        unless (length($oldPin)) {
            confess '$oldPin can not be empty if defined';
        }
    }
    if (defined $newPin) {
        $newPin .= '';
        unless (length($newPin)) {
            confess '$newPin can not be empty if defined';
        }
    }

    $self->{rv} = $self->{pkcs11xs}->C_SetPIN($self->{session}, $oldPin, $newPin);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub CloseSession {
    my ($self) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_CloseSession($self->{session});
    if ($self->{rv} == CKR_OK) {
        delete $self->{session};
    }
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub GetSessionInfo {
    my ($self) = @_;
    my $info = {};

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GetSessionInfo($self->{session}, $info);

    unless (ref($info) eq 'HASH') {
        confess 'Internal Error: $info is not a hash reference';
    }

    return $self->{rv} == CKR_OK ? wantarray ? %$info : $info : undef;
}

sub GetOperationState {
    my ($self) = @_;
    my $operationState;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GetOperationState($self->{session}, $operationState);
    return $self->{rv} == CKR_OK ? $operationState : undef;
}

sub SetOperationState {
    my ($self, $operationState, $encryptionKey, $authenticationKey) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $operationState) {
        confess '$operationState must be defined';
    }
    if (defined $encryptionKey) {
        unless (blessed($encryptionKey) and $encryptionKey->isa('Crypt::PKCS11::Object')) {
            confess '$encryptionKey is defined but is not a Crypt::PKCS11::Object';
        }
    }
    if (defined $authenticationKey) {
        unless (blessed($authenticationKey) and $authenticationKey->isa('Crypt::PKCS11::Object')) {
            confess '$authenticationKey is defined but is not a Crypt::PKCS11::Object';
        }
    }

    $self->{rv} = $self->{pkcs11xs}->C_SetOperationState($self->{session}, $operationState, $encryptionKey ? $encryptionKey->id : 0, $authenticationKey ? $authenticationKey->id : 0);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Login {
    my ($self, $userType, $pin) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $userType) {
        confess '$userType must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Login($self->{session}, $userType, $pin);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Logout {
    my ($self) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Logout($self->{session});
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub CreateObject {
    my ($self, $template) = @_;
    my $object;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_CreateObject($self->{session}, $template->toArray, $object);
    return $self->{rv} == CKR_OK ? Crypt::PKCS11::Object->new($object) : undef;
}

sub CopyObject {
    my ($self, $object, $template) = @_;
    my $newObject;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($object) and $object->isa('Crypt::PKCS11::Object')) {
        confess '$object is not a Crypt::PKCS11::Object';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_CopyObject($self->{session}, $object->id, $template->toArray, $newObject);
    return $self->{rv} == CKR_OK ? Crypt::PKCS11::Object->new($newObject) : undef;
}

sub DestroyObject {
    my ($self, $object) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($object) and $object->isa('Crypt::PKCS11::Object')) {
        confess '$object is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DestroyObject($self->{session}, $object->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub GetObjectSize {
    my ($self, $object) = @_;
    my $size;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($object) and $object->isa('Crypt::PKCS11::Object')) {
        confess '$object is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GetObjectSize($self->{session}, $object->id, $size);
    return $self->{rv} == CKR_OK ? $size : undef;
}

sub GetAttributeValue {
    my ($self, $object, $template) = @_;
    my $templateArray;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($object) and $object->isa('Crypt::PKCS11::Object')) {
        confess '$object is not a Crypt::PKCS11::Object';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GetAttributeValue($self->{session}, $object->id, $templateArray = $template->toArray);

    if ($self->{rv} == CKR_OK) {
        $template->fromArray($templateArray);
        return wantarray ? $template->all : 1;
    }

    return undef;
}

sub SetAttributeValue {
    my ($self, $object, $template) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($object) and $object->isa('Crypt::PKCS11::Object')) {
        confess '$object is not a Crypt::PKCS11::Object';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SetAttributeValue($self->{session}, $object->id, $template->toArray);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub FindObjectsInit {
    my ($self, $template) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_FindObjectsInit($self->{session}, $template->toArray);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub FindObjects {
    my ($self, $maxObjectCount) = @_;
    my $objects = [];
    my @objects;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $maxObjectCount) {
        confess '$maxObjectCount must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_FindObjects($self->{session}, $objects, $maxObjectCount);

    unless (ref($objects) eq 'ARRAY') {
        confess 'Internal Error: $objects is not an array reference';
    }

    foreach my $object (@$objects) {
        push(@objects, Crypt::PKCS11::Object->new($object));
    }

    return $self->{rv} == CKR_OK ? wantarray ? @objects : \@objects : undef;
}

sub FindObjectsFinal {
    my ($self) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_FindObjectsFinal($self->{session});
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub EncryptInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_EncryptInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Encrypt {
    my ($self, $data) = @_;
    my $encryptedData;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $data) {
        confess '$data must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Encrypt($self->{session}, $data, $encryptedData);
    return $self->{rv} == CKR_OK ? $encryptedData : undef;
}

sub EncryptUpdate {
    my ($self, $part) = @_;
    my $encryptedPart;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_EncryptUpdate($self->{session}, $part, $encryptedPart);
    return $self->{rv} == CKR_OK ? $encryptedPart : undef;
}

sub EncryptFinal {
    my ($self) = @_;
    my $lastEncryptedPart;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_EncryptFinal($self->{session}, $lastEncryptedPart);
    return $self->{rv} == CKR_OK ? $lastEncryptedPart : undef;
}

sub DecryptInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DecryptInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Decrypt {
    my ($self, $encryptedData) = @_;
    my $data;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $encryptedData) {
        confess '$encryptedData must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Decrypt($self->{session}, $encryptedData, $data);
    return $self->{rv} == CKR_OK ? $data : undef;
}

sub DecryptUpdate {
    my ($self, $encryptedPart) = @_;
    my $part;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $encryptedPart) {
        confess '$encryptedPart must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DecryptUpdate($self->{session}, $encryptedPart, $part);
    return $self->{rv} == CKR_OK ? $part : undef;
}

sub DecryptFinal {
    my ($self) = @_;
    my $lastPart;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DecryptFinal($self->{session}, $lastPart);
    return $self->{rv} == CKR_OK ? $lastPart : undef;
}

sub DigestInit {
    my ($self, $mechanism) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DigestInit($self->{session}, $mechanism->toHash);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Digest {
    my ($self, $data) = @_;
    my $digest;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $data) {
        confess '$data must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Digest($self->{session}, $data, $digest);
    return $self->{rv} == CKR_OK ? $digest : undef;
}

sub DigestUpdate {
    my ($self, $part) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DigestUpdate($self->{session}, $part);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub DigestKey {
    my ($self, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DigestKey($self->{session}, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub DigestFinal {
    my ($self) = @_;
    my $digest;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DigestFinal($self->{session}, $digest);
    return $self->{rv} == CKR_OK ? $digest : undef;
}

sub SignInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Sign {
    my ($self, $data) = @_;
    my $signature;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $data) {
        confess '$data must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Sign($self->{session}, $data, $signature);
    return $self->{rv} == CKR_OK ? $signature : undef;
}

sub SignUpdate {
    my ($self, $part) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignUpdate($self->{session}, $part);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub SignFinal {
    my ($self) = @_;
    my $signature;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignFinal($self->{session}, $signature);
    return $self->{rv} == CKR_OK ? $signature : undef;
}

sub SignRecoverInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignRecoverInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub SignRecover {
    my ($self, $data) = @_;
    my $signature;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $data) {
        confess '$data must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignRecover($self->{session}, $data, $signature);
    return $self->{rv} == CKR_OK ? $signature : undef;
}

sub VerifyInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_VerifyInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub Verify {
    my ($self, $data, $signature) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $data) {
        confess '$data must be defined';
    }
    unless (defined $signature) {
        confess '$signature must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_Verify($self->{session}, $data, $signature);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub VerifyUpdate {
    my ($self, $part) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_VerifyUpdate($self->{session}, $part);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub VerifyFinal {
    my ($self, $signature) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $signature) {
        confess '$signature must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_VerifyFinal($self->{session}, $signature);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub VerifyRecoverInit {
    my ($self, $mechanism, $key) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_VerifyRecoverInit($self->{session}, $mechanism->toHash, $key->id);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub VerifyRecover {
    my ($self, $signature) = @_;
    my $data;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $signature) {
        confess '$signature must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_VerifyRecover($self->{session}, $signature, $data);
    return $self->{rv} == CKR_OK ? $data : undef;
}

sub DigestEncryptUpdate {
    my ($self, $part) = @_;
    my $encryptedPart;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DigestEncryptUpdate($self->{session}, $part, $encryptedPart);
    return $self->{rv} == CKR_OK ? $encryptedPart : undef;
}

sub DecryptDigestUpdate {
    my ($self, $encryptedPart) = @_;
    my $part;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $encryptedPart) {
        confess '$encryptedPart must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DecryptDigestUpdate($self->{session}, $encryptedPart, $part);
    return $self->{rv} == CKR_OK ? $part : undef;
}

sub SignEncryptUpdate {
    my ($self, $part) = @_;
    my $encryptedPart;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $part) {
        confess '$part must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SignEncryptUpdate($self->{session}, $part, $encryptedPart);
    return $self->{rv} == CKR_OK ? $encryptedPart : undef;
}

sub DecryptVerifyUpdate {
    my ($self, $encryptedPart) = @_;
    my $part;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $encryptedPart) {
        confess '$encryptedPart must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DecryptVerifyUpdate($self->{session}, $encryptedPart, $part);
    return $self->{rv} == CKR_OK ? $part : undef;
}

sub GenerateKey {
    my ($self, $mechanism, $template) = @_;
    my $key;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GenerateKey($self->{session}, $mechanism->toHash, $template->toArray, $key);
    return $self->{rv} == CKR_OK ? Crypt::PKCS11::Object->new($key) : undef;
}

sub GenerateKeyPair {
    my ($self, $mechanism, $publicKeyTemplate, $privateKeyTemplate) = @_;
    my ($publicKey, $privateKey);
    my @keys;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($publicKeyTemplate) and $publicKeyTemplate->isa('Crypt::PKCS11::Attributes')) {
        confess '$publicKeyTemplate is not a Crypt::PKCS11::Attributes';
    }
    unless (blessed($privateKeyTemplate) and $privateKeyTemplate->isa('Crypt::PKCS11::Attributes')) {
        confess '$privateKeyTemplate is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GenerateKeyPair($self->{session}, $mechanism->toHash, $publicKeyTemplate->toArray, $privateKeyTemplate->toArray, $publicKey, $privateKey);

    if ($self->{rv} == CKR_OK) {
        @keys = (
            Crypt::PKCS11::Object->new($publicKey),
            Crypt::PKCS11::Object->new($privateKey)
        );
        return wantarray ? @keys : \@keys;
    }
    return $self->{rv};
}

sub WrapKey {
    my ($self, $mechanism, $wrappingKey, $key) = @_;
    my $wrappedKey;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($wrappingKey) and $wrappingKey->isa('Crypt::PKCS11::Object')) {
        confess '$wrappingKey is not a Crypt::PKCS11::Object';
    }
    unless (blessed($key) and $key->isa('Crypt::PKCS11::Object')) {
        confess '$key is not a Crypt::PKCS11::Object';
    }

    $self->{rv} = $self->{pkcs11xs}->C_WrapKey($self->{session}, $mechanism->toHash, $wrappingKey->id, $key->id, $wrappedKey);
    return $self->{rv} == CKR_OK ? $wrappedKey : undef;
}

sub UnwrapKey {
    my ($self, $mechanism, $unwrappingKey, $wrappedKey, $template) = @_;
    my $key;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($unwrappingKey) and $unwrappingKey->isa('Crypt::PKCS11::Object')) {
        confess '$unwrappingKey is not a Crypt::PKCS11::Object';
    }
    unless (defined $wrappedKey) {
        confess '$wrappedKey must be defined';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_UnwrapKey($self->{session}, $mechanism->toHash, $unwrappingKey->id, $wrappedKey, $template->toArray, $key);
    return $self->{rv} == CKR_OK ? Crypt::PKCS11::Object->new($key) : undef;
}

sub DeriveKey {
    my ($self, $mechanism, $baseKey, $template) = @_;
    my $key;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (blessed($mechanism) and $mechanism->isa('Crypt::PKCS11::CK_MECHANISMPtr')) {
        confess '$mechanism is not a Crypt::PKCS11::CK_MECHANISMPtr';
    }
    unless (blessed($baseKey) and $baseKey->isa('Crypt::PKCS11::Object')) {
        confess '$baseKey is not a Crypt::PKCS11::Object';
    }
    unless (blessed($template) and $template->isa('Crypt::PKCS11::Attributes')) {
        confess '$template is not a Crypt::PKCS11::Attributes';
    }

    $self->{rv} = $self->{pkcs11xs}->C_DeriveKey($self->{session}, $mechanism->toHash, $baseKey->id, $template->toArray, $key);
    return $self->{rv} == CKR_OK ? Crypt::PKCS11::Object->new($key) : undef;
}

sub SeedRandom {
    my ($self, $seed) = @_;
    my $key;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $seed) {
        confess '$seed must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_SeedRandom($self->{session}, $seed);
    return $self->{rv} == CKR_OK ? 1 : undef;
}

sub GenerateRandom {
    my ($self, $randomLen) = @_;
    my $randomData;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }
    unless (defined $randomLen) {
        confess '$randomLen must be defined';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GenerateRandom($self->{session}, $randomData, $randomLen);
    return $self->{rv} == CKR_OK ? $randomData : undef;
}

sub GetFunctionStatus {
    my ($self) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_GetFunctionStatus($self->{session});
    return $self->{rv};
}

sub CancelFunction {
    my ($self) = @_;

    unless (exists $self->{session}) {
        confess 'session is closed';
    }

    $self->{rv} = $self->{pkcs11xs}->C_CancelFunction($self->{session});
    return $self->{rv};
}

sub errno {
    return $_[0]->{rv};
}

sub errstr {
    return Crypt::PKCS11::XS::rv2str($_[0]->{rv});
}

1;

__END__
