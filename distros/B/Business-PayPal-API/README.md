# NAME

Business::PayPal::API - PayPal SOAP API client with sandbox support

# VERSION

version 0.76

# SYNOPSIS

    use Business::PayPal::API qw( ExpressCheckout GetTransactionDetails );

    ## certificate authentication
    my $pp = Business::PayPal::API->new(
        Username       => 'my_api1.domain.tld',
        Password       => 'this_is_my_password',
        PKCS12File     => '/path/to/cert.pkcs12',
        PKCS12Password => '(pkcs12 password)',
        sandbox        => 1,
    );

    ## PEM cert authentication
    my $pp = Business::PayPal::API->new(
        Username => 'my_api1.domain.tld',
        Password => 'this_is_my_password',
        CertFile => '/path/to/cert.pem',
        KeyFile  => '/path/to/cert.pem',
        sandbox  => 1,
    );

    ## 3-token (Signature) authentication
    my $pp = Business::PayPal::API->new(
        Username => 'my_api1.domain.tld',
        Password => 'Xdkis9k3jDFk39fj29sD9',    ## supplied by PayPal
        Signature =>
            'f7d03YCpEjIF3s9Dk23F2V1C1vbYYR3ALqc7jm0UrCcYm-3ksdiDwjfSeii', ## ditto
        sandbox => 1,
    );

    my %response = $pp->SetExpressCheckout( ... );

# DESCRIPTION

**Business::PayPal::API** supports both certificate authentication and
the new 3-token "Signature" authentication.

It also supports PayPal's development _sandbox_ for testing. See the
**sandbox** parameter to **new()** below for details.

**Business::PayPal::API** can import other **API** derived classes:

    use Business::PayPal::API qw( RefundTransaction );

This allows for much more concise and intuitive usage. For example,
these two statements are equivalent:

    use Business::PayPal::API::RefundTransaction;
    my $pp = Business::PayPal::API::RefundTransaction->new( ... );
    $pp->RefundTransaction( ... );

and more concisely:

    use Business::PayPal::API qw( RefundTransaction );
    my $pp = Business::PayPal::API->new( ... );
    $pp->RefundTransaction( ... );

The advantage of this becomes clear when you need to use multiple API
calls in your program; this allows you to use the same object to
invoke the various methods, instead of creating a new object for each
subclass. Here is an example of a **API** object used to invoke various
PayPal APIs with the same object:

    use Business::PayPal::API qw( GetTransactionDetails
                                  TransactionSearch
                                  RefundTransaction );
    my $pp = Business::PayPal::API->new( ... );
    my $records = $pp->TransactionSearch( ... );

    my %details = $pp->GetTransactionDetails( ... );

    my %resp = $pp->RefundTransaction( ... );

However, you may certainly use just the subclass if that's all you
need. Every subclass should work as its own self-contained API.

For details on **Business::PayPal::API::\*** subclasses, see each
subclass's individual documentation.

## new

Creates a new **Business::PayPal::API** object.

A note about certificate authentication: PayPal (and this module)
support either PKCS#12 certificate authentication or PEM certificate
authentication. See options below.

- **Username**

    Required. This is the PayPal API username, usually in the form of
    'my\_api1.mydomain.tld'. You can find or create your API credentials by
    logging into PayPal (if you want to do testing, as you should, you
    should also create a developer sandbox account) and going to:

        My Account -> Profile -> API Access -> Request API Credentials

    Please see the _PayPal API Reference_ and _PayPal Sandbox User
    Guide_ for details on creating a PayPal business account and sandbox
    account for testing.

- **Password**

    Required. If you use certificate authentication, this is the PayPal
    API password created when you setup your certificate. If you use
    3-token (Signature) authentication, this is the password PayPal
    assigned you, along with the "API User Name" and "Signature Hash".

