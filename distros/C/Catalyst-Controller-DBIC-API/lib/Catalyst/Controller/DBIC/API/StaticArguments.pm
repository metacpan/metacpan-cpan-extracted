package Catalyst::Controller::DBIC::API::StaticArguments;
$Catalyst::Controller::DBIC::API::StaticArguments::VERSION = '2.006002';
#ABSTRACT: Provides controller level configuration arguments
use Moose::Role;
use MooseX::Types::Moose(':all');
use namespace::autoclean;

requires 'check_column_relation';


foreach my $var (
    qw( create_requires create_allows update_requires update_allows ))
{
    has $var => (
        is      => 'ro',
        isa     => ArrayRef [ Str | HashRef ],
        traits  => ['Array'],
        default => sub { [] },
        trigger => sub {
            my ( $self, $new ) = @_;
            $self->check_column_relation( $_, 1 ) for @$new;
        },
        handles => {
            "get_${var}_column"    => 'get',
            "set_${var}_column"    => 'set',
            "delete_${var}_column" => 'delete',
            "insert_${var}_column" => 'insert',
            "count_${var}_column"  => 'count',
            "all_${var}_columns"   => 'elements',
        }
    );

    before "set_${var}_column" =>
        sub { $_[0]->check_column_relation( $_[2], 1 ) };
    before "insert_${var}_column" =>
        sub { $_[0]->check_column_relation( $_[2], 1 ) };
}


has 'prefetch_allows' => (
    is        => 'ro',
    writer    => '_set_prefetch_allows',
    isa       => ArrayRef [ ArrayRef | Str | HashRef ],
    default   => sub { [] },
    predicate => 'has_prefetch_allows',
    traits    => ['Array'],
    handles   => { all_prefetch_allows => 'elements', },
);

has 'prefetch_validator' => (
    is         => 'ro',
    isa        => 'Catalyst::Controller::DBIC::API::Validator',
    lazy_build => 1,
);

sub _build_prefetch_validator {
    my $self = shift;

    sub _check_rel {
        my ( $self, $rel, $static, $validator ) = @_;
        if ( ArrayRef->check($rel) ) {
            foreach my $rel_sub (@$rel) {
                _check_rel( $self, $rel_sub, $static, $validator );
            }
        }
        elsif ( HashRef->check($rel) ) {
            while ( my ( $k, $v ) = each %$rel ) {
                $self->check_has_relation( $k, $v, undef, $static );
            }
            $validator->load($rel);
        }
        else {
            $self->check_has_relation( $rel, undef, undef, $static );
            $validator->load($rel);
        }
    }

    my $validator = Catalyst::Controller::DBIC::API::Validator->new;

    foreach my $rel ( $self->all_prefetch_allows ) {
        _check_rel( $self, $rel, 1, $validator );
    }

    return $validator;
}


has 'count_arg' => ( is => 'ro', isa => Str, default => 'list_count' );


has 'page_arg' => ( is => 'ro', isa => Str, default => 'list_page' );


has 'offset_arg' => ( is => 'ro', isa => Str, default => 'list_offset' );


has 'select_arg' => ( is => 'ro', isa => Str, default => 'list_returns' );


has 'as_arg' => ( is => 'ro', isa => Str, default => 'as' );


has 'search_arg' => ( is => 'ro', isa => Str, default => 'search' );


has 'grouped_by_arg' =>
    ( is => 'ro', isa => Str, default => 'list_grouped_by' );


has 'ordered_by_arg' =>
    ( is => 'ro', isa => Str, default => 'list_ordered_by' );


has 'prefetch_arg' => ( is => 'ro', isa => Str, default => 'list_prefetch' );


has 'stash_key' => ( is => 'ro', isa => Str, default => 'response' );


has 'data_root' => ( is => 'ro', isa => Str, default => 'list' );


has 'item_root' => ( is => 'ro', isa => Str, default => 'data' );


has 'total_entries_arg' =>
    ( is => 'ro', isa => Str, default => 'totalcount' );


has 'use_json_boolean' => ( is => 'ro', isa => Bool, default => 0 );


has 'return_object' => ( is => 'ro', isa => Bool, default => 0 );


1;

__END__

=pod

=head1 NAME

Catalyst::Controller::DBIC::API::StaticArguments - Provides controller level configuration arguments

=head1 VERSION

version 2.006002

=head1 DESCRIPTION

StaticArguments is a role that is composed by the controller to provide
configuration parameters such as where to find specific elements in the request
data and if to use JSON boolean types.

=head1 PUBLIC_ATTRIBUTES

=head2 create_requires create_allows update_requires update_allows

These attributes control requirements and limits to columns when creating or
updating objects.

Each provides a number of handles:

    "get_${var}_column" => 'get'
    "set_${var}_column" => 'set'
    "delete_${var}_column" => 'delete'
    "insert_${var}_column" => 'insert'
    "count_${var}_column" => 'count'
    "all_${var}_columns" => 'elements'

=head2 prefetch_allows

prefetch_allows limits what relations may be prefetched when executing searches
with joins. This is necessary to avoid denial of service attacks in form of
queries which would return a large number of data and unwanted disclosure of
data.

Like the synopsis in DBIC::API shows, you can declare a "template" of what is
allowed (by using an '*'). Each element passed in, will be converted into a
Data::DPath and added to the validator.

    prefetch_allows => [ 'cds', { cds => tracks }, { cds => producers } ] # to be explicit
    prefetch_allows => [ 'cds', { cds => '*' } ] # wildcard means the same thing

=head2 count_arg

Controls how to reference 'count' in the the request_data, defaults to
'list_count'.

=head2 page_arg

Controls how to reference 'page' in the the request_data, defaults to
'list_page'.

=head2 offset_arg

Controls how to reference 'offset' in the the request_data, defaults to
'list_offset'.

=head2 select_arg

Controls how to reference 'select' in the the request_data, defaults to
'list_returns'.

=head2 as_arg

Controls how to reference 'as' in the the request_data, defaults to 'as'.

=head2 search_arg

Controls how to reference 'search' in the the request_data, defaults to
'search'.

=head2 grouped_by_arg

Controls how to reference 'grouped_by' in the the request_data, defaults to
'list_grouped_by'.

=head2 ordered_by_arg

Controls how to reference 'ordered_by' in the the request_data, defaults to
'list_ordered_by'.

=head2 prefetch_arg

Controls how to reference 'prefetch' in the the request_data, defaults to
'list_prefetch'.

=head2 stash_key

Controls where in the stash the request_data should be stored, defaults to
'response'.

=head2 data_root

Controls how to reference where the data is in the the request_data, defaults to
'list'.

=head2 item_root

Controls how to reference where the data for single object requests is in the
the request_data, defaults to 'data'.

=head2 total_entries_arg

Controls how to reference 'total_entries' in the the request_data, defaults to
'totalcount'.

=head2 use_json_boolean

Controls whether JSON boolean types are used in the success parameter of the
response or if raw strings are used, defaults to false.

=head2 return_object

Controls whether the results of create/update are serialized and returned in
the response, defaults to false.

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
