package Catalyst::Model::SWISH;
use strict;
use warnings;
use base qw( Catalyst::Model );
use Carp;
use SWISH::API::Object;
use Data::Dump qw( dump );
use MRO::Compat;
use mro 'c3';
use Data::Pageset;
use Time::HiRes qw( time );
use Sort::SQL;

our $VERSION = '0.06';

__PACKAGE__->mk_accessors(
    qw( swish swish_error pages_per_set page_size indexes debug ));

=head1 NAME

Catalyst::Model::SWISH - Catalyst model for Swish-e

=head1 SYNOPSIS

 # in your Controller
 sub search : Local
 {
    my ($self, $c) = @_;
    my ($pager, $results, $query, $order, $total, $stime, $btime) = 
     $c->model('SWISH')->search(
        query         => $c->request->params->{q},
        page          => $c->request->params->{page} || 0,
        page_size     => $c->request->params->{itemsperpage} || 0,
        limit_to      => 'swishtitle',
        limit_high    => 'm',
        limit_low     => 'a',
        order_by      => 'swishrank desc swishtitle asc'
     );
    $c->stash(search => 
        {
            results  => $results,
            pager    => $pager,
            query    => $query,
            order    => $order,
            hits     => $total,
            search_time => $stime,
            build_time  => $btime
        }
    );
 }
 

=head1 DESCRIPTION

