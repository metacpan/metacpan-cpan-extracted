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
package Cloudflare::API::KV;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw(@ISA $VERSION);
use warnings;


#  Cloudflare::API modules and inheritance
#
use Cloudflare::API::Resource;
@ISA=qw(Cloudflare::API::Resource);


#  Version information
#
$VERSION='1.010';


#  All done. Positive return
#
1;


#============================================================================


sub list_namespaces {


    #  Preserve result_info for callers that request the full response
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('storage', 'kv', 'namespaces'),
        query => \%query, full_response => $full_response);

}


sub get_namespace {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('GET', $self->api()->account_path('storage', 'kv', 'namespaces', $id),
        %opt);

}


sub create_namespace {


    #  Forward the namespace body after checking its expected shape
    #
    my ($self, $body_hr, %opt)=@_;
    die "namespace body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('storage', 'kv', 'namespaces'),
        json => $body_hr, %opt);

}


sub rename_namespace {

    my ($self, $id, $body_hr, %opt)=@_;
    die "namespace body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PUT', $self->api()->account_path('storage', 'kv', 'namespaces', $id),
        json => $body_hr, %opt);

}


sub delete_namespace {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('DELETE', $self->api()->account_path('storage', 'kv', 'namespaces', $id),
        %opt);

}


sub list_keys {

    my ($self, $id, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('storage', 'kv', 'namespaces', $id, 'keys'),
        query => \%query, full_response => $full_response);

}


sub get_value {


    #  KV values are bytes rather than Cloudflare JSON envelopes
    #
    my ($self, $id, $key, %opt)=@_;
    delete($opt{'full_response'});
    die "unknown get option: $_\n" foreach sort(keys(%opt));
    my $response_or=$self->api()->raw_request('GET',
        $self->api()->account_path('storage', 'kv', 'namespaces', $id, 'values', $key));
    return $response_or->content();

}


sub put_value {


    #  A plain request body preserves arbitrary value bytes
    #
    my ($self, $id, $key, $value, %opt)=@_;
    die "value must be a scalar\n" unless defined($value)&&!ref($value);
    my $full_response=delete($opt{'full_response'});
    my %query;
    foreach my $name (qw(expiration expiration_ttl)) {
        $query{$name}=delete($opt{$name}) if exists($opt{$name});
    }
    die "unknown put option: $_\n" foreach sort(keys(%opt));
    die "expiration and expiration_ttl are mutually exclusive\n"
        if exists($query{'expiration'})&&exists($query{'expiration_ttl'});
    utf8::encode($value) if utf8::is_utf8($value);
    return $self->api()->request('PUT',
        $self->api()->account_path('storage', 'kv', 'namespaces', $id, 'values', $key),
        content => $value, headers => { 'Content-Type' => 'application/octet-stream' },
        query => \%query, full_response => $full_response);

}


sub delete_value {

    my ($self, $id, $key, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('storage', 'kv', 'namespaces', $id, 'values', $key), %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::KV #

# NAME #

Cloudflare::API::KV - manage Workers KV namespaces, keys, and values

# SYNOPSIS #

```perl
my $kv=$api->kv();
my $namespace=$kv->create_namespace({ title => 'my-cache' });
$kv->put_value($namespace->{'id'}, 'greeting', 'hello');
my $bytes=$kv->get_value($namespace->{'id'}, 'greeting');
```

# DESCRIPTION #

All operations use the account ID configured on `Cloudflare::API`. Namespace and key-list methods use Cloudflare JSON responses. Values are handled as raw bytes; they are not JSON-decoded by `get_value()`.

# METHODS #

* **list_namespaces(%query)** — List namespaces with named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **get_namespace($id, %options)** — Retrieve a namespace by ID and return its `result`.
* **create_namespace(\%body, %options)** — POST a namespace definition, normally `{ title => '...' }`, and return its `result`.
* **rename_namespace($id, \%body, %options)** — PUT a namespace definition with the new `title` and return its `result`.
* **delete_namespace($id, %options)** — DELETE a namespace and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_keys($namespace_id, %query)** — List keys in a namespace. Query options such as `prefix`, `limit`, and `cursor` pass to Cloudflare. Returns `result`; `full_response => 1` retains the cursor and other envelope fields.
* **get_value($namespace_id, $key)** — Return the raw response content as a byte string. This method has no `full_response` mode or other request options.
* **put_value($namespace_id, $key, $value, %options)** — PUT a scalar value as raw content and return the decoded JSON `result`. A Perl character string is encoded as UTF-8 bytes. Optional `expiration` and `expiration_ttl` become query parameters and are mutually exclusive. `full_response => 1` retains the envelope. A write replaces the existing expiration and metadata; this convenience method does not support metadata-bearing writes.
* **delete_value($namespace_id, $key, %options)** — DELETE one key and return the endpoint's `result`, possibly `undef` for an empty body.

JSON methods accept `full_response => 1` for the complete envelope. Namespace IDs and key names are percent-encoded as path components. Create and rename bodies must be hash references; `put_value()` requires a defined non-reference scalar.

# ERRORS #

Missing account context, invalid identifiers, bodies, values, or options cause Perl exceptions. HTTP, transport, and Cloudflare envelope failures follow `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md)

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

Cloudflare::API::KV - manage Workers KV namespaces, keys, and values


=head1 SYNOPSIS


 my $kv=$api->kv();
 my $namespace=$kv->create_namespace({ title => 'my-cache' });
 $kv->put_value($namespace->{'id'}, 'greeting', 'hello');
 my $bytes=$kv->get_value($namespace->{'id'}, 'greeting');

=head1 DESCRIPTION

All operations use the account ID configured on C<Cloudflare::API>. Namespace and key-list methods use Cloudflare JSON responses. Values are handled as raw bytes; they are not JSON-decoded by C<get_value()>.


=head1 METHODS

=over

=item *

B<list_namespaces(%query)> — List namespaces with named query filters. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_namespace($id, %options)> — Retrieve a namespace by ID and return its C<result>.


=item *

B<create_namespace(\%body, %options)> — POST a namespace definition, normally C<<< { title => '...' } >>>, and return its C<result>.


=item *

B<rename_namespace($id, \%body, %options)> — PUT a namespace definition with the new C<title> and return its C<result>.


=item *

B<delete_namespace($id, %options)> — DELETE a namespace and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<list_keys($namespace_id, %query)> — List keys in a namespace. Query options such as C<prefix>, C<limit>, and C<cursor> pass to Cloudflare. Returns C<result>; C<<< full_response => 1 >>> retains the cursor and other envelope fields.


=item *

B<get_value($namespace_id, $key)> — Return the raw response content as a byte string. This method has no C<full_response> mode or other request options.


=item *

B<put_value($namespace_id, $key, $value, %options)> — PUT a scalar value as raw content and return the decoded JSON C<result>. A Perl character string is encoded as UTF-8 bytes. Optional C<expiration> and C<expiration_ttl> become query parameters and are mutually exclusive. C<<< full_response => 1 >>> retains the envelope. A write replaces the existing expiration and metadata; this convenience method does not support metadata-bearing writes.


=item *

B<delete_value($namespace_id, $key, %options)> — DELETE one key and return the endpoint's C<result>, possibly C<undef> for an empty body.


=back

JSON methods accept C<<< full_response => 1 >>> for the complete envelope. Namespace IDs and key names are percent-encoded as path components. Create and rename bodies must be hash references; C<put_value()> requires a defined non-reference scalar.


=head1 ERRORS

Missing account context, invalid identifiers, bodies, values, or options cause Perl exceptions. HTTP, transport, and Cloudflare envelope failures follow C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
