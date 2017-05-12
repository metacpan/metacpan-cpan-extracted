package CatalystX::CRUD::Model::Utils;
use strict;
use warnings;
use base qw( CatalystX::CRUD Class::Accessor::Fast );
use Sort::SQL;
use Data::Pageset;
use Search::QueryParser::SQL;
use Carp;

__PACKAGE__->mk_accessors(qw( use_ilike use_lower ne_sign ));

our $VERSION = '0.57';

=head1 NAME

CatalystX::CRUD::Model::Utils - helpful methods for your CRUD Model class

=head1 SYNOPSIS

 package MyApp::Model::Foo;
 use base qw( 
    CatalystX::CRUD::Model
    CatalystX::CRUD::Model::Utils
  );
 # ... 
 1;
 
=head1 DESCRIPTION

CatalystX::CRUD::Model::Utils provides helpful, non-essential methods
for CRUD Model implementations. Stick it in your @ISA to help reduce the
amount of code you have to write yourself.

=head1 METHODS

=head2 use_ilike( boolean )

Convenience accessor to flag requests in params_to_sql_query()
to use ILIKE instead of LIKE SQL command.

=head2 ne_sign( I<string> )

What string to use for 'not equal' in params_to_sql_query().
Defaults to '!='.

=head2 treat_like_int

Should return a hashref of column names to treat as integers
instead of text strings when parsing wildcard request params. Example
might be all date/timestamp columns.

=cut

=head2 make_sql_query( [ I<field_names> ] )

Returns a hashref suitable for passing to a SQL-oriented model.

I<field_names> should be an array of valid column names.
If false or missing, will call $c->controller->field_names().

The following reserved request param names are implemented:

=over

=item cxc-order

Sort order. Should be a SQL-friendly string parse-able by Sort::SQL.

=item cxc-sort

Instead of cxc-order, can pass one column name to sort by.

=item cxc-dir

With cxc-sort, pass the direction in which to sort.

=item cxc-page_size

For the Data::Pageset pager object. 
Defaults to page_size(). An upper limit of 200
is implemented by default to reduce the risk of 
a user [unwittingly] creating a denial
of service situation.

=item cxc-page

What page the current request is coming from. Used to set the offset value
in the query. Defaults to C<1>.

=item cxc-offset

Pass explicit row to offset from in query. If not present, deduced from
cxc-page and cxc-page_size.

=item cxc-no_page

Ignore cxc-page_size, cxc-page and cxc-offset and do not return a limit
or offset value.

=item cxc-op

If set to C<OR> then the query columns will be marked as OR'd together,
rather than AND'd together (the default).

=item cxc-query

The query string to use. This overrides any param values set for
field names.

=item cxc-query-fields

Which field names to set as 'default_column' in the Search::QueryParser::SQL
parser object. The default is all I<field_names>. B<NOTE> this param is only
checked if C<cxc-query> has a value.

=item cxc-fuzzy

If set to a true value triggers the 'fuzzify' feature in 
Search::QueryParser::SQL.

=item cxc-fuzzy2

If set to a true value, overrides cxc-fuzzy and triggers the 'fuzzify2'
feature in Search::QueryParser::SQL.

=back

=cut

sub _which_sort {
    my ( $self, $c ) = @_;
    my $params = $c->req->params;

    # backwards compat
    for my $p (qw( cxc-order _order )) {
        return $params->{$p} if defined $params->{$p};
    }

    # use explicit param
    for my $p (qw( cxc-sort _sort )) {
        my $dir = $params->{'cxc-dir'}
            || $params->{'_dir'};
        return join( ' ', $params->{$p}, uc($dir) )
            if defined( $params->{$p} ) && defined($dir);
    }

    my $pks = $c->controller->primary_key;
    return join( ' ', map { $_ . ' DESC' } ref $pks ? @$pks : ($pks) );
}

sub make_sql_query {
    my $self = shift;
    my $c    = $self->context;
    my $field_names
        = shift
        || $c->req->params->{'cxc-query-fields'}
        || $c->controller->field_names($c)
        || $self->throw_error("field_names required");

    # if present, param overrides default of form->field_names
    # passed by base controller.
    if (   exists $c->req->params->{'cxc-query-fields'}
        && exists $c->req->params->{'cxc-query'} )
    {
        $field_names = $c->req->params->{'cxc-query-fields'};
    }

    if ( !ref($field_names) ) {
        $field_names = [$field_names];
    }

    my $p2q    = $self->params_to_sql_query($field_names);
    my $params = $c->req->params;
    my $sp     = Sort::SQL->string2array( $self->_which_sort($c) );
    my $s      = join( ', ', map { join( ' ', %$_ ) } @$sp );
    my $offset = $params->{'cxc-offset'} || $params->{'_offset'};
    my $page_size
        = $params->{'cxc-page_size'}
        || $params->{'_page_size'}
        || $c->controller->page_size
        || $self->page_size;

    # don't let users DoS us. unless they ask to (see _no_page).
    $page_size = 200 if $page_size > 200;

    my $page = $params->{'cxc-page'} || $params->{'_page'} || 1;

    if ( !defined($offset) ) {
        $offset = ( $page - 1 ) * $page_size;
    }

    # normalize since some ORMs require UPPER case
    $s =~ s,\b(asc|desc)\b,uc($1),eg;

    my %query = (
        query           => $p2q->{sql},
        sort_by         => $s,
        limit           => $page_size,
        offset          => $offset,
        sort_order      => $sp,
        plain_query     => $p2q->{query_hash},
        plain_query_str => (
              $p2q->{query}
            ? $p2q->{query}->stringify
            : ''
        ),
        query_obj => $p2q->{query},
    );

    # undo what we've done if asked.
    if ( $params->{'cxc-no_page'} ) {
        delete $query{limit};
        delete $query{offset};
    }

    return \%query;

}

