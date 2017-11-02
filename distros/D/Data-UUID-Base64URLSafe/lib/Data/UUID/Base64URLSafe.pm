package Data::UUID::Base64URLSafe;
use 5.008001;
use strict;
use warnings;
use MIME::Base64;

our $VERSION = "0.35";

use base qw( Data::UUID );
our @EXPORT  = @Data::UUID::EXPORT;

=encoding utf-8

=head1 NAME

Data::UUID::Base64URLSafe - getting Data::UUID with URLSafe strings

=head1 SYNOPSIS

 use Data::UUID::Base64URLSafe;
 my $ug = Data::UUID::Base64URLSafe->new();
 my $uuid = $ug->create_b64_urlsafe();                                  # make an unique UUID
 $uuid = $ug->create_from_name_b64_urlsafe( <namespace>, <string> );    # from namespace and string
 my $str = $ug->from_b64_urlsafe(< Base64-URLSafe || Base64 >);         # decoding from Base64
 my $bin = $ug->create_from_name( <namepace>, <string> );
 my $uuid2 = $ug->to_b64_urlsafe($bin);                                 # encoding from binary

=head1 DESCRIPTION

Data::UUID::Base64URLSafe is a wrapper module for Data::UUID.

L<Data::UUID|https://github.com/rjbs/Data-UUID> creates wonderful Globally/Universally Unique
Identifiers (GUIDs/UUIDs). This module is a subclass of that
module which adds a method to get a URL-safe Base64-encoded
version of the UUID using L<MIME::Base64|https://github.com/gisle/mime-base64>.
What that means is that you can get a 22-character UUID string which
you can use safely in URLs.

It will help you when you wanna make user-ID on your web applications.

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    return bless $class->SUPER::new(), $class;
};

=head2 create_b64_urlsafe

Create a URL-safe Base64-encoded UUID:

 my $uuid = $ug->create_b64_urlsafe();

=cut

sub create_b64_urlsafe {
    my $self = shift;
    my $uuid = $self->create();
    return MIME::Base64::encode_base64url($uuid);
}

=head2 create_from_name_b64_urlsafe

Creates a URL-safe Base64 encoded UUID with the namespace and data
specified (See the L<Data::UUID|https://github.com/rjbs/Data-UUID> docs on create_from_name

=cut

sub create_from_name_b64_urlsafe {
    my $self = shift;
    my $uuid = $self->create_from_name(@_);
    return MIME::Base64::encode_base64url($uuid);
}

=head2 from_b64_urlsafe

Convert a (URL-safe or not) Base64-encoded UUID to its canonical binary representation

 my $uuid = $ug−>create_from_name_b64_urlsafe(<namespace>, <name>);
 my $bin = $ug->from_b64_urlsafe($uuid);

=cut

sub from_b64_urlsafe {
    my $self = shift;
    my $b64 = shift;
    $b64 =~ tr[-_][+/] if $b64 =~ m|[-_]|;
    return MIME::Base64::decode_base64($b64);
}

=head2 to_b64_urlsafe

Convert a binary UUID to a URL-safe Base64 encoded UUID

 my $bin = $ug->create_from_name(<namespace>, <name>);
 my $uuid = $ug−>to_b64_urlsafe($bin);

=cut

sub to_b64_urlsafe {
    my $self = shift;
    my $bin = shift;
    return MIME::Base64::encode_base64url($bin);
}

1;
__END__

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>,
Yuki Yoshida(worthmine) C<< <worthmine@gmail.com> >>

=head1 LICENSE

Copyright (C) 2008, Leon Brocard, 2017, Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
