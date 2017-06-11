# NAME

Business::GoCardless - Top level namespace for the Business::GoCardless
set of modules

<div>

    <a href='https://travis-ci.org/Humanstate/business-gocardless?branch=master'><img src='https://travis-ci.org/Humanstate/business-gocardless.svg?branch=master' alt='Build Status' /></a>
    <a href='https://coveralls.io/r/Humanstate/business-gocardless?branch=master'><img src='https://coveralls.io/repos/Humanstate/business-gocardless/badge.png?branch=master' alt='Coverage Status' /></a>
</div>

# VERSION

0.21

# DESCRIPTION

Business::GoCardless is a set of libraries for easy interface to the gocardless
payment service, they implement most of the functionality currently found
in the service's API documentation: https://developer.gocardless.com

Current missing functionality is partner account handling, but all resource
manipulation (Bill, Merchant, Payout etc) is handled along with webhooks and
the checking/generation of signature, nonce, param normalisation, and other
such lower level interface with the API.

# Do Not Use This Module Directly

Read the below to find out why.

# If You Are New To Business::GoCardless

You should go straight to [Business::GoCardless::Pro](https://metacpan.org/pod/Business::GoCardless::Pro) and start there. Do
**NOT** use the [Business::GoCardless::Basic](https://metacpan.org/pod/Business::GoCardless::Basic) module for reasons stated below.

# If You Are A Current User Of Business::GoCardless

You should read [Business::GoCardless::Upgrading](https://metacpan.org/pod/Business::GoCardless::Upgrading) as you will be using the
[Business::GoCardless::Basic](https://metacpan.org/pod/Business::GoCardless::Basic) module (via this module) and the API that
relates to (v1) will be swtiched off by GoCardless sometime in late 2017.

When GoCardless switch off the v1 API this dist will be updated to make this
module refer to the Pro module directly.

# SEE ALSO

[Business::GoCardless::Basic](https://metacpan.org/pod/Business::GoCardless::Basic)

[Business::GoCardless::Pro](https://metacpan.org/pod/Business::GoCardless::Pro)

# AUTHOR

Lee Johnson - `leejo@cpan.org`

# LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/Humanstate/business-gocardless
