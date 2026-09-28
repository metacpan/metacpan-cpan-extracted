#
#  This file is part of Cloudflare::API.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package Cloudflare::API;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;


#  External modules
#
use HTTP::API::Core 1.08;


#  Cloudflare::API modules
#
use Cloudflare::API::Error;


#  Version information
#
$VERSION='1.011';


#  All done. Positive return
#
1;


#============================================================================


sub new {


    #  Resolve credentials and account context from options or environment
    #
    my ($class, %opt)=@_;
    my $token=exists($opt{'token'}) ? delete($opt{'token'}) : $ENV{'CLOUDFLARE_API_TOKEN'};
    die "token is required\n" unless defined($token)&&!ref($token)&&length($token);

    my $account_id=exists($opt{'account_id'})
        ? delete($opt{'account_id'}) : $ENV{'CLOUDFLARE_ACCOUNT_ID'};
    die "account_id must be a non-empty scalar\n"
        if defined($account_id)&&(ref($account_id)||!length($account_id));

    my $base_url=exists($opt{'base_url'})
        ? delete($opt{'base_url'}) : 'https://api.cloudflare.com/client/v4';
    die "base_url must be an HTTPS URL\n"
        unless defined($base_url)&&$base_url=~m{\Ahttps://[^/]+(?:/.*)?\z};



    #  Build the HTTP client with bearer authentication
    #
    my %core_opt=(
        base_url => $base_url,
        headers  => { Authorization => "Bearer $token", Accept => 'application/json' },
        retry    => { attempts => 1 }
    );
    foreach my $name (qw(timeout transport retry hooks)) {
        $core_opt{$name}=delete($opt{$name}) if exists($opt{$name});
    }
    die "unknown constructor option: $_\n" foreach sort(keys(%opt));



    #  Retain the account ID for resource methods
    #
    my $self=bless({
        account_id => $account_id,
        core_or    => HTTP::API::Core->new(%core_opt)
    }, $class);
    return $self;

}


sub account_id { return $_[0]->{'account_id'} }


sub response {


    #  Require a relative API path so credentials stay on the configured host
    #
    my ($self, $method, $path, %opt)=@_;
    die "path must begin with one slash\n"
        unless defined($path)&&!ref($path)&&$path=~m{\A/(?!/)};
    return $self->{'core_or'}->request($method, $path, %opt);

}


sub raw_request {

    my $self=shift();
    return $self->response(@_);

}


sub request {


    #  Unwrap result by default, but allow the full decoded envelope
    #
    my ($self, $method, $path, %opt)=@_;
    my $full_response=delete($opt{'full_response'});
    my $body_hr=$self->request_full($method, $path, %opt);
    return $full_response ? $body_hr : $body_hr->{'result'};

}


sub request_full {


    #  Parse the Cloudflare envelope and surface reported API failures
    #
    my ($self, $method, $path, %opt)=@_;
    my $response_or=$self->response($method, $path, %opt);
    return $self->decode_response($response_or);

}


sub decode_response {


    #  Decode and validate the Cloudflare response shared by direct requests
    #  and paginated extractors
    #
    my ($self, $response_or, $body_hr)=@_;
    return { success => 1, result => undef } unless $response_or->has_content();

    $body_hr=$response_or->json() unless defined($body_hr);
    die "Cloudflare returned a non-object JSON response\n" unless ref($body_hr) eq 'HASH';
    if (exists($body_hr->{'success'})&&!$body_hr->{'success'}) {
        die Cloudflare::API::Error->new(
            response => $response_or,
            errors   => $body_hr->{'errors'},
            messages => $body_hr->{'messages'}
        );
    }
    return $body_hr;

}


sub pagination {


    #  Configure the Core iterator while retaining Cloudflare validation and
    #  the endpoint's result and continuation shapes
    #
    my ($self, $path, %opt)=@_;
    die "path must begin with one slash\n"
        unless defined($path)&&!ref($path)&&$path=~m{\A/(?!/)};
    my $mode=delete($opt{'mode'}) || 'page';
    die "unsupported Cloudflare pagination mode: $mode\n"
        unless $mode=~/\A(?:page|cursor|single)\z/;
    my $items_path=delete($opt{'items'}) || 'result';
    my $next_path=delete($opt{'next'}) || 'result_info.cursor';
    my $page_param=delete($opt{'page_param'}) || 'page';
    my $page_size_param=delete($opt{'page_size_param'}) || 'per_page';
    my $cursor_param=delete($opt{'cursor_param'}) || 'cursor';
    my $query_hr=delete($opt{'query'}) || {};
    my $request_hr=delete($opt{'request'}) || {};
    die "query must be a hash reference\n" unless ref($query_hr) eq 'HASH';
    die "request must be a hash reference\n" unless ref($request_hr) eq 'HASH';
    die "unknown Cloudflare pagination option: $_\n" foreach sort(keys(%opt));

    my %query=%$query_hr;
    my $items_cr=sub {
        my ($body_hr, $response_or)=@_;
        $body_hr=$self->decode_response($response_or, $body_hr);
        return $self->response_value($body_hr, $items_path);
    };
    my %page_opt=(
        items                     => $items_cr,
        query                     => \%query,
        request                   => $request_hr,
        response_aware_extractors => 1
    );

    if ($mode=~/\A(?:cursor|single)\z/) {
        $page_opt{'mode'}='cursor';
        if ($mode eq 'cursor') {
            $page_opt{'cursor_param'}=$cursor_param;
            $page_opt{'cursor'}=delete($query{$cursor_param})
                if exists($query{$cursor_param});
        }
        $page_opt{'next'}=sub {
            my ($body_hr, $response_or)=@_;
            $body_hr=$self->decode_response($response_or, $body_hr);
            return undef if $mode eq 'single';
            return $self->response_value($body_hr, $next_path);
        };
    }
    else {
        $page_opt{'mode'}='page';
        $page_opt{'page_param'}=$page_param;
        $page_opt{'start_page'}=delete($query{$page_param})
            if exists($query{$page_param});
        $page_opt{'page_size_param'}=$page_size_param;
        $page_opt{'page_size'}=delete($query{$page_size_param})
            if exists($query{$page_size_param});
        $page_opt{'has_more'}=sub {
            my ($body_hr, $response_or)=@_;
            $body_hr=$self->decode_response($response_or, $body_hr);
            my $info_hr=$body_hr->{'result_info'};
            if (ref($info_hr) eq 'HASH') {
                return $info_hr->{'page'}<$info_hr->{'total_pages'}
                    if defined($info_hr->{'page'})&&defined($info_hr->{'total_pages'});
                if (defined($info_hr->{'page'})&&defined($info_hr->{'per_page'})&&
                    defined($info_hr->{'total_count'})&&$info_hr->{'per_page'}>0) {
                    return $info_hr->{'page'}*$info_hr->{'per_page'}<
                        $info_hr->{'total_count'};
                }
            }
            my $items_ar=$self->response_value($body_hr, $items_path);
            return ref($items_ar) eq 'ARRAY'&&@$items_ar ? 1 : 0;
        };
    }
    return $self->{'core_or'}->paginate($path, %page_opt);

}


sub response_value {

    my ($self, $body_hr, $path)=@_;
    my $value_ref=$body_hr;
    foreach my $part (split(/\./, $path)) {
        return undef unless ref($value_ref) eq 'HASH';
        $value_ref=$value_ref->{$part};
    }
    return $value_ref;

}


sub account_path {


    #  Encode each account-scoped path component separately
    #
    my ($self, @part)=@_;
    die "account_id is required for this operation\n" unless defined($self->{'account_id'});
    return '/accounts/'.join('/', map { $self->segment($_) } ($self->{'account_id'}, @part));

}


sub segment {


    #  Percent-encode UTF-8 bytes, preserving only unreserved URL characters
    #
    my ($self, $value)=@_;
    die "path segment must be a non-empty scalar\n"
        unless defined($value)&&!ref($value)&&length($value);
    my $bytes="$value";
    utf8::encode($bytes) if utf8::is_utf8($bytes);
    $bytes=~s/([^A-Za-z0-9._~-])/sprintf('%%%02X', ord($1))/ge;
    return $bytes;

}


#  Load resource modules only when their accessor is used
#
sub workers { require Cloudflare::API::Workers; return Cloudflare::API::Workers->new($_[0]) }
sub r2      { require Cloudflare::API::R2;      return Cloudflare::API::R2->new($_[0]) }
sub kv      { require Cloudflare::API::KV;      return Cloudflare::API::KV->new($_[0]) }
sub d1      { require Cloudflare::API::D1;      return Cloudflare::API::D1->new($_[0]) }
sub queues  { require Cloudflare::API::Queues;  return Cloudflare::API::Queues->new($_[0]) }
sub hyperdrive { require Cloudflare::API::Hyperdrive; return Cloudflare::API::Hyperdrive->new($_[0]) }
sub secrets_store { require Cloudflare::API::SecretsStore; return Cloudflare::API::SecretsStore->new($_[0]) }
sub accounts { require Cloudflare::API::Accounts; return Cloudflare::API::Accounts->new($_[0]) }
sub zones    { require Cloudflare::API::Zones;    return Cloudflare::API::Zones->new($_[0]) }
__END__

=begin markdown

# Cloudflare::API #

# NAME #

Cloudflare::API - Perl client for Cloudflare resource management

# SYNOPSIS #

```perl
use Cloudflare::API;

my $api=Cloudflare::API->new(
    token      => $ENV{'CLOUDFLARE_API_TOKEN'},
    account_id => $ENV{'CLOUDFLARE_ACCOUNT_ID'}
);

my $buckets_ar=$api->r2()->list_buckets();
my $page_or=$api->r2()->list_buckets_page(per_page => 100);
my $page_hr=$api->r2()->list_buckets_page_response(per_page => 100);
my $response_or=$api->response('GET', '/accounts');
my $zone=$api->zones()->get($zone_id);
```

# DESCRIPTION #

`Cloudflare::API` supplies a bearer-authenticated HTTP client and accessors for the resource modules below. It requires Perl 5.10 or later, HTTP::API::Core 1.08 or later, and HTTPS support through IO::Socket::SSL. Resource objects share the same client and transport. The module manages resources through Cloudflare's REST API; it does not build Worker projects or perform R2 object transfers.

An API token is required. Supply `token` to `new()` or set `CLOUDFLARE_API_TOKEN`. Account-scoped methods also need `account_id` or `CLOUDFLARE_ACCOUNT_ID`; account and zone lookups work without a default account ID. Use a token with the permissions required by the selected Cloudflare operations.

# RESOURCE MODULES #

Each accessor creates a resource object. Consult its own man page for arguments, return values, and service-specific limits.

* **[Cloudflare::API::Accounts](API/Accounts.pm.md)** (`accounts()`) lists and retrieves accounts visible to the token.
* **[Cloudflare::API::Zones](API/Zones.pm.md)** (`zones()`) lists and retrieves zones.
* **[Cloudflare::API::Workers](API/Workers.pm.md)** (`workers()`) manages scripts, versions, assets, deployments, secrets, subdomains, and zone routes.
* **[Cloudflare::API::R2](API/R2.pm.md)** (`r2()`) manages R2 buckets.
* **[Cloudflare::API::KV](API/KV.pm.md)** (`kv()`) manages Workers KV namespaces, keys, and raw values.
* **[Cloudflare::API::D1](API/D1.pm.md)** (`d1()`) manages D1 databases and runs REST SQL queries.
* **[Cloudflare::API::Queues](API/Queues.pm.md)** (`queues()`) manages queues and consumers.
* **[Cloudflare::API::Hyperdrive](API/Hyperdrive.pm.md)** (`hyperdrive()`) manages database connection configurations.
* **[Cloudflare::API::SecretsStore](API/SecretsStore.pm.md)** (`secrets_store()`) manages stores and write-only secrets.
* **[Cloudflare::API::Error](API/Error.pm.md)** represents a Cloudflare JSON response reporting failure despite HTTP success.
* **[Cloudflare::API::Resource](API/Resource.pm.md)** is the shared base class for resource objects; applications normally use the accessors above rather than constructing it.

# METHODS #

* **new(%options)**

    Construct the client. `token` is a non-empty scalar and is mandatory after environment fallback. `account_id` is an optional non-empty scalar. `base_url` defaults to `https://api.cloudflare.com/client/v4` and must be an HTTPS URL. `timeout`, `retry`, `hooks`, and `transport` pass through to HTTP::API::Core. Unknown options and invalid credentials or URL cause an exception. Automatic retries are disabled by default (`attempts => 1`), since management writes can have side effects; pass `retry` explicitly to change that policy. Returns a `Cloudflare::API` object.

* **account_id()**

    Return the configured account ID, or `undef` if none was supplied.

* **workers(), r2(), kv(), d1(), queues(), hyperdrive(), secrets_store(), accounts(), zones()**

    Return a new object of the corresponding resource class, retaining this client. Resource modules are loaded when their accessor is called.

* **request($method, $path, %options)**

    Call a JSON endpoint and return the decoded Cloudflare response's `result`, which may be a hash reference, array reference, scalar, or `undef` according to the endpoint. `full_response => 1` returns the complete decoded response hash instead. Other options, including `query`, `json`, `content`, and `headers`, pass to HTTP::API::Core. The path must begin with exactly one slash and cannot be an absolute URL.

* **request_full($method, $path, %options)**

    Return the complete decoded Cloudflare JSON hash reference, including fields such as `success`, `errors`, `messages`, and `result_info` when Cloudflare supplies them. An empty successful body yields `{ success => 1, result => undef }`. A non-object JSON body causes an exception.

* **response($method, $path, %options)**

    Return an `HTTP::API::Core::Response` object without decoding the body. Use this for non-JSON responses. It enforces the same single-slash relative-path rule as `request()`.

* **raw_request($method, $path, %options)**

    Compatibility alias for `response()`.

* **account_path(@segments)**

    Return `/accounts/<configured ID>/...` with each component percent-encoded. It throws if no account ID was configured. Resource modules use this helper; callers using `response()` can use it to build account-scoped paths.

* **segment($value)**

    Return a non-empty scalar as one percent-encoded UTF-8 URL path component. It rejects references, empty strings, and undefined values. Encode dynamic components when building low-level paths yourself.

# RETURN VALUES AND ERRORS #

Named non-list resource methods normally return the JSON `result`; pass `full_response => 1` to retain the complete decoded Cloudflare response. List methods automatically follow every page reported by Cloudflare and return a flat array reference containing all items. This can issue many requests and holds the complete collection in memory.

Every list method has two additional forms. Its `_page()` form returns a lazy `HTTP::API::Core::Pagination` object whose `next()` method yields one item and fetches subsequent pages as needed; `all()` collects its remaining items. Its `_page_response()` form makes exactly one request and returns the complete decoded Cloudflare response hash, including `result` and any `result_info`. A supplied `page` or `cursor` selects the starting point for `list()` and `_page()`, but selects only that page for `_page_response()`. `full_response` is unavailable on the list method family.

List filters are named arguments sent as query parameters. Exceptions from HTTP or transport failures remain `HTTP::API::Core::Error` objects; their decoded Cloudflare body is available through `json()`. A successful HTTP status with `success: false` throws `Cloudflare::API::Error`, including while a paginator is fetching a later page. Input validation errors throw plain Perl exceptions. No resource write is automatically rolled back.

# SEE ALSO #

[Cloudflare API documentation](https://developers.cloudflare.com/api/), HTTP::API::Core, the resource module man pages above, and the `cloudflare-api` command.

# AUTHOR #

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Cloudflare::API.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Cloudflare::API - Perl client for Cloudflare resource management


=head1 SYNOPSIS


 use Cloudflare::API;

 my $api=Cloudflare::API->new(
     token      => $ENV{'CLOUDFLARE_API_TOKEN'},
     account_id => $ENV{'CLOUDFLARE_ACCOUNT_ID'}
 );

 my $buckets_ar=$api->r2()->list_buckets();
 my $page_or=$api->r2()->list_buckets_page(per_page => 100);
 my $page_hr=$api->r2()->list_buckets_page_response(per_page => 100);
 my $response_or=$api->response('GET', '/accounts');
 my $zone=$api->zones()->get($zone_id);

=head1 DESCRIPTION

C<Cloudflare::API> supplies a bearer-authenticated HTTP client and accessors for the resource modules below. It requires Perl 5.10 or later, HTTP::API::Core 1.08 or later, and HTTPS support through IO::Socket::SSL. Resource objects share the same client and transport. The module manages resources through Cloudflare's REST API; it does not build Worker projects or perform R2 object transfers.

An API token is required. Supply C<token> to C<new()> or set C<CLOUDFLARE_API_TOKEN>. Account-scoped methods also need C<account_id> or C<CLOUDFLARE_ACCOUNT_ID>; account and zone lookups work without a default account ID. Use a token with the permissions required by the selected Cloudflare operations.


=head1 RESOURCE MODULES

Each accessor creates a resource object. Consult its own man page for arguments, return values, and service-specific limits.

=over

=item *

B<L<Cloudflare::API::Accounts|Cloudflare::API::Accounts>> (C<accounts()>) lists and retrieves accounts visible to the token.


=item *

B<L<Cloudflare::API::Zones|Cloudflare::API::Zones>> (C<zones()>) lists and retrieves zones.


=item *

B<L<Cloudflare::API::Workers|Cloudflare::API::Workers>> (C<workers()>) manages scripts, versions, assets, deployments, secrets, subdomains, and zone routes.


=item *

B<L<Cloudflare::API::R2|Cloudflare::API::R2>> (C<r2()>) manages R2 buckets.


=item *

B<L<Cloudflare::API::KV|Cloudflare::API::KV>> (C<kv()>) manages Workers KV namespaces, keys, and raw values.


=item *

B<L<Cloudflare::API::D1|Cloudflare::API::D1>> (C<d1()>) manages D1 databases and runs REST SQL queries.


=item *

B<L<Cloudflare::API::Queues|Cloudflare::API::Queues>> (C<queues()>) manages queues and consumers.


=item *

B<L<Cloudflare::API::Hyperdrive|Cloudflare::API::Hyperdrive>> (C<hyperdrive()>) manages database connection configurations.


=item *

B<L<Cloudflare::API::SecretsStore|Cloudflare::API::SecretsStore>> (C<secrets_store()>) manages stores and write-only secrets.


=item *

B<L<Cloudflare::API::Error|Cloudflare::API::Error>> represents a Cloudflare JSON response reporting failure despite HTTP success.


=item *

B<L<Cloudflare::API::Resource|Cloudflare::API::Resource>> is the shared base class for resource objects; applications normally use the accessors above rather than constructing it.


=back


=head1 METHODS

=over

=item *

B<new(%options)>

Construct the client. C<token> is a non-empty scalar and is mandatory after environment fallback. C<account_id> is an optional non-empty scalar. C<base_url> defaults to C<https://api.cloudflare.com/client/v4> and must be an HTTPS URL. C<timeout>, C<retry>, C<hooks>, and C<transport> pass through to HTTP::API::Core. Unknown options and invalid credentials or URL cause an exception. Automatic retries are disabled by default (C<<< attempts => 1 >>>), since management writes can have side effects; pass C<retry> explicitly to change that policy. Returns a C<Cloudflare::API> object.



=item *

B<account_id()>

Return the configured account ID, or C<undef> if none was supplied.



=item *

B<workers(), r2(), kv(), d1(), queues(), hyperdrive(), secrets_store(), accounts(), zones()>

Return a new object of the corresponding resource class, retaining this client. Resource modules are loaded when their accessor is called.



=item *

B<request($method, $path, %options)>

Call a JSON endpoint and return the decoded Cloudflare response's C<result>, which may be a hash reference, array reference, scalar, or C<undef> according to the endpoint. C<<< full_response => 1 >>> returns the complete decoded response hash instead. Other options, including C<query>, C<json>, C<content>, and C<headers>, pass to HTTP::API::Core. The path must begin with exactly one slash and cannot be an absolute URL.



=item *

B<request_full($method, $path, %options)>

Return the complete decoded Cloudflare JSON hash reference, including fields such as C<success>, C<errors>, C<messages>, and C<result_info> when Cloudflare supplies them. An empty successful body yields C<<< { success => 1, result => undef } >>>. A non-object JSON body causes an exception.



=item *

B<response($method, $path, %options)>

Return an C<HTTP::API::Core::Response> object without decoding the body. Use this for non-JSON responses. It enforces the same single-slash relative-path rule as C<request()>.



=item *

B<raw_request($method, $path, %options)>

Compatibility alias for C<response()>.



=item *

B<account_path(@segments)>

Return C<<< /accounts/<configured ID>/... >>> with each component percent-encoded. It throws if no account ID was configured. Resource modules use this helper; callers using C<response()> can use it to build account-scoped paths.



=item *

B<segment($value)>

Return a non-empty scalar as one percent-encoded UTF-8 URL path component. It rejects references, empty strings, and undefined values. Encode dynamic components when building low-level paths yourself.



=back


=head1 RETURN VALUES AND ERRORS

Named non-list resource methods normally return the JSON C<result>; pass C<<< full_response => 1 >>> to retain the complete decoded Cloudflare response. List methods automatically follow every page reported by Cloudflare and return a flat array reference containing all items. This can issue many requests and holds the complete collection in memory.

Every list method has two additional forms. Its C<_page()> form returns a lazy C<HTTP::API::Core::Pagination> object whose C<next()> method yields one item and fetches subsequent pages as needed; C<all()> collects its remaining items. Its C<_page_response()> form makes exactly one request and returns the complete decoded Cloudflare response hash, including C<result> and any C<result_info>. A supplied C<page> or C<cursor> selects the starting point for C<list()> and C<_page()>, but selects only that page for C<_page_response()>. C<full_response> is unavailable on the list method family.

List filters are named arguments sent as query parameters. Exceptions from HTTP or transport failures remain C<HTTP::API::Core::Error> objects; their decoded Cloudflare body is available through C<json()>. A successful HTTP status with C<success: false> throws C<Cloudflare::API::Error>, including while a paginator is fetching a later page. Input validation errors throw plain Perl exceptions. No resource write is automatically rolled back.


=head1 SEE ALSO

L<Cloudflare API documentation|https://developers.cloudflare.com/api/>, HTTP::API::Core, the resource module man pages above, and the C<cloudflare-api> command.


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
