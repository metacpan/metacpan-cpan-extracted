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
package Cloudflare::API::Zones;


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
$VERSION='1.011';


#  All done. Positive return
#
1;


#============================================================================


sub list {

    my ($self, %query)=@_;
    return $self->collect_list($self->list_page(%query));

}


sub list_page {

    my ($self, %query)=@_;
    return $self->list_pagination('/zones', { mode => 'page' }, \%query);

}


sub list_page_response {

    my ($self, %query)=@_;
    return $self->list_response('/zones', \%query);

}


sub get {


    #  Zone lookup needs no account ID configured on the client
    #
    my ($self, $zone_id, %opt)=@_;
    return $self->api()->request('GET', '/zones/'.$self->api()->segment($zone_id),
        %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Zones #

# NAME #

Cloudflare::API::Zones - list and retrieve Cloudflare zones

# SYNOPSIS #

```perl
my $zones=$api->zones()->list(status => 'active');
my $zone=$api->zones()->get($zone_id);
```

# DESCRIPTION #

Zone lookups use the token configured on `Cloudflare::API` and do not require its default account ID. Worker routes are managed by `Cloudflare::API::Workers` using an explicit zone ID.

# METHODS #

* **list(%query)** — List every visible zone. Named arguments become Cloudflare query parameters. The method follows all pages and returns one flat array reference; a large zone set can require many requests and substantial memory.
* **list_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object for the zone list. Use `next()` to consume one zone at a time or `all()` to collect the remaining zones.
* **list_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including `result_info` when Cloudflare supplies it.
* **get($zone_id, %options)** — Retrieve one zone by ID. Returns the decoded zone `result`. The ID is percent-encoded as a path component; `full_response => 1` returns the complete decoded Cloudflare response.

# ERRORS #

See `Cloudflare::API` for HTTP, transport, Cloudflare response, and invalid path-component exceptions.

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

Cloudflare::API::Zones - list and retrieve Cloudflare zones


=head1 SYNOPSIS


 my $zones=$api->zones()->list(status => 'active');
 my $zone=$api->zones()->get($zone_id);

=head1 DESCRIPTION

Zone lookups use the token configured on C<Cloudflare::API> and do not require its default account ID. Worker routes are managed by C<Cloudflare::API::Workers> using an explicit zone ID.


=head1 METHODS

=over

=item *

B<list(%query)> — List every visible zone. Named arguments become Cloudflare query parameters. The method follows all pages and returns one flat array reference; a large zone set can require many requests and substantial memory.


=item *

B<list_page(%query)> — Return a lazy C<HTTP::API::Core::Pagination> object for the zone list. Use C<next()> to consume one zone at a time or C<all()> to collect the remaining zones.


=item *

B<list_page_response(%query)> — Make one list request and return the complete decoded Cloudflare response hash, including C<result_info> when Cloudflare supplies it.


=item *

B<get($zone_id, %options)> — Retrieve one zone by ID. Returns the decoded zone C<result>. The ID is percent-encoded as a path component; C<<< full_response => 1 >>> returns the complete decoded Cloudflare response.


=back


=head1 ERRORS

See C<Cloudflare::API> for HTTP, transport, Cloudflare response, and invalid path-component exceptions.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>, L<Cloudflare::API::Workers|Cloudflare::API::Workers>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
