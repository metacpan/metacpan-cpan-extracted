package Catalyst::Controller::DBIC::API::RequestArguments;
$Catalyst::Controller::DBIC::API::RequestArguments::VERSION = '2.006002';
#ABSTRACT: Provides Request argument validation
use MooseX::Role::Parameterized;
use Catalyst::Controller::DBIC::API::Types(':all');
use MooseX::Types::Moose(':all');
use Scalar::Util('reftype');
use Data::Dumper;
use Catalyst::Controller::DBIC::API::Validator;
use namespace::autoclean;

use Catalyst::Controller::DBIC::API::JoinBuilder;




has [qw( search_validator select_validator )] => (
    is      => 'ro',
    isa     => 'Catalyst::Controller::DBIC::API::Validator',
    lazy    => 1,
    builder => '_build_validator',
);

sub _build_validator {
    return Catalyst::Controller::DBIC::API::Validator->new;
}

parameter static => ( isa => Bool, default => 0 );

role {
    my $p = shift;

    if ( $p->static ) {
        requires
            qw( check_has_relation check_column_relation prefetch_allows );
    }
    else {
        requires qw( _controller check_has_relation check_column_relation );
    }


    has 'count' => (
        is        => 'ro',
        writer    => '_set_count',
        isa       => Int,
        predicate => 'has_count',
    );


    has 'page' => (
        is        => 'ro',
        writer    => '_set_page',
        isa       => Int,
        predicate => 'has_page',
    );


    has 'offset' => (
        is        => 'ro',
        writer    => '_set_offset',
        isa       => Int,
        predicate => 'has_offset',
    );


    has 'ordered_by' => (
        is        => 'ro',
        writer    => '_set_ordered_by',
        isa       => OrderedBy,
        predicate => 'has_ordered_by',
        coerce    => 1,
        default   => sub { $p->static ? [] : undef },
    );


    has 'grouped_by' => (
        is        => 'ro',
        writer    => '_set_grouped_by',
        isa       => GroupedBy,
        predicate => 'has_grouped_by',
        coerce    => 1,
        default   => sub { $p->static ? [] : undef },
    );


    has prefetch => (
        is      => 'ro',
        writer  => '_set_prefetch',
        isa     => Prefetch,
        default => sub { $p->static ? [] : undef },
        coerce  => 1,
        trigger => sub {
            my ( $self, $new ) = @_;

            foreach my $pf (@$new) {
                if ( HashRef->check($pf) ) {
                    die
                        qq|'${\Dumper($pf)}' is not an allowed prefetch in: ${\join("\n", @{$self->prefetch_validator->templates})}|
                        unless $self->prefetch_validator->validate($pf)->[0];
                }
                else {
                    die
                        qq|'$pf' is not an allowed prefetch in: ${\join("\n", @{$self->prefetch_validator->templates})}|
                        unless $self->prefetch_validator->validate(
                        { $pf => 1 } )->[0];
                }
            }
        },
    );


    has 'search_exposes' => (
        is        => 'ro',
        writer    => '_set_search_exposes',
        isa       => ArrayRef [ Str | HashRef ],
        predicate => 'has_search_exposes',
        default   => sub { [] },
        trigger   => sub {
            my ( $self, $new ) = @_;
            $self->search_validator->load($_) for @$new;
        },
    );


    has 'search' => (
        is        => 'ro',
        writer    => '_set_search',
        isa       => SearchParameters,
        predicate => 'has_search',
        coerce    => 1,
        trigger   => sub {
            my ( $self, $new ) = @_;

            if ( $self->has_search_exposes and @{ $self->search_exposes } ) {
                foreach my $foo (@$new) {
                    while ( my ( $k, $v ) = each %$foo ) {
                        local $Data::Dumper::Terse = 1;
                        die
                            qq|{ $k => ${\Dumper($v)} } is not an allowed search term in: ${\join("\n", @{$self->search_validator->templates})}|
                            unless $self->search_validator->validate(
                            { $k => $v } )->[0];
                    }
                }
            }
            else {
                foreach my $foo (@$new) {
                    while ( my ( $k, $v ) = each %$foo ) {
                        $self->check_column_relation( { $k => $v } );
                    }
                }
            }

            my ( $search_parameters, $search_attributes ) =
                $self->generate_parameters_attributes($new);
            $self->_set_search_parameters($search_parameters);
            $self->_set_search_attributes($search_attributes);

        },
    );


    has search_parameters => (
        is        => 'ro',
        isa       => SearchParameters,
        writer    => '_set_search_parameters',
        predicate => 'has_search_parameters',
        coerce    => 1,
        default   => sub { [ {} ] },
    );


    has search_attributes => (
        is         => 'ro',
        isa        => HashRef,
        writer     => '_set_search_attributes',
        predicate  => 'has_search_attributes',
        lazy_build => 1,
    );


    has search_total_entries => (
        is        => 'ro',
        isa       => Int,
        writer    => '_set_search_total_entries',
        predicate => 'has_search_total_entries',
    );


    has 'select_exposes' => (
        is        => 'ro',
        writer    => '_set_select_exposes',
        isa       => ArrayRef [ Str | HashRef ],
        predicate => 'has_select_exposes',
        default   => sub { [] },
        trigger   => sub {
            my ( $self, $new ) = @_;
            $self->select_validator->load($_) for @$new;
        },
    );


    has select => (
        is        => 'ro',
        writer    => '_set_select',
        isa       => SelectColumns,
        predicate => 'has_select',
        default   => sub { $p->static ? [] : undef },
        coerce    => 1,
        trigger   => sub {
            my ( $self, $new ) = @_;
            if ( $self->has_select_exposes ) {
                foreach my $val (@$new) {
                    die "'$val' is not allowed in a select"
                        unless $self->select_validator->validate($val);
                }
            }
            else {
                $self->check_column_relation( $_, $p->static ) for @$new;
            }
        },
    );


    has as => (
        is      => 'ro',
        writer  => '_set_as',
        isa     => AsAliases,
        default => sub { $p->static ? [] : undef },
        trigger => sub {
            my ( $self, $new ) = @_;
            if ( $self->has_select ) {
                die
                    "'as' argument count (${\scalar(@$new)}) must match 'select' argument count (${\scalar(@{$self->select || []})})"
                    unless @$new == @{ $self->select || [] };
            }
            elsif ( defined $new ) {
                die "'as' is only valid if 'select is also provided'";
            }
        }
    );


    has joins => (
        is         => 'ro',
        isa        => JoinBuilder,
        lazy_build => 1,
        handles    => { build_joins => 'joins', }
    );


    has 'request_data' => (
        is        => 'ro',
        isa       => HashRef,
        writer    => '_set_request_data',
        predicate => 'has_request_data',
        trigger   => sub {
            my ( $self, $new ) = @_;
            my $controller = $self->_controller;
            return unless defined($new) && keys %$new;
            $self->_set_prefetch( $new->{ $controller->prefetch_arg } )
                if exists $new->{ $controller->prefetch_arg };
            $self->_set_select( $new->{ $controller->select_arg } )
                if exists $new->{ $controller->select_arg };
            $self->_set_as( $new->{ $controller->as_arg } )
                if exists $new->{ $controller->as_arg };
            $self->_set_grouped_by( $new->{ $controller->grouped_by_arg } )
                if exists $new->{ $controller->grouped_by_arg };
            $self->_set_ordered_by( $new->{ $controller->ordered_by_arg } )
                if exists $new->{ $controller->ordered_by_arg };
            $self->_set_count( $new->{ $controller->count_arg } )
                if exists $new->{ $controller->count_arg };
            $self->_set_page( $new->{ $controller->page_arg } )
                if exists $new->{ $controller->page_arg };
            $self->_set_offset( $new->{ $controller->offset_arg } )
                if exists $new->{ $controller->offset_arg };
            $self->_set_search( $new->{ $controller->search_arg } )
                if exists $new->{ $controller->search_arg };
        }
    );

    method _build_joins => sub {
        return Catalyst::Controller::DBIC::API::JoinBuilder->new(
            name => 'TOP' );
    };


    method format_search_parameters => sub {
        my ( $self, $params ) = @_;

        my $genparams = [];

        foreach my $param (@$params) {
            push(
                @$genparams,
                $self->generate_column_parameters(
                    $self->stored_result_source,
                    $param, $self->joins
                )
            );
        }

        return $genparams;
    };


    method generate_column_parameters => sub {
        my ( $self, $source, $param, $join, $base ) = @_;
        $base ||= 'me';
        my $search_params = {};

        # return non-hashref params unaltered
        return $param
            unless ref $param eq 'HASH';

        # build up condition
        foreach my $column ( keys %$param ) {
            my $value = $param->{$column};
            if ( $source->has_relationship($column) ) {

                # check if the value isn't a hashref
                unless ( ref $value eq 'HASH' )
                {
                    $search_params->{ join( '.', $base, $column ) } =
                        $value;
                    next;
                }

                $search_params = {
                    %$search_params,
                    %{  $self->generate_column_parameters(
                            $source->related_source($column),
                            $value,
                            Catalyst::Controller::DBIC::API::JoinBuilder->new(
                                parent => $join,
                                name   => $column
                            ),
                            $column
                        )
                    }
                };
            }
            elsif ( $source->has_column($column) ) {
                $search_params->{ join( '.', $base, $column ) } =
                    $param->{$column};
            }
            elsif ( $column eq '-or' || $column eq '-and' || $column eq '-not' ) {
                # either an arrayref or hashref
                if ( ref $value  eq 'HASH' ) {
                    $search_params->{$column} = $self->generate_column_parameters(
                        $source,
                        $value,
                        $join,
                        $base,
                    );
                }
                elsif ( ref $value eq 'ARRAY' ) {
                    push @{$search_params->{$column}},
                        $self->generate_column_parameters(
                            $source,
                            $_,
                            $join,
                            $base,
                        )
                        for @$value;
                }
                else {
                    die "unsupported value '$value' for column '$column'\n";
                }
            }

            # might be a sql function instead of a column name
            # e.g. {colname => {like => '%foo%'}}
            else {
                # but only if it's not a hashref
                unless ( ref $value eq 'HASH' ) {
                    $search_params->{ join( '.', $base, $column ) } =
                        $param->{$column};
                }
                else {
                    die "unsupported value '$value' for column '$column'\n";
                }
            }
        }

        return $search_params;
    };


    method generate_parameters_attributes => sub {
        my ( $self, $args ) = @_;

        return ( $self->format_search_parameters($args),
            $self->search_attributes );
    };

    method _build_search_attributes => sub {
        my ( $self, $args ) = @_;
        my $static            = $self->_controller;
        my $search_attributes = {
            group_by => $self->grouped_by
                || (
                ( scalar( @{ $static->grouped_by } ) ) ? $static->grouped_by
                : undef
                ),
            order_by => $self->ordered_by
                || (
                ( scalar( @{ $static->ordered_by } ) ) ? $static->ordered_by
                : undef
                ),
            select => $self->select
                || (
                ( scalar( @{ $static->select } ) ) ? $static->select
                : undef
                ),
            as => $self->as
                || ( ( scalar( @{ $static->as } ) ) ? $static->as : undef ),
            prefetch => $self->prefetch || $static->prefetch || undef,
            rows     => $self->count    || $static->count,
            page     => $static->page,
            offset   => $self->offset,
            join     => $self->build_joins,
        };

        if ( $self->has_page ) {
            $search_attributes->{page} = $self->page;
        }
        elsif (!$self->has_page
            && defined( $search_attributes->{offset} )
            && defined( $search_attributes->{rows} ) )
        {
            $search_attributes->{page} =
                $search_attributes->{offset} / $search_attributes->{rows} + 1;
            delete $search_attributes->{offset};
        }

        $search_attributes = {
            map {@$_}
                grep {
                defined( $_->[1] )
                    ? ( ref( $_->[1] )
                        && reftype( $_->[1] ) eq 'HASH'
                        && keys %{ $_->[1] } )
                    || ( ref( $_->[1] )
                    && reftype( $_->[1] ) eq 'ARRAY'
                    && @{ $_->[1] } )
                    || length( $_->[1] )
                    : undef
                }
                map { [ $_, $search_attributes->{$_} ] }
                keys %$search_attributes
        };

        if ( $search_attributes->{page} && !$search_attributes->{rows} ) {
            die 'list_page can only be used with list_count';
        }

        if ( $search_attributes->{select} ) {

            # make sure all columns have an alias to avoid ambiguous issues
            # but allow non strings (eg. hashrefs for db procs like 'count')
            # to pass through unmolested
            $search_attributes->{select} = [
                map { ( Str->check($_) && $_ !~ m/\./ ) ? "me.$_" : $_ }
                    ( ref $search_attributes->{select} )
                ? @{ $search_attributes->{select} }
                : $search_attributes->{select}
            ];
        }

        return $search_attributes;

    };

};


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::RequestArguments - Provides Request argument validation

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

