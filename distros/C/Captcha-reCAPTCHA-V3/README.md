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
    
    my $content = $rc->verify($param{'g-recaptcha-response'});
    unless ( $content->{'success'} ) {
       # code for failing like below
       die 'fail to verify reCAPTCHA: ', @{ $content->{'error-codes'} }, "\n";
    }
    

# DESCRIPTION

Captcha::reCAPTCHA::V3 is inspired from [Captcha::reCAPTCHA::V2](https://metacpan.org/pod/Captcha%3A%3AreCAPTCHA%3A%3AV2)

This one is especially for Google reCAPTCHA v3, not for v2 because APIs are so defferent.

## Basic Usage

### new( secret => _secret_, sitekey => _sitekey_ \[ query\_name => _query\_name_ \] )

Requires secret and sitekey when constructing.
You have to get them before running from [here](https://www.google.com/recaptcha/intro/v3.html).

    my $rc = Captcha::reCAPTCHA::V3->new(
       secret  => '__YOUR_SECRET__',
       sitekey => '__YOUR_SITEKEY__',
       query_name => '__YOUR_QUERY_NAME__', # Optinal
    );

According to the official document, query\_name defaults to 'g-recaptcha-response'
so if you changed it another, you have to set _query\_name_ as same.

### verify( _response_ )

Requires just only response key being got from Google reCAPTCHA API.

**DO NOT** add remote address. there is no function for remote address within reCAPTCHA v3.

    my $content = $rc->verify($param{'g-recaptcha-response'});

The default _query\_name_ is 'g-recaptcha-response' and it is stocked in constructor.

so you don't have to change it if you wrote like this:

    my $content = $rc->verify($param{ $rc->{'query_name'} });

The response contains JSON so it returns decoded value from JSON.

    unless ( $content->{'success'} ) {
       # code for failing like below
       die 'fail to verify reCAPTCHA: ', @{ $content->{'error-codes'} }, "\n";
    }

### deny\_by\_score( response => _response_, \[ score => _expected_ \] )

reCAPTCHA v3 responses have score whether the request was by bot.

So this method provides evaluation by scores that 0.0~1.0(defaults to 0.5)

If the score was lower than what you expected, the verifying is fail
with inserting 'too-low-score' into top of the error-codes.

`verify()` requires just only one argument because of compatibility for version 0.01. 

In this method, the response pair SHOULD be set as a hash argument(score pair is optional).

## Additional method for lazy(not sudgested)

### verify\_or\_die( response => _response_, \[ score => _score_ \] )

This method is a wrapper of `deny_by_score()`, the differense is dying imidiately when fail to verify.

### scripts( id => _ID_, \[ action => _action_ \] )

You can insert this somewhere in your &lt;body> tag.

In ordinal HTMLs, you can set this like below:

    print <<"EOL", scripts( id => 'MailForm' );
    <form action="./" method="POST" id="MailForm">
       <input type="hidden" name="name" value="value">
       <button type="submit">send</button>
    </form>
    EOL

Then you might write less javascript lines.

# NOTES

To test this module strictly,
there is a necessary to run javascript in test environment.

I have not prepared it yet.

So any [PRs](https://github.com/worthmine/Captcha-reCAPTCHA-V3/pulls)
and [Issues](https://github.com/worthmine/Captcha-reCAPTCHA-V3/issues) are welcome.

# SEE ALSO

- [Captcha::reCAPTCHA::V2](https://metacpan.org/pod/Captcha%3A%3AreCAPTCHA%3A%3AV2)
- [Google reCAPTCHA v3](https://www.google.com/recaptcha/intro/v3.html)
- [Google reCAPTCHA v3 API document](https://developers.google.com/recaptcha/docs/v3)

# LICENSE

Copyright (C) worthmine.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

worthmine <worthmine@gmail.com>
