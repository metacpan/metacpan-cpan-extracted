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
package Cloudflare::API::D1;


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


sub list_databases {


    #  Preserve result_info for callers that request the full response
    #
    my ($self, %query)=@_;
    my $full_response=delete($query{'full_response'});
    return $self->api()->request('GET', $self->api()->account_path('d1', 'database'),
        query => \%query, full_response => $full_response);

}


sub get_database {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('GET', $self->api()->account_path('d1', 'database', $id),
        %opt);

}


sub create_database {

    my ($self, $body_hr, %opt)=@_;
    die "database body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('d1', 'database'),
        json => $body_hr, %opt);

}


sub delete_database {

    my ($self, $id, %opt)=@_;
    return $self->api()->request('DELETE', $self->api()->account_path('d1', 'database', $id),
        %opt);

}


sub update_database {

    my ($self, $id, $body_hr, %opt)=@_;
    die "database body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('PATCH', $self->api()->account_path('d1', 'database', $id),
        json => $body_hr, %opt);

}


sub query_database {


    #  Pass SQL and its parameters in the caller's supplied request body
    #
    my ($self, $id, $body_hr, %opt)=@_;
    die "query body must be a hash reference\n" unless ref($body_hr) eq 'HASH';
    return $self->api()->request('POST', $self->api()->account_path('d1', 'database', $id, 'query'),
        json => $body_hr, %opt);

}


sub query_sql {


    #  Keep bound values separate from SQL text
    #
    my ($self, $id, $sql, @arg)=@_;
    my $params_ar=@arg % 2 ? shift(@arg) : undef;
    my %opt=@arg;
    die "sql must be a non-empty scalar\n" unless defined($sql)&&!ref($sql)&&length($sql);
    die "params must be an array reference\n"
        if defined($params_ar)&&ref($params_ar) ne 'ARRAY';
    my %body=(sql => $sql);
    $body{'params'}=$params_ar if defined($params_ar);
    return $self->query_database($id, \%body, %opt);

}
__END__

=encoding utf8

=begin markdown

# Cloudflare::API::D1 #

# NAME #

Cloudflare::API::D1 - manage D1 databases and run REST SQL queries

# SYNOPSIS #

```perl
my $d1=$api->d1();
my $databases=$d1->list_databases();
my $rows=$d1->query_sql($database_id,
    'SELECT * FROM items WHERE id = ?', [$item_id]);
```

# DESCRIPTION #

All methods use the account ID configured on `Cloudflare::API`. The query methods call Cloudflare's D1 REST query endpoint; they do not provide a DBI connection or migration system. SQL parameters remain separate from SQL text.

# METHODS #

* **list_databases(%query)** — List databases, passing named filters as query parameters. Returns `result`; `full_response => 1` retains the envelope and pagination information.
* **get_database($id, %options)** — Retrieve a database by ID and return its `result`.
* **create_database(\%body, %options)** — POST a database definition, normally including `name`. Returns the created `result`.
* **update_database($id, \%body, %options)** — PATCH a database and return its `result`.
* **delete_database($id, %options)** — DELETE a database and return the endpoint's `result`, possibly `undef` for an empty body.
* **query_database($id, \%body, %options)** — POST a D1 query body such as `{ sql => 'SELECT 1', params => [] }`. Returns Cloudflare's `result` without reshaping it.
* **query_sql($id, $sql, \@params, %options)** — Build a single-statement body and call `query_database()`. `\@params` is optional; omit it for a query without bound values. Returns D1's query result array, whose entries can contain `results`, `meta`, and `success`.

For every JSON method, `full_response => 1` returns the entire decoded envelope. Database IDs are percent-encoded in paths. Body arguments must be hash references; `query_sql()` also requires a non-empty scalar SQL string and, when supplied, an array reference of parameters.

# ERRORS #

Invalid bodies or SQL arguments cause Perl exceptions. HTTP, transport, and Cloudflare envelope failures follow the rules in `Cloudflare::API`.

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

Cloudflare::API::D1 - manage D1 databases and run REST SQL queries


=head1 SYNOPSIS


 my $d1=$api->d1();
 my $databases=$d1->list_databases();
 my $rows=$d1->query_sql($database_id,
     'SELECT * FROM items WHERE id = ?', [$item_id]);

=head1 DESCRIPTION

All methods use the account ID configured on C<Cloudflare::API>. The query methods call Cloudflare's D1 REST query endpoint; they do not provide a DBI connection or migration system. SQL parameters remain separate from SQL text.


=head1 METHODS

=over

=item *

B<list_databases(%query)> — List databases, passing named filters as query parameters. Returns C<result>; C<<< full_response => 1 >>> retains the envelope and pagination information.


=item *

B<get_database($id, %options)> — Retrieve a database by ID and return its C<result>.


=item *

B<create_database(\%body, %options)> — POST a database definition, normally including C<name>. Returns the created C<result>.


=item *

B<update_database($id, \%body, %options)> — PATCH a database and return its C<result>.


=item *

B<delete_database($id, %options)> — DELETE a database and return the endpoint's C<result>, possibly C<undef> for an empty body.


=item *

B<query_database($id, \%body, %options)> — POST a D1 query body such as C<<< { sql => 'SELECT 1', params => [] } >>>. Returns Cloudflare's C<result> without reshaping it.


=item *

B<query_sql($id, $sql, \@params, %options)> — Build a single-statement body and call C<query_database()>. C<\@params> is optional; omit it for a query without bound values. Returns D1's query result array, whose entries can contain C<results>, C<meta>, and C<success>.


=back

For every JSON method, C<<< full_response => 1 >>> returns the entire decoded envelope. Database IDs are percent-encoded in paths. Body arguments must be hash references; C<query_sql()> also requires a non-empty scalar SQL string and, when supplied, an array reference of parameters.


=head1 ERRORS

Invalid bodies or SQL arguments cause Perl exceptions. HTTP, transport, and Cloudflare envelope failures follow the rules in C<Cloudflare::API>.


=head1 SEE ALSO

L<Cloudflare::API|Cloudflare::API>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE and COPYRIGHT

Copyright (c) 2026 Andrew Speer. This software is free software under the same terms as Perl 5.

=cut
