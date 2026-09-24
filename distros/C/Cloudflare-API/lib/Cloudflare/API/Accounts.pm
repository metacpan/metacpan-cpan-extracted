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
package Cloudflare::API::Accounts;


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


sub list {


    #  Pass list filters as query parameters, keeping envelope metadata optional
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', '/accounts', query => \%query,
        full_response => $full_response);

}


sub get {


    #  Account lookup needs no account ID configured on the client
    #
    my ($self, $account_id, %opt)=@_;
    return $self->api()->request('GET', '/accounts/'.$self->api()->segment($account_id),
        %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Accounts #

# NAME #

Cloudflare::API::Accounts - list and retrieve Cloudflare accounts

# SYNOPSIS #

```perl
my $accounts=$api->accounts()->list();
my $account=$api->accounts()->get($account_id);
```

# DESCRIPTION #

Account lookups use the token configured on `Cloudflare::API`. They do not require a default account ID on the parent client.

# METHODS #

* **list(%query)** — List visible accounts. Named arguments become Cloudflare query parameters. Returns the decoded `result`; use `full_response => 1` to retain the envelope and pagination `result_info`.
* **get($account_id, %options)** — Retrieve one account by ID. Returns the decoded account `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the envelope.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare envelope, and invalid path-component exceptions.

# SEE ALSO #

[Cloudflare::API](../API.pm.md), [Cloudflare::API::Zones](Zones.pm.md)

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

Cloudflare::API::Accounts - list and retrieve Cloudflare accounts


=head1 SYNOPSIS


 my $accounts=$api->accounts()->list();
 my $account=$api->accounts()->get($account_id);

=head1 DESCRIPTION

Account lookups use the token configured on C<Cloudflare::API>. They do not require a default account ID on the parent client.


=head1 METHODS

=over

=item *

B<list(%query)> — List visible accounts. Named arguments become Cloudflare query parameters. Returns the decoded C<result>; use C<<< full_response => 1 >>> to retain the envelope and pagination C<result_info>.


=item *

B<get($account_id, %options)> — Retrieve one account by ID. Returns the decoded account C<result>. The ID is percent-encoded as a path component; C<<< full_response => 1 >>> returns the envelope.


=back


=head1 ERRORS

See C<Cloudflare::API> for HTTP, transport, Cloudflare envelope, and invalid path-component exceptions.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>, L<Cloudflare::API::Zones|Cloudflare::API::Zones>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
