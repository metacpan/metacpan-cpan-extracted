# Cloudflare::API::Error #

# NAME #

Cloudflare::API::Error - exception for a failed Cloudflare JSON response

# SYNOPSIS #

```perl
my $result=eval { $api->zones()->get($zone_id) };
if (my $error=$@) {
    if (ref($error) && $error->isa('Cloudflare::API::Error')) {
        warn $error->as_string();
        my $details=$error->errors();
    }
}
```

# DESCRIPTION #

`Cloudflare::API` throws this exception when the HTTP request succeeds but the decoded JSON envelope contains `success: false`. HTTP and transport failures instead throw `HTTP::API::Core::Error`. The error object retains the original response and Cloudflare's error and message arrays.

# METHODS #

* **new(%fields)** — Construct an exception object from `response`, `errors`, and `messages`. This is normally called by `Cloudflare::API`; it returns a `Cloudflare::API::Error` object.
* **response()** — Return the original `HTTP::API::Core::Response` object, or `undef` if one was not supplied.
* **errors()** — Return Cloudflare's `errors` value, or an empty array reference if absent or false.
* **messages()** — Return Cloudflare's `messages` value, or an empty array reference if absent or false.
* **as_string()** — Join non-empty `message` fields from hash entries in `errors` with semicolons. If none are present, return `Cloudflare API reported failure`. Stringification invokes this method automatically.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), HTTP::API::Core::Error

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT #

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.