RequestArguments embodies those arguments that are provided as part of a request
or effect validation on request arguments. This Role can be consumed in one of
two ways. As this is a parameterized Role, it accepts a single argument at
composition time: 'static'. This indicates that those parameters should be
stored statically and used as a fallback when the current request doesn't
provide them.

=head1 PUBLIC_ATTRIBUTES

=head2 count

The number of rows to be returned during paging.

=head2 page

What page to return while paging.

=head2 offset

Specifies where to start the paged result (think SQL LIMIT).

=head2 ordered_by

Is passed to ->search to determine sorting.

=head2 groupd_by

Is passed to ->search to determine aggregate results.

=head2 prefetch

Is passed to ->search to optimize the number of database fetches for joins.

=head2 search_exposes

Limits what can actually be searched. If a certain column isn't indexed or
perhaps a BLOB, you can explicitly say which columns can be search to exclude
that one.

Like the synopsis in DBIC::API shows, you can declare a "template" of what is
allowed (by using '*'). Each element passed in, will be converted into a
Data::DPath and added to the validator.

=head2 search

Contains the raw search parameters. Upon setting, a trigger will fire to format
them, set search_parameters and search_attributes.

Please see L</generate_parameters_attributes> for details on how the format works.

=head2 search_parameters

Stores the formatted search parameters that will be passed to ->search.

