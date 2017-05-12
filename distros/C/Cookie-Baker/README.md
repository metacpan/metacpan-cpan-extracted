# NAME

Cookie::Baker - Cookie string generator / parser

# SYNOPSIS

    use Cookie::Baker;

    $headers->push_header('Set-Cookie', bake_cookie($key,$val));

    my $cookies_hashref = crush_cookie($headers->header('Cookie'));

# DESCRIPTION

Cookie::Baker provides simple cookie string generator and parser.

# XS IMPLEMENTATION

This module tries to use [Cookie::Baker::XS](https://metacpan.org/pod/Cookie::Baker::XS)'s crush\_cookie by default.
If this fails, it will use Cookie::Baker's pure Perl crush\_cookie.

There is no XS implementation of bake\_cookie yet.

# FUNCTION

- bake\_cookie

        my $cookie = bake_cookie('foo','val');
        my $cookie = bake_cookie('foo', {
            value => 'val',
            path => "test",
            domain => '.example.com',
            expires => '+24h'
        } );

    Generates a cookie string for an HTTP response header.
    The first argument is the cookie's name and the second argument is a plain string or hash reference that
    can contain keys such as `value`, `domain`, `expires`, `path`, `httponly`, `secure`,
    `max-age`.

    - value

        Cookie's value

    - domain

        Cookie's domain.

    - expires

        Cookie's expires date time. Several formats are supported

            expires => time + 24 * 60 * 60 # epoch time
            expires => 'Wed, 03-Nov-2010 20:54:16 GMT' 
            expires => '+30s' # 30 seconds from now
            expires => '+10m' # ten minutes from now
            expires => '+1h'  # one hour from now 
            expires => '-1d'  # yesterday (i.e. "ASAP!")
            expires => '+3M'  # in three months
            expires => '+10y' # in ten years time
            expires => 'now'  #immediately

    - path

        Cookie's path.

    - httponly

        If true, sets HttpOnly flag. false by default.

    - secure

        If true, sets secure flag. false by default.

- crush\_cookie

    Parses cookie string and returns a hashref. 

        my $cookies_hashref = crush_cookie($headers->header('Cookie'));
        my $cookie_value = $cookies_hashref->{cookie_name}  

# SEE ALSO

CPAN already has many cookie related modules. But there is no simple cookie string generator and parser module.

[CGI](https://metacpan.org/pod/CGI), [CGI::Simple](https://metacpan.org/pod/CGI::Simple), [Plack](https://metacpan.org/pod/Plack), [Dancer::Cookie](https://metacpan.org/pod/Dancer::Cookie)

# LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masahiro Nagano <kazeburo@gmail.com>