- **Subject**

    Optional. This is used by PayPal to authenticate 3rd party billers
    using your account. See the documents in ["SEE ALSO"](#see-also).

- **Signature**

    Required for 3-token (Signature) authentication. This is the
    "Signature Hash" you received when you did "Request API Credentials"
    in your PayPal Business Account.

- **PKCS12File**

    Required for PKCS#12 certificate authentication, unless the
    **HTTPS\_PKCS12\_FILE** environment variable is already set.

    This contains the path to your private key for PayPal
    authentication. It is used to set the **HTTPS\_PKCS12\_FILE** environment
    variable. You may set this environment variable yourself and leave
    this field blank.

- **PKCS12Password**

    Required for PKCS#12 certificate authentication, unless the
    **HTTPS\_PKCS12\_PASSWORD** environment variable is already set.

    This contains the PKCS#12 password for the key specified in
    **PKCS12File**. It is used to set the **HTTPS\_PKCS12\_PASSWORD**
    environment variable. You may set this environment variable yourself
    and leave this field blank.

- **CertFile**

    Required for PEM certificate authentication, unless the
    HTTPS\_CERT\_FILE environment variable is already set.

    This contains the path to your PEM format certificate given to you
    from PayPal (and accessible in the same location that your Username
    and Password and/or Signature Hash are found) and is used to set the
    **HTTPS\_CERT\_FILE** environment variable. You may set this environment
    variable yourself and leave this field blank.

    You may combine both certificate and private key into one file and set
    **CertFile** and **KeyFile** to the same path.

- **KeyFile**

    Required for PEM certificate authentication, unless the HTTPS\_KEY\_FILE
    environment variable is already set.

    This contains the path to your PEM format private key given to you
    from PayPal (and accessible in the same location that your Username
    and Password and/or Signature Hash are found) and is used to set the
    **HTTPS\_KEY\_FILE** environment variable. You may set this environment
    variable yourself and leave this field blank.

    You may combine both certificate and private key into one file and set
    **CertFile** and **KeyFile** to the same path.

- **sandbox**

    Required. If set to true (default), **Business::PayPal::API** will
    connect to PayPal's development sandbox, instead of PayPal's live
    site. \*You must explicitly set this to false (0) to access PayPal's
    live site\*.

    If you use PayPal's development sandbox for testing, you must have
    already signed up as a PayPal developer and created a Business sandbox
    account and a Buyer sandbox account (and make sure both of them have
    **Verified** status in the sandbox).

    When testing with the sandbox, you will use different usernames,
    passwords, and certificates (if using certificate authentication) than
    you will when accessing PayPal's live site. Please see the PayPal
    documentation for details. See ["SEE ALSO"](#see-also) for references.

    PayPal's sandbox reference:

    [https://www.paypal.com/IntegrationCenter/ic\_sandbox.html](https://www.paypal.com/IntegrationCenter/ic_sandbox.html)

- **proxy\_url**

    Optional. When set, the proxy at the specified URL will be used for outbound
    connections.

- **timeout**

    Optional. Set the timeout in seconds. Defaults to 30 seconds.

# NAME

Business::PayPal::API - PayPal API

# ERROR HANDLING

Every API call should return an **Ack** response, whether _Success_,
_Failure_, or otherwise (depending on the API call). If it returns
any non-success value, you can find an _Errors_ entry in your return
hash, whose value is an arrayref of hashrefs:

    [ { ErrorCode => 10002,
        LongMessage => "Invalid security header" },

      { ErrorCode => 10030,
        LongMessage => "Some other error" }, ]

You can retrieve these errors like this:

    %response = $pp->doSomeAPICall();
    if( $response{Ack} ne 'Success' ) {
        for my $err ( @{$response{Errors}} ) {
            warn "Error: " . $err->{LongMessage} . "\n";
        }
    }

# TESTING

Testing the **Business::PayPal::API::\*** modules requires that you
create a file containing your PayPal Developer Sandbox authentication
credentials (e.g., API certificate authentication or 3-Token
authentication signature, etc.) and setting the **WPP\_TEST**
environment variable to point to this file.

The format for this file is as follows:

    Username = your_api.username.com
    Password = your_api_password

and then ONE of the following options:

    a) supply 3-token authentication signature

        Signature = xxxxxxxxxxxxxxxxxxxxxxxx

    b) supply PEM certificate credentials

        CertFile = /path/to/cert_key_pem.txt
        KeyFile  = /path/to/cert_key_pem.txt

    c) supply PKCS#12 certificate credentials

        PKCS12File = /path/to/cert.p12
        PKCS12Password = pkcs12_password

You may also set the appropriate HTTPS\_\* environment variables for b)
and c) above (e.g., HTTPS\_CERT\_FILE, HTTPS\_KEY\_FILE,
HTTPS\_PKCS12\_File, HTTPS\_PKCS12\_PASSWORD) in lieu of putting this
information in a file.

Then use "WPP\_TEST=my\_auth.txt make test" (for Bourne shell derivates) or
"setenv WPP\_TEST my\_auth.txt && make test" (for C-shell derivates).

See 'auth.sample.\*' files in this package for an example of the file
format. Variables are case-\*sensitive\*.

Any of the following variables are recognized:

    Username Password Signature Subject
    CertFile KeyFile PKCS12File PKCS12Password
    BuyerEmail

