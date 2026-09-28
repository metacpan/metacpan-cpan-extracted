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
package Cloudflare::API::R2;


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


sub list_buckets {

    my ($self, %query)=@_;
    return $self->collect_list($self->list_buckets_page(%query));

}


sub list_buckets_page {

    my ($self, %query)=@_;
    return $self->list_pagination($self->api()->account_path('r2', 'buckets'), {
        mode => 'cursor', items => 'result.buckets'
    }, \%query);

}


sub list_buckets_page_response {

    my ($self, %query)=@_;
    return $self->list_response($self->api()->account_path('r2', 'buckets'), \%query);

}


sub get_bucket {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('GET', $self->api()->account_path('r2', 'buckets', $name),
        %opt);

}


sub create_bucket {


    #  Forward Cloudflare's bucket settings without changing their shape
    #
    my ($self, $body_hr, %opt)=@_;
    die "bucket body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('r2', 'buckets'),
        json => $body_hr, %opt);

}


sub delete_bucket {

    my ($self, $name, %opt)=@_;
    return $self->api()->request('DELETE', $self->api()->account_path('r2', 'buckets', $name),
        %opt);

}


sub update_bucket {

    my ($self, $name, $body_hr, %opt)=@_;
    die "bucket body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PATCH', $self->api()->account_path('r2', 'buckets', $name),
        json => $body_hr, %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::R2 #

# NAME #

Cloudflare::API::R2 - manage R2 buckets through Cloudflare's REST API

# SYNOPSIS #

```perl
my $r2=$api->r2();
my $bucket=$r2->create_bucket({ name => 'my-app-assets' });
my $buckets=$r2->list_buckets();
my $page_or=$r2->list_buckets_page(per_page => 100);
```

# DESCRIPTION #

Bucket management uses the account ID on `Cloudflare::API`. This module does not transfer bucket objects; use R2's S3-compatible API for object operations.

# METHODS #

* **list_buckets(%query)** — List every bucket. Named arguments become Cloudflare query parameters. The method follows cursor pages and returns one flat array reference; a large bucket set can require many requests and substantial memory.
* **list_buckets_page(%query)** — Return a lazy `HTTP::API::Core::Pagination` object. Use `next()` to consume one bucket at a time. A supplied `cursor` selects the starting page.
* **list_buckets_page_response(%query)** — Make one list request and return the complete decoded Cloudflare response hash, including the bucket array and any cursor in `result_info`.
* **get_bucket($name, %options)** — Retrieve a bucket by name and return its `result`.
* **create_bucket(\%body, %options)** — POST a bucket definition, normally including `name`, and return its `result`. Other fields pass through to Cloudflare.
* **update_bucket($name, \%body, %options)** — PATCH a bucket and return its `result`.
* **delete_bucket($name, %options)** — DELETE a bucket and return the endpoint's `result`, possibly `undef` for an empty body.

Non-list JSON methods accept `full_response => 1`. Bucket names are percent-encoded as path components. Create and update bodies must be hash references.

# ERRORS #

Missing account context, invalid names or bodies, HTTP and transport failures, and Cloudflare response failures cause exceptions as described in `Cloudflare::API`.

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

Cloudflare::API::R2 - manage R2 buckets through Cloudflare's REST API


=head1 SYNOPSIS


 my $r2=$api->r2();
 my $bucket=$r2->create_bucket({ name => 'my-app-assets' });
 my $buckets=$r2->list_buckets();
 my $page_or=$r2->list_buckets_page(per_page => 100);

=head1 DESCRIPTION

Bucket management uses the account ID on C<Cloudflare::API>. This module does not transfer bucket objects; use R2's S3-compatible API for object operations.


=head1 METHODS

=over

=item *

B<list_buckets(%query)> — List every bucket. Named arguments become Cloudflare query parameters. The method follows cursor pages and returns one flat array reference; a large bucket set can require many requests and substantial memory.


=item *

B<list_buckets_page(%query)> — Return a lazy C<HTTP::API::Core::Pagination> object. Use C<next()> to consume one bucket at a time. A supplied C<cursor> selects the starting page.


=item *

B<list_buckets_page_response(%query)> — Make one list request and return the complete decoded Cloudflare response hash, including the bucket array and any cursor in C<result_info>.


=item *

B<get_bucket($name, %options)> — Retrieve a bucket by name and return its C<result>.


=item *

B<create_bucket(\%body, %options)> — POST a bucket definition, normally including C<name>, and return its C<result>. Other fields pass through to Cloudflare.


=item *

B<update_bucket($name, \%body, %options)> — PATCH a bucket and return its C<result>.


=item *

B<delete_bucket($name, %options)> — DELETE a bucket and return the endpoint's C<result>, possibly C<undef> for an empty body.


=back

Non-list JSON methods accept C<<< full_response => 1 >>>. Bucket names are percent-encoded as path components. Create and update bodies must be hash references.


=head1 ERRORS

Missing account context, invalid names or bodies, HTTP and transport failures, and Cloudflare response failures cause exceptions as described in C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
