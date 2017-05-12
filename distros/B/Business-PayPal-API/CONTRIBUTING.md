# SANDBOX TESTING

To test this module type the following:

    WPP_TEST=auth.txt prove -lvr t

Please notice that this module requires you have several things before
you can test it:

  - a sandbox personal PayPal account
  - a sandbox business PayPal account
  - API credentials (either a certificate or signature)
  - auth.txt, which contains your API credentials

Read PayPal's and this module's documentation to learn more about how to
acquire PayPal sandbox credentials.

If you do not set the WPP_TEST environment variable, sandbox tests will be
skipped.

The format of the authentication tokens file defined by WPP_TEST may be found
in the Business::PayPal::API documentation under "TESTING". Sample auth.txt
files may be found in 'auth.sample.3token' and 'auth.sample.cert' in this
distribution.
