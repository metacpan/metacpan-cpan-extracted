# Dancer2-Plugin-HTTP-ConditionalRequest
Conditionally handling HTTP request based on eTag or Modification-Date,
according to RFC 7232

HTTP Conditional Requests are used for telling servers that they only have to
perform the method if the preconditions are met. Such requests are either used
by caches to (re)validate the cached response with the origin server - or -
to prevent lost-updates with unsafe-methods in a stateless api (like REST).
 
    any '/my_resource/:id' => sub {
        ...
        # check stuff
        # - compute eTag from MD5
        # - use an external table
        # - find a last modification date
        ...
        
        http_conditional {
            etag            => '2d5730a4c92b1061',
            last_modified   => "Tue, 15 Nov 1994 12:45:26 GMT", # HTTP Date
            required        => false,
        } => sub {
            ...
            # do the real stuff, like updating
            ...
        }
    };

### Strong and weak validators
ETags are stronger validators than the Date Last-Modified. In the above
described example, it has two validators provided that can be used to check the conditional request. If the client did set an eTag conditional in 'If-Matched'
or 'If-None-Matched', it will try to match that. If not, it will try to match
against the Date Last-Modified with either the 'If-Modified-Since' or
'If-Unmodified-Since'.

### Required or not
The optional 'required' turns the API into a strict mode. Running under 'strict'
ensures that the client will provided either the eTag or Date-Modified validator
for un-safe requests. If not provided when required, it will return a response
with status 428 (Precondition Required) (RFC 6585).

When set to false, it allows a client to sent of a request without the headers
for the conditional requests and as such have bypassed all the checks end up in
the last validation step and continue with the requested operation.

### Safe and unsafe methods
Sending these validators with a GET request is used for caching and respond with
a status of 304 (Not Modified) when the client has a 'fresh' version. Remember
though to send of current caching-information too (according to the RFC 7232).

When used with 'unsafe' methods that will cause updates, these validators can
prevent 'lost updates' and will respond with 412 (Precondition Failed) when
there might have happened an intermediate update.

### Generating eTags and Dates Last-Modified
Unfortunately, for a any method one might have to retrieve and process the
resource data before being capable of generating a eTag. Or one might have to go
through a few pieces of underlying data structures to find that
last-modification date.

For a GET method one can then skip the 'post-processing' like serialisation and
one does no longer have to send the data but only the status message 304
(Not Modified).

### More reading
There is a lot of additional information in RFC-7232 about generating and
retrieving eTags or last-modification-dates. Please read-up in the RFC about
those topics.
