[![Build Status](https://travis-ci.com/worthmine/Captcha-reCAPTCHA-V3.svg?branch=master)](https://travis-ci.com/worthmine/Captcha-reCAPTCHA-V3)
# NAME

Captcha::reCAPTCHA::V3 - A Perl implementation of reCAPTCHA API version v3

# SYNOPSIS

Captcha::reCAPTCHA::V3 provides you to integrate Google reCAPTCHA v3 for your web applications.

    use Captcha::reCAPTCHA::V3;
    my $rc = Captcha::reCAPTCHA::V3->new(
        secret  => '__YOUR_SECRET__',
        sitekey => '__YOUR_SITEKEY__',
    );

    ...
    
    my $content = $rc->verify($param{'reCAPTCHA_Token'});
    if( $content->{'success'} ){
       # code for succeeding
    }else{
       # code for failing
    }

# DESCRIPTION

Captcha::reCAPTCHA::V3 is inspired from [Captcha::reCAPTCHA::V2](https://metacpan.org/pod/Captcha::reCAPTCHA::V2)

This one is especially for Google reCAPTCHA v3, not for v2 because APIs are so defferent.

## Basic Usage

### new()

Requires secret and sitekey when constructing.
You have to get them before running from [here](https://www.google.com/recaptcha/intro/v3.html)

### verify()

Requires just only response key being got from Google reCAPTCHA API.
**DO NOT** add remote address. there is no function for remote address in reCAPTCHA v3

## Additional method for lazy persons(not supported)

### script4head()

You can insert this in your &lt;head> tag

### input4form

You can insert this in your &lt;form> tag

# SEE ALSO

- [Captcha::reCAPTCHA::V2](https://metacpan.org/pod/Captcha::reCAPTCHA::V2)
- [Google reCAPTCHA v3](https://www.google.com/recaptcha/intro/v3.html)
- [Google reCAPTCHA v3 API document](https://developers.google.com/recaptcha/docs/v3)

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

worthmine <worthmine@gmail.com>