=head2 params_to_sql_query( I<field_names> )

Convert request->params into a SQL-oriented
query.

Returns a hashref with three key/value pairs:

=over

=item sql

Arrayref of ORM-friendly SQL constructs.

=item query_hash

Hashref of column_name => raw_values_as_arrayref.

=item query

The Search::QueryParser::SQL::Query object used
to generate C<sql>.

=back

Called internally by make_sql_query().

=cut

sub params_to_sql_query {
    my ( $self, $field_names ) = @_;
    croak "field_names ARRAY ref required"
        unless defined $field_names
        and ref($field_names) eq 'ARRAY';
    my $c = $self->context;
    my ( @sql, %pq );
    my $ne = $self->ne_sign || '!=';
    my $like = $self->use_ilike ? 'ilike' : 'like';
    my $treat_like_int
        = $self->can('treat_like_int') ? $self->treat_like_int : {};
    my $params = $c->req->params;
    my $oper   = $params->{'cxc-op'} || $params->{'_op'} || 'AND';
    my $fuzzy  = $params->{'cxc-fuzzy'} || $params->{'_fuzzy'} || 0;
    my $fuzzy2 = $params->{'cxc-fuzzy2'} || 0;

    my %columns;
    for my $fn (@$field_names) {
        $columns{$fn} = exists $treat_like_int->{$fn} ? 'int' : 'char';
    }

    my ( @param_query, @default_columns );

    # if cxc-query is present, prefer that.
    # otherwise, any params matching those in $field_names
    # are each parsed as individual queries, serialized and joined
    # with $oper.
    # cxc-query should be free from sql-injection attack as
    # long as Models use 'sql' or 'query'->dbi in returned hashref
    if ( exists $params->{'cxc-query'} ) {
        my $q
            = ref $params->{'cxc-query'}
            ? $params->{'cxc-query'}->[0]
            : $params->{'cxc-query'};

        if ( exists $params->{'cxc-query-fields'} ) {
            @default_columns
                = ref $params->{'cxc-query-fields'}
                ? @{ $params->{'cxc-query-fields'} }
                : ( $params->{'cxc-query-fields'} );

        }

        @param_query = ($q);
        $pq{'cxc-query'} = \@param_query;

    }
    else {
        for (@$field_names) {
            next unless exists $params->{$_};
            my @v
                = ref $params->{$_} ? @{ $params->{$_} } : ( $params->{$_} );

            grep {s/\+/ /g} @v;    # TODO URI + for space -- is this right?

            $pq{$_} = \@v;

            next unless grep {m/\S/} @v;

            # we don't want to "double encode" $like
            # or $use_lower because it will
            # be re-parsed as a word not an op, so we have a modified
            # parser for per-field queries.
            my %args = (
                like    => '=',
                fuzzify => $fuzzy,
                columns => \%columns,
                strict  => 1,
                rxOp    => qr/==|<=|>=|!=|=~|!~|=|<|>|~/,
            );
            if ($fuzzy2) {
                delete $args{fuzzify};
                $args{fuzzify2} = 1;
            }
            my $parser = Search::QueryParser::SQL->new(%args);

            my $query;
            eval {
                $query = $parser->parse( "$_ = (" . join( ' ', @v ) . ')' );
            };
            return $self->throw_error($@) if $@;

            push @param_query, $query->stringify;
        }
    }

    #Carp::carp Data::Dump::dump \@param_query;

    my $joined_query = join( ' ', @param_query );
    my $sql          = [];
    my $query        = '';

    if ( length $joined_query ) {

        my %args = (
            like           => $like,
            fuzzify        => $fuzzy,
            lower          => $self->use_lower,
            columns        => \%columns,
            default_column => (
                @default_columns
                ? \@default_columns
                : [ keys %columns ]
            ),
            strict => 1,
            rxOp   => qr/==|<=|>=|!=|=~|!~|=|<|>|~/,

        );
        if ($fuzzy2) {
            delete $args{fuzzify};
            $args{fuzzify2} = 1;
        }
        my $parser = Search::QueryParser::SQL->new(%args);

        # must eval and re-throw since we run under strict
        eval { $query = $parser->parse( $joined_query, uc($oper) eq 'AND' ); };
        return $self->throw_error($@) if $@;

        $sql = $query->rdbo;

    }

    #Carp::carp Data::Dump::dump $sql;

    return {
        sql        => $sql,
        query      => $query,
        query_hash => \%pq,
    };
}

=head2 make_pager( I<total> )

Returns a Data::Pageset object using I<total>,
either the C<_page_size> param or the value of page_size(),
and the C<_page> param or C<1>.

If the C<_no_page> request param is true, will return undef.
B<NOTE:> Model authors should check (and respect) the C<_no_page>
param when constructing queries.

=cut

sub make_pager {
    my ( $self, $count ) = @_;
    my $c      = $self->context;
    my $params = $c->req->params;
    return if ( $params->{'cxc-no_page'} or $params->{'_no_page'} );
    return Data::Pageset->new(
        {   total_entries    => $count,
            entries_per_page => $params->{'cxc-page_size'}
                || $params->{'_page_size'}
                || $c->controller->page_size
                || $self->page_size,
            current_page => $params->{'cxc-page'}
                || $params->{'_page'}
                || 1,
            pages_per_set => 10,        #TODO make this configurable?
            mode          => 'slide',
        }
    );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <perl at peknet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-crud at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CatalystX-CRUD>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::CRUD

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CatalystX-CRUD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CatalystX-CRUD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CatalystX-CRUD>

=item * Search CPAN

L<http://search.cpan.org/dist/CatalystX-CRUD>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Peter Karman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
