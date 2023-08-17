package My::Test::AutoCleanHash;

use v5.20;
use Test::Lib;

use experimental 'signatures', 'postderef';


sub TIEHASH ( $class, $hash ) {
    return bless { $hash->%* }, $class;
}

sub FETCH ( $self, $key ) {
    return delete $self->{$key};
}

sub STORE ( $self, $key, $value ) {
    $self->{$key} = $value;
}

sub DELETE ( $self, $key ) {
    return delete $self->{$key};
}

sub CLEAR ( $self, $key ) {
    %$self = ();
}

sub EXISTS ( $self, $key ) {
    return exists $self->{$key};
}

sub FIRSTKEY ( $self ) {
    keys $self->%*;
    each $self->%*;
}

sub NEXTKEY ( $self, $ ) {
    return each $self->%*;
}
1;