=head2 search_attributes

Stores the formatted search attributes that will be passed to ->search.

=head2 search_total_entries

Stores the total number of entries in a paged search result.

=head2 select_exposes

Limits what can actually be selected. Use this to whitelist database functions
(such as COUNT).

Like the synopsis in DBIC::API shows, you can declare a "template" of what is
allowed (by using '*'). Each element passed in, will be converted into a
Data::DPath and added to the validator.

=head2 select

Is the search attribute that allows you to both limit what is returned in the
result set and also make use of database functions like COUNT.

Please see L<DBIx::Class::ResultSet/select> for more details.

=head2 as

Is the search attribute compliment to L</select> that allows you to label
columns for object inflaction and actually reference database functions like
COUNT.

Please see L<DBIx::Class::ResultSet/as> for more details.

=head2 joins

Holds the top level JoinBuilder object used to keep track of joins automagically
while formatting complex search parameters.

Provides the method 'build_joins' which returns the 'join' attribute for
search_attributes.

=head2 request_data

Holds the raw (but deserialized) data for this request.

=head1 PRIVATE_ATTRIBUTES

=head2 search_validator

A Catalyst::Controller::DBIC::API::Validator instance used solely to validate
search parameters.

=head2 select_validator

A Catalyst::Controller::DBIC::API::Validator instance used solely to validate
select parameters.

=head2 prefetch_validator

A Catalyst::Controller::DBIC::API::Validator instance used solely to validate
prefetch parameters.

=head1 PROTECTED_METHODS

=head2 format_search_parameters

Iterates through the provided arrayref calling generate_column_parameters on
each one.

=head2 generate_column_parameters

Recursively generates properly aliased parameters for search building a new
JoinBuilder each layer of recursion.

=head2 generate_parameters_attributes

Takes the raw search arguments and formats them by calling
format_search_parameters. Then builds the related attributes, preferring
request-provided arguments for things like grouped_by over statically configured
options. Finally tacking on the appropriate joins.

Returns a list of both formatted search parameters and attributes.

=head1 AUTHORS

=over 4

=item *

Nicholas Perez <nperez@cpan.org>

=item *

Luke Saunders <luke.saunders@gmail.com>

=item *

Alexander Hartmaier <abraxxa@cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Oleg Kostyuk <cub.uanic@gmail.com>

=item *

Samuel Kaufman <sam@socialflow.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Luke Saunders, Nicholas Perez, Alexander Hartmaier, et al..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
