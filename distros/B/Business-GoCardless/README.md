# NAME

Business::GoCardless - Top level namespace for the Business::GoCardless
set of modules

<div>

    <a href='https://travis-ci.org/Humanstate/business-gocardless?branch=master'><img src='https://travis-ci.org/Humanstate/business-gocardless.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/business-gocardless?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-gocardless/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.38

# DESCRIPTION

Business::GoCardless is a set of libraries for easy interface to the gocardless
payment service, they implement most of the functionality currently found
in the service's API documentation: https://developer.gocardless.com

Current missing functionality is partner account handling, but all resource
manipulation (Bill, Merchant, Payout etc) is handled along with webhooks and
the checking/generation of signature, nonce, param normalisation, and other
such lower level interface with the API.

# Do Not Use This Module Directly

You should go straight to [Business::GoCardless::Pro](https://metacpan.org/pod/Business%3A%3AGoCardless%3A%3APro) and start there.

# SEE ALSO

[Business::GoCardless::Pro](https://metacpan.org/pod/Business%3A%3AGoCardless%3A%3APro)

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# CONTRIBUTORS

grifferz - `andy-github.com@strugglers.net`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless
