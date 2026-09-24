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
package Cloudflare::API::Hyperdrive;


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


sub list_configs {

    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('hyperdrive', 'configs'),
        query => \%query, full_response => $full_response);

}


sub get_config {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('GET',
        $self->api()->account_path('hyperdrive', 'configs', $id), %opt);

}


sub create_config {

    my ($self, $body_hr, %opt)=@_;
    die "config body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST',
        $self->api()->account_path('hyperdrive', 'configs'), json => $body_hr, %opt);

}


sub replace_config {

    my ($self, $id, $body_hr, %opt)=@_;
    die "config body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PUT',
        $self->api()->account_path('hyperdrive', 'configs', $id), json => $body_hr, %opt);

}


sub update_config {

    my ($self, $id, $body_hr, %opt)=@_;
    die "config body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PATCH',
        $self->api()->account_path('hyperdrive', 'configs', $id), json => $body_hr, %opt);

}


sub delete_config {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('hyperdrive', 'configs', $id), %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Hyperdrive #

# NAME #

Cloudflare::API::Hyperdrive - manage Hyperdrive connection configurations

# SYNOPSIS #

```perl
my $configs=$api->hyperdrive()->list_configs();
my $config=$api->hyperdrive()->get_config($config_id);
```

# DESCRIPTION #

These account-scoped REST methods manage Hyperdrive configurations for external PostgreSQL or MySQL databases. They do not run SQL. Applications query through a Worker Hyperdrive binding and a database driver. Cloudflare's origin password is write-only; keep request bodies and credentials out of logs and source control.

# METHODS #

* **list_configs(%query)** — List configurations. Named filters become query parameters. Returns `result`; `full_response => 1` retains pagination information.
* **get_config($id, %options)** — Retrieve a configuration by ID and return its `result`.
* **create_config(\%body, %options)** — POST a Cloudflare configuration body and return its `result`.
* **replace_config($id, \%body, %options)** — PUT a replacement configuration and return its `result`.
* **update_config($id, \%body, %options)** — PATCH a configuration and return its `result`.
* **delete_config($id, %options)** — DELETE a configuration and return the endpoint's `result`, possibly `undef` for an empty body.

Every JSON method accepts `full_response => 1` for the complete decoded envelope. IDs are percent-encoded. Write bodies must be hash references; Cloudflare defines the accepted fields.

# ERRORS #

Missing account context, invalid bodies or IDs, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in `Cloudflare::API`.

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

Cloudflare::API::Hyperdrive - manage Hyperdrive connection configurations


=head1 SYNOPSIS


 my $configs=$api->hyperdrive()->list_configs();
 my $config=$api->hyperdrive()->get_config($config_id);

=head1 DESCRIPTION

These account-scoped REST methods manage Hyperdrive configurations for external PostgreSQL or MySQL databases. They do not run SQL. Applications query through a Worker Hyperdrive binding and a database driver. Cloudflare's origin password is write-only; keep request bodies and credentials out of logs and source control.


=head1 METHODS

=over

=item *

B<list_configs(%query)> — List configurations. Named filters become query parameters. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_config($id, %options)> — Retrieve a configuration by ID and return its C<result>.


=item *

B<create_config(\%body, %options)> — POST a Cloudflare configuration body and return its C<result>.


=item *

B<replace_config($id, \%body, %options)> — PUT a replacement configuration and return its C<result>.


=item *

B<update_config($id, \%body, %options)> — PATCH a configuration and return its C<result>.


=item *

B<delete_config($id, %options)> — DELETE a configuration and return the endpoint's C<result>, possibly C<undef> for an empty body.


=back

Every JSON method accepts C<<< full_response => 1 >>> for the complete decoded envelope. IDs are percent-encoded. Write bodies must be hash references; Cloudflare defines the accepted fields.


=head1 ERRORS

Missing account context, invalid bodies or IDs, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
