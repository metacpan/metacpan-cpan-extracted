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
package Cloudflare::API::Queues;


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


sub list_queues {


    #  Preserve result_info for callers that request the full response
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('queues'),
        query => \%query, full_response => $full_response);

}


sub get_queue {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('GET', $self->api()->account_path('queues', $id),
        %opt);

}


sub create_queue {

    my ($self, $body_hr, %opt)=@_;
    die "queue body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('queues'),
        json => $body_hr, %opt);

}


sub delete_queue {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('DELETE', $self->api()->account_path('queues', $id),
        %opt);

}


sub update_queue {

    my ($self, $id, $body_hr, %opt)=@_;
    die "queue body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PATCH', $self->api()->account_path('queues', $id),
        json => $body_hr, %opt);

}


sub list_consumers {


    #  Consumer listing is scoped to a queue, not directly to the account
    #
    my ($self, $queue_id, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('queues', $queue_id, 'consumers'),
        query => \%query, full_response => $full_response);

}


sub create_consumer {

    my ($self, $queue_id, $body_hr, %opt)=@_;
    die "consumer body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('queues', $queue_id, 'consumers'),
        json => $body_hr, %opt);

}


sub delete_consumer {

    my ($self, $queue_id, $consumer_id, %opt)=@_;
    return $self->api()->request('DELETE',
        $self->api()->account_path('queues', $queue_id, 'consumers', $consumer_id), %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::Queues #

# NAME #

Cloudflare::API::Queues - manage queues and their consumers

# SYNOPSIS #

```perl
my $queues=$api->queues()->list_queues();
my $consumers=$api->queues()->list_consumers($queue_id);
```

# DESCRIPTION #

These methods use the account ID configured on `Cloudflare::API`. They manage queue resources and consumers, including Worker consumers; they do not push or pull messages.

# METHODS #

* **list_queues(%query)** — List queues using named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **get_queue($id, %options)** — Retrieve a queue by ID and return its `result`.
* **create_queue(\%body, %options)** — POST a queue definition, normally including `queue_name`, and return its `result`.
* **update_queue($id, \%body, %options)** — PATCH a queue and return its `result`.
* **delete_queue($id, %options)** — DELETE a queue and return the endpoint's `result`, possibly `undef` for an empty body.
* **list_consumers($queue_id, %query)** — List consumers for one queue, using named query filters. Returns `result`; `full_response => 1` retains pagination information.
* **create_consumer($queue_id, \%body, %options)** — POST a consumer definition and return its `result`.
* **delete_consumer($queue_id, $consumer_id, %options)** — DELETE a consumer and return the endpoint's `result`, possibly `undef` for an empty body.

Every JSON method accepts `full_response => 1`. IDs are percent-encoded. Create and update bodies must be hash references.

# ERRORS #

Missing account context, invalid IDs or bodies, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in `Cloudflare::API`.

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

Cloudflare::API::Queues - manage queues and their consumers


=head1 SYNOPSIS


 my $queues=$api->queues()->list_queues();
 my $consumers=$api->queues()->list_consumers($queue_id);

=head1 DESCRIPTION

These methods use the account ID configured on C<Cloudflare::API>. They manage queue resources and consumers, including Worker consumers; they do not push or pull messages.


=head1 METHODS

=over

=item *

B<list_queues(%query)> — List queues using named query filters. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<get_queue($id, %options)> — Retrieve a queue by ID and return its C<result>.


=item *

B<create_queue(\%body, %options)> — POST a queue definition, normally including C<queue_name>, and return its C<result>.


=item *

B<update_queue($id, \%body, %options)> — PATCH a queue and return its C<result>.


=item *

B<delete_queue($id, %options)> — DELETE a queue and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<list_consumers($queue_id, %query)> — List consumers for one queue, using named query filters. Returns C<result>; C<<< full_response => 1 >>> retains pagination information.


=item *

B<create_consumer($queue_id, \%body, %options)> — POST a consumer definition and return its C<result>.


=item *

B<delete_consumer($queue_id, $consumer_id, %options)> — DELETE a consumer and return the endpoint's C<result>, possibly C<undef> for an empty body.


=back

Every JSON method accepts C<<< full_response => 1 >>>. IDs are percent-encoded. Create and update bodies must be hash references.


=head1 ERRORS

Missing account context, invalid IDs or bodies, HTTP and transport failures, and Cloudflare envelope failures cause exceptions as described in C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