Catalyst::Model::SWISH provides an easy interface to 
SWISH::API::Object for searching
Swish-e indexes (http://www.swish-e.org/). It is similar to and inspired by
Catalyst::Model::Xapian.

=head1 CONFIGURATION

The configuration value is passed directly to SWISH::API::Object->new()
so see the SWISH::API::Object documentation for possible key/value options.

=over

=item indexes

Path(s) to the Swish-e index(es). Defaults to <MyApp>/index.swish-e.

=item page_size

Default page sizes for L<Data::Pageset>. Defaults to 10.

=back

You may set config options either in your root class config() method prior to
setup(), using your Model class name as the key, or set them directly in
your Model class config() method.

Examples:

 # in MyApp.pm
 MyApp->config(
    'MyApp::Model::SWISH' => { 
        'indexes' => MyApp->path_to('some/where/index.swish-e')->stringify
        }
    );
    
 # same thing in MyApp/Model/SWISH.pm
 MyApp::Model::SWISH->config(
    'indexes' => MyApp->path_to('some/where/index.swish-e')->stringify
    );
 


=head1 METHODS

=head2 new

Constructor is called automatically by Catalyst at startup.

=cut

__PACKAGE__->config(
    pages_per_set => 10,
    page_size     => 10,
);

sub new {
    my ( $class, $c ) = @_;
    my $self = $class->next::method($c);

    # this config merging pointless if the default __PACKAGE__->config()
    # works above.

    #    my %config = (
    #        indexes => $self->config->{indexes}
    #            || $c->config->{$class}->{indexes}
    #            || $c->config->{home} . '/index.swish-e',
    #        pages_per_set => $self->config->{pages_per_set} || 10
    #    );
    #
    #    $c->merge_config_hashes( \%config, $self->config ) if $self->config;
    #    $c->merge_config_hashes( \%config, $c->config->{$class} )
    #        if exists $c->config->{$class};
    #
    #    # page_size == 0 is a valid value, so we must use defined()
    #    unless ( defined $config{page_size} ) {
    #        if ( defined $self->config->{page_size} ) {
    #            $config{page_size} = $self->config->{page_size};
    #        }
    #        elsif ( defined $c->config->{$class}->{page_size} ) {
    #            $config{page_size} = $c->config->{$class}->{page_size};
    #        }
    #        else {
    #            $config{page_size} = 10;
    #        }
    #    }

    #    $self->config( \%config );

    $self->{app_class} = ref($c) || $c;    # for logging
    $self->{indexes} ||= $c->path_to('index.swish-e') . '';    # stringify

    $self->debug
        and $self->{app_class}
        ->log->debug( sprintf( "%s: %s", ref($self), dump $self ) );

    return $self;
}

=head2 search( I<opts> )

Perform a search on the index.

In array context, returns (in order):

=over

=item 

a L<Data::Pageset> object

=item

an arrayref of SWISH::API::Result objects.

=item

an arrayref of parsed query terms

=item

an arrayref of property sort order, where each array item is a hashref like:

 { property => asc | desc }

=item

the total number of hits

=item

the search time

=item

the build time

=back

In scalar context, returns a hashref with the same values, with keys:

=over

=item pager

=item results

=item query

=item order

=item hits

=item search_time

=item build_time

=back

I<opts> require a C<query> name/value pair at minimum. Other
valid params include:

=over

=item page

Which page to start on. Used in cooperation with C<page_size> set in new().

=item order_by

Sort results by a property other than rank.

=item limit_to

Property name to limit results by.

=item limit_high

High value for C<limit_to>.

=item limit_low

Low value for C<limit_to>.

=back

=cut

sub search {
    my $self = shift;
    my %opts = @_;

    $opts{query} or croak "query required";

    my ( $swish, $search, $search_time, $build_time, $start_time, $results,
        $pager, $search_results );

    $search_results = { results => [], hits => 0 };

    $swish = $self->{swish} || $self->connect;
    $search = $swish->new_search_object;
    croak( $self->swish_error ) if $self->_check_err;
    $self->set_search_opts( $search, \%opts );
    croak( $self->swish_error ) if $self->_check_err;

    $start_time = time();
    $results    = $search->execute( $opts{query} );
    croak( $self->swish_error ) if $self->_check_err;

    if ( $self->debug ) {
        $self->{app_class}->log->debug(
            sprintf(
                "%s: query '%s': %d hits",
                ref($self), $opts{query}, $results->hits
            )
        );
        croak( $self->swish_error ) if $self->_check_err;
    }

    $search_time = sprintf( '%0.4f', time() - $start_time );

    if ( $results->hits ) {
        my $start       = ( $opts{page} - 1 ) * $opts{page_size};
        my $build_start = time();
        $self->seek_result( $results, $start ) unless $start > $results->hits;
        croak( $self->swish_error ) if $self->_check_err;
        $search_results = $self->get_results( $results, \%opts );
        croak( $self->swish_error ) if $self->_check_err;

        unless ( $opts{page_size} == 0 ) {

            $pager = Data::Pageset->new(
                {   total_entries    => $search_results->{hits},
                    entries_per_page => $opts{page_size},
                    current_page     => $opts{page},
                    pages_per_set    => $opts{pages_per_set},
                    mode             => 'slide',
                }
            );

        }

        $build_time = sprintf( '%0.4f', time() - $build_start );
    }

    return wantarray
        ? (
        $pager,
        $search_results->{results},
        [ $results->parsed_words( $swish->indexes->[0] ) ],
        Sort::SQL->string2array( $opts{order_by} || 'swishrank desc' ),
        $search_results->{hits},
        $search_time,
        $build_time
        )
        : {
        pager   => $pager,
        results => $search_results->{results},
        query   => [ $results->parsed_words( $swish->indexes->[0] ) ],
        order =>
            Sort::SQL->string2array( $opts{order_by} || 'swishrank desc' ),
        hits        => $search_results->{hits},
        search_time => $search_time,
        build_time  => $build_time
        };
}

=head2 seek_result( I<results_object>, I<start_offset> )

Calls the I<results_object> seek_result() method, setting it to
I<start_offset>.

=cut

sub seek_result {
    my ( $self, $results, $start ) = @_;
    $results->seek_result($start);
}

=head2 set_search_opts( I<search_object>, I<opts> )

I<search_object> is a SWISH::API::More::Search object.

I<opts> is a hashref. This method is called within search().
Override it to set per-search options other than the defaults.

=cut

sub set_search_opts {
    my $self   = shift;
    my $search = shift or croak "Search object required";
    my $opts   = shift or croak "opts hashref required";

    $opts->{page} ||= 1;
    $opts->{page_size}
        = defined( $opts->{page_size} )
        ? $opts->{page_size}
        : $self->config->{page_size};
    $opts->{pages_per_set} ||= $self->config->{pages_per_set};

    if ( $opts->{limit_to} ) {
        defined $opts->{limit_high}
            or croak "limit_high required with limit_to";
        defined $opts->{limit_low}
            or croak "limit_low required with limit_to";

        $search->set_search_limit( $opts->{limit_to}, $opts->{limit_low},
            $opts->{limit_high} );
        if ( $self->_check_err ) {
            croak( $self->swish_error );
            return;
        }
    }
    if ( $opts->{order_by} ) {
        $search->set_sort( $opts->{order_by} );
    }

    return $opts;
}

=head2 get_results( I<results_object>, I<opts> )

Loops over I<results_object> calling next_result().
I<opts> is the same hashref passed to set_search_opts().

Returns a hashref with the following key pairs:

=over

=item hits

Total number of hits for query.

=item count

Total number of results in current search.

=item results

Arrayref of result objects.

=back

=cut

sub get_results {
    my $self    = shift;
    my $results = shift or croak "SWISH::API::Object::Results required";
    my $opts    = shift or croak "search opts hashref required";
    my $count   = 0;
    my @r;
    while ( my $r = $results->next_result ) {
        push( @r, $r );
        if ( ++$count >= $opts->{page_size} && $opts->{page_size} != 0 ) {
            last;
        }
    }
    return { hits => $results->Hits, count => $count, results => \@r };
}

sub _check_err {
    my $self = shift;

    if ( $self->{swish}->error ) {
        $self->swish_error(
                  ref($self) . ": "
                . $self->{swish}->error_string . ": "
                . $self->{swish}->last_error_msg );
        return 1;
    }
    return 0;
}

=head2 connect

Calling connect() will DESTROY the cached SWISH::API::Object object and re-cache
it, essentially re-opening the Swish-e index.

B<NOTE:> SWISH::API::Object actually makes this unnecessary in most cases,
since it inherits from SWISH::API::Stat.

Returns the SWISH::API::Object instance.

=cut

sub connect {
    my $self = shift;
    $self->{swish} = SWISH::API::Object->new(
        indexes => $self->indexes,
        debug   => $self->debug
    );
    croak $self->swish_error if $self->_check_err;

    # use RankScheme 1 if the index supports it
    my $rs = $self->{swish}->header_value( $self->{swish}->indexes->[0],
        'IgnoreTotalWordCountWhenRanking' );
    if ( !$rs ) {
        $self->{swish}->rank_scheme(1);
    }

    return $self->{swish};
}

1;

__END__

=head1 AUTHOR

Peter Karman <perl@peknet.com>

Thanks to Atomic Learning, Inc for sponsoring the development of this module.

=head1 LICENSE

This library is free software. You may redistribute it and/or modify it under
the same terms as Perl itself.


=head1 SEE ALSO

http://www.swish-e.org/, SWISH::API::Object

=cut

