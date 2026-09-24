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
package Cloudflare::API::SecretsStore;


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


sub list_stores {

    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('secrets_store', 'stores'),
        query => \%query, full_response => $full_response);

}


sub get_store {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('secrets_store', 'stores', $id), %opt);

}


sub create_store {

    my ($self, $body_hr, %opt)=@_;
    die "store body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST',
        $self->api()->account_path('secrets_store', 'stores'), json => $body_hr, %opt);

}


sub delete_store {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('secrets_store', 'stores', $id), %opt);

}


sub list_secrets {

    my ($self, $store_id, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET',
        $self->api()->account_path('secrets_store', 'stores', $store_id, 'secrets'),
        query => \%query, full_response => $full_response);

}


sub get_secret {

    my ($self, $store_id, $secret_id, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('secrets_store', 'stores', $store_id, 'secrets', $secret_id),
        %opt);

}


sub create_secret {


    #  Cloudflare accepts an array even when creating one secret
    #
    my ($self, $store_id, $body_ar, %opt)=@_;
    die "secret body must be a non-empty array reference\n"
        unless ref($body_ar) eq 'ARRAY'&&@$body_ar;
    return $self->api()->request('POST',
        $self->api()->account_path('secrets_store', 'stores', $store_id, 'secrets'),
        json => $body_ar, %opt);

}


sub update_secret {

    my ($self, $store_id, $secret_id, $body_hr, %opt)=@_;
    die "secret body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PATCH',
        $self->api()->account_path('secrets_store', 'stores', $store_id, 'secrets', $secret_id),
        json => $body_hr, %opt);

}


sub delete_secret {

    my ($self, $store_id, $secret_id, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('secrets_store', 'stores', $store_id, 'secrets', $secret_id),
        %opt);

}


sub get_quota {

    my ($self, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('secrets_store', 'quota'), %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::SecretsStore #

# NAME #

Cloudflare::API::SecretsStore - manage Cloudflare Secrets Store resources

# SYNOPSIS #

```perl
my $store=$api->secrets_store();
my $stores=$store->list_stores();
my $secret=$store->create_secret($store_id, [{
    name   => 'API_KEY',
    value  => $secret_value,
    scopes => ['workers']
}]);
```

# DESCRIPTION #

These account-scoped methods manage stores, secret metadata, write-only secret values, and quota. Cloudflare does not return a secret's value through `get_secret()`. Keep values out of logs, command lines, and source control.

# METHODS #

* **list_stores(%query)** — List stores with named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **get_store($id, %options)** — Retrieve a store by ID and return its `result`.
* **create_store(\%body, %options)** — POST a store definition and return its `result`.
* **delete_store($id, %options)** — DELETE a store and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_secrets($store_id, %query)** — List secrets in one store with named query filters. Returns metadata in `result`; `full_response => 1` retains pagination information.
* **get_secret($store_id, $secret_id, %options)** — Return one secret's metadata in `result`; its value is not available.
* **create_secret($store_id, \@secrets, %options)** — POST a non-empty array reference, even when creating one secret. Each entry should supply `name`, `value`, and `scopes` such as `['workers']`; `comment` is optional. Returns `result`.
* **update_secret($store_id, $secret_id, \%body, %options)** — PATCH a secret with fields such as `value`, `scopes`, or `comment`. Returns `result`.
* **delete_secret($store_id, $secret_id, %options)** — DELETE a secret and return the endpoint's `result`, possibly `undef` for an empty body.
* **get_quota(%options)** — Retrieve the account's Secrets Store usage and return `result`.

Every JSON method accepts `full_response => 1` for the decoded envelope. IDs are percent-encoded as path components. Create-store and update-secret bodies must be hash references; `create_secret()` requires a non-empty array reference. The module passes accepted field details through to Cloudflare.

# ERRORS #

Missing account context, invalid identifiers or body shapes, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in `Cloudflare::API`.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Workers](Workers.pm.md)

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

Cloudflare::API::SecretsStore - manage Cloudflare Secrets Store resources


=head1 SYNOPSIS


 my $store=$api->secrets_store();
 my $stores=$store->list_stores();
 my $secret=$store->create_secret($store_id, [{
     name   => 'API_KEY',
     value  => $secret_value,
     scopes => ['workers']
 }]);

=head1 DESCRIPTION

These account-scoped methods manage stores, secret metadata, write-only secret values, and quota. Cloudflare does not return a secret's value through C<get_secret()>. Keep values out of logs, command lines, and source control.


=head1 METHODS

=over

=item *

B<list_stores(%query)> — List stores with named query filters. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_store($id, %options)> — Retrieve a store by ID and return its C<result>.


=item *

B<create_store(\%body, %options)> — POST a store definition and return its C<result>.


=item *

B<delete_store($id, %options)> — DELETE a store and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<list_secrets($store_id, %query)> — List secrets in one store with named query filters. Returns metadata in C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_secret($store_id, $secret_id, %options)> — Return one secret's metadata in C<result>; its value is not available.


=item *

B<create_secret($store_id, \@secrets, %options)> — POST a non-empty array reference, even when creating one secret. Each entry should supply C<name>, C<value>, and C<scopes> such as C<['workers']>; C<comment> is optional. Returns C<result>.


=item *

B<update_secret($store_id, $secret_id, \%body, %options)> — PATCH a secret with fields such as C<value>, C<scopes>, or C<comment>. Returns C<result>.


=item *

B<delete_secret($store_id, $secret_id, %options)> — DELETE a secret and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<get_quota(%options)> — Retrieve the account's Secrets Store usage and return C<result>.


=back

Every JSON method accepts C<<< full_response => 1 >>> for the decoded envelope. IDs are percent-encoded as path components. Create-store and update-secret bodies must be hash references; C<create_secret()> requires a non-empty array reference. The module passes accepted field details through to Cloudflare.


=head1 ERRORS

Missing account context, invalid identifiers or body shapes, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>, L<Cloudflare::API::Workers|Cloudflare::API::Workers>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
