# NAME

Data::UUID::Base64URLSafe - getting Data::UUID with URLSafe strings

# SYNOPSIS

    use Data::UUID::Base64URLSafe;
    my $ug = Data::UUID::Base64URLSafe->new();
    my $uuid = $ug->create_b64_urlsafe();                                  # make an unique UUID
    $uuid = $ug->create_from_name_b64_urlsafe( <namespace>, <string> );    # from namespace and string
    my $str = $ug->from_b64_urlsafe(< Base64-URLSafe || Base64 >);         # decoding from Base64
    my $bin = $ug->create_from_name( <namepace>, <string> );
    my $uuid2 = $ug->to_b64_urlsafe($bin);                                 # encoding from binary

# DESCRIPTION

Data::UUID::Base64URLSafe is a wrapper module for Data::UUID.

[Data::UUID](https://github.com/rjbs/Data-UUID) creates wonderful Globally/Universally Unique
Identifiers (GUIDs/UUIDs). This module is a subclass of that
module which adds a method to get a URL-safe Base64-encoded
version of the UUID using [MIME::Base64](https://github.com/gisle/mime-base64).
What that means is that you can get a 22-character UUID string which
you can use safely in URLs.

It will help you when you wanna make user-ID on your web applications.

# METHODS

## new

## create\_b64\_urlsafe

Create a URL-safe Base64-encoded UUID:

    my $uuid = $ug->create_b64_urlsafe();

## create\_from\_name\_b64\_urlsafe

Creates a URL-safe Base64 encoded UUID with the namespace and data
specified (See the [Data::UUID](https://github.com/rjbs/Data-UUID) docs on create\_from\_name

## from\_b64\_urlsafe

Convert a (URL-safe or not) Base64-encoded UUID to its canonical binary representation

    my $uuid = $ug−>create_from_name_b64_urlsafe(<namespace>, <name>);
    my $bin = $ug->from_b64_urlsafe($uuid);

## to\_b64\_urlsafe

Convert a binary UUID to a URL-safe Base64 encoded UUID

    my $bin = $ug->create_from_name(<namespace>, <name>);
    my $uuid = $ug−>to_b64_urlsafe($bin);

# AUTHOR

Leon Brocard, `<acme@astray.com>`,
Yuki Yoshida(worthmine) `<worthmine@gmail.com>`

# LICENSE

Copyright (C) 2008, Leon Brocard, 2017, Yuki Yoshida.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