Note: PayPal authentication may _fail_ if you set the certificate
environment variables and attempt to connect using 3-token
authentication (i.e., PayPal will use the first authentication
credentials presented to it, and if they fail, the connection is
aborted).

# TROUBLESHOOTING

## PayPal Authentication Errors

If you are experiencing PayPal authentication errors (e.g., "Security
header is not valid", "SSL negotiation failed", etc.), you should make
sure:

    * your username and password match those found in your PayPal
      Business account sandbox (this is not the same as your regular
      account).

    * you're not trying to use your live username and password for
      sandbox testing and vice versa.

    * you are using a US Business Sandbox account, you may also need to have
      "PayPal Payments Pro" enabled.

    * if the sandbox works but "live" does not, make sure you've turned
      off the 'sandbox' parameter correctly. Otherwise you'll be
      passing your PayPal sandbox credentials to PayPal's live site
      (which won't work).

    * if you use certificate authentication, your certificate must be
      the correct one (live or sandbox) depending on what you're doing.

    * if you use 3-Token authentication (i.e., Signature), you don't
      have any B<PKCS12*> parameters or B<CertFile> or B<KeyFile>
      parameters in your constructor AND that none of the corresponding
      B<HTTPS_*> environment variables are set. PayPal prefers
      certificate authentication since it occurs at connection time; if
      it fails, it will not try Signature authentication.

      Try clearing your environment:

          ## delete all HTTPS, SSL env
          delete $ENV{$_} for grep { /^(HTTPS|SSL)/ } keys %ENV;

          ## now put our own HTTPS env back in
          $ENV{HTTPS_CERT_FILE} = '/var/path/to/cert.pem';

          ## create our paypal object
          my $pp = Business::PayPal::API->new(...)

    * if you have already loaded Net::SSLeay (or IO::Socket::SSL), then
      Net::HTTPS will prefer to use IO::Socket::SSL. I don't know how
      to get SOAP::Lite to work with IO::Socket::SSL (e.g.,
      Crypt::SSLeay uses HTTPS_* environment variables), so until then,
      you can use this hack:

        local $IO::Socket::SSL::VERSION = undef;

        $pp->DoExpressCheckoutPayment(...);

      This will tell Net::HTTPS to ignore the fact that IO::Socket::SSL
      is already loaded for this scope and import Net::SSL (part of the
      Crypt::SSLeay package) for its 'configure()' method.

    * if you receive a message like "500 Can't connect to
      api.sandbox.paypal.com:443 (Illegal seek)", you'll need to make
      sure you have Crypt::SSLeay installed. It seems that other crypto
      modules don't do the certificate authentication quite as well,
      and LWP needs this to negotiate the SSL connection with PayPal.

See the DEBUGGING section below for further hints.

## PayPal Munging URLs

PayPal seems to be munging my URLs when it returns.

SOAP::Lite follows the XML specification carefully, and encodes '&'
and '<' characters before applying them to the SOAP document. PayPal
does not properly URL-decode HTML entities '&amp;amp;' and '&amp;lt;' on the
way back, so if you have an ampersand in your ReturnURL (for example),
your customers will be redirected here:

    http://domain.tld/prog?arg1=foo&amp;arg2=bar

instead of here:

    http://domain.tld/prog?arg1=foo&arg2=bar

Solution:

Use CDATA tags to wrap your request:

    ReturnURL => '<![CDATA[http://domain.tld/prog?arg1=foo&arg2=bar]]>'

You may also use semicolons instead of ampersands to separate your URL
arguments:

    ReturnURL => 'http://domain.tld/prog?arg1=foo;arg2=bar'

(thanks to Ollie Ready)

# DEBUGGING

You can see the raw SOAP XML sent and received by
**Business::PayPal::API** by setting its **$Debug** variable:

    $Business::PayPal::API::Debug = 1;
    $pp->SetExpressCheckout( %args );

this will print the XML being sent, and dump a Perl data structure of
the SOM received on STDERR (so check your error\_log if running inside
a web server).

If anyone knows how to turn a SOAP::SOM object into XML without
setting **outputxml()**, let me know.

# DEVELOPMENT

If you are a developer wanting to extend **Business::PayPal::API** for
other PayPal API calls, you can review any of the included modules
(e.g., `RefundTransaction.pm` or `ExpressCheckout.pm`) for examples
on how to do this until I have more time to write a more complete
document.

But in a nutshell:

    package Business::PayPal::API::SomeAPI;

    use 5.008001;
    use strict;
    use warnings;

    use SOAP::Lite 0.67;
    use Business::PayPal::API ();

    our @ISA = qw(Business::PayPal::API);
    our @EXPORT_OK = qw( SomeAPIMethod );

    sub SomeAPIMethod {
     ...
    }

Notice the **@EXPORT\_OK** variable. This is _not_ used by **Exporter**
(we don't load Exporter at all): it is a special variable used by
**Business::PayPal::API** to know which methods to import when
**Business::PayPal::API** is run like this:

    use Business::PayPal::API qw( SomeAPI );

That is, **Business::PayPal::API** will import any subroutine into its
own namespace from the **@EXPORT\_OK** array. Now it can be used like this:

    use Business::PayPal::API qw( SomeAPI );
    my $pp = Business::PayPal::API->new( ... );
    $pp->SomeAPIMethod( ... );

Of course, we also do a 'use Business::PayPal::API' in the module so
that it can be used as a standalone module, if necessary:

    use Business::PayPal::API::SomeAPI;
    my $pp = Business::PayPal::API::SomeAPI->new( ... ); ## same args as superclass
    $pp->SomeAPIMethod( ... );

Adding the **@EXPORT\_OK** array in your module allows your module to be
used in the most convenient way for the given circumstances.

# EXAMPLES

Andy Spiegl <paypalcheckout.Spiegl@kascada.com> has kindly donated
some example code (in German) for the ExpressCheckout API which may be
found in the `eg` directory of this archive. Additional code examples
for other APIs may be found in the `t` test directory.

# EXPORT

None by default.

# CAVEATS

Because I haven't figured out how to make SOAP::Lite read the WSDL
definitions directly and simply implement those (help, anyone?), I
have essentially recreated all of those WSDL structures internally in
this module.

(Note - 6 Oct 2006: SOAP::Lite's WSDL support is moving ahead, but
slowly. The methods used by this API are considered "best practice"
and are safe to use).

As with all web services, if PayPal stop supporting their API
endpoint, this module \*may stop working\*. You can help me keep this
module up-to-date if you notice such an event occurring.

Also, I didn't implement a big fat class hierarchy to make this module
"academically" correct. You'll notice that I fudged colliding
parameter names in **DoExpressCheckoutPayment** and similar fudging may
be found in **GetTransactionDetails**. The good news is that this was
written quickly, works, and is dead-simple to use. The bad news is
that this sort of collision might occur again as more and more data is
sent in the API (call it 'eBay API bloat'). I'm willing to take the
risk this will be rare (PayPal--please make it rare!).

# ACKNOWLEDGEMENTS

Wherein I acknowledge all the good folks who have contributed to this
module in some way:

- Daniel P. Hembree

    for authoring the AuthorizationRequest, CaptureRequest,
    DirectPayments, ReauthorizationRequest, and VoidRequest extensions.

- &lt;jshiles at base16consulting daught com>

    for finding some API typos in the ExpressCheckout API

- Andy Spiegl <paypalcheckout.Spiegl@kascada.com>

    for giving me the heads-up on PayPal's new 3-token auth URI and for a
    sample command-line program (found in the 'eg' directory)
    demonstrating the ExpressCheckout API.

- Ollie Ready &lt;oready at drjays daught com>

    for the heads-up on the newest 3-token auth URI as well as a pile of
    documentation inconsistencies.

- Michael Hendricks &lt;michael at ndrix daught org>

    for a patch that adds ShippingTotal to the DirectPayments module.

- Erik Aronesty, Drew Simpson via rt.cpan.org (#28596)

    for a patch to fix getFields() when multiple items are returned

- Sebastian Böhm via email, SDC via rt.cpan.org (#38915)

    for a heads-up that the PayPal documentation for MassPay API was wrong
    regarding the _UniqueId_ parameter.

- Jonathon Wright via email

    for patches for **ExpressCheckout** and **RecurringPayments** that
    implement _BillingAgreement_ and _DoReferenceTransaction_ API
    calls.

# SEE ALSO

[SOAP::Lite](https://metacpan.org/pod/SOAP::Lite),
[PayPal User Guide](https://developer.paypal.com/webapps/developer/docs/classic/products),
[PayPal API Reference](https://developer.paypal.com/webapps/developer/docs/api/overview)

# AUTHORS

- Scott Wiersdorf <scott@perlcode.org>
- Danny Hembree <danny@dynamical.org>
- Bradley M. Kuhn <bkuhn@ebb.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2006-2017 by Scott Wiersdorf, Danny Hembree, Bradley M. Kuhn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 205:

    '=item' outside of any '=over'

- Around line 214:

    You forgot a '=back' before '=head1'
