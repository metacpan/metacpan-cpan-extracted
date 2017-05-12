package RestTest::Controller::API::REST::Producer;

use strict;
use warnings;
use JSON::XS;

use parent qw/RestTest::ControllerBase::REST/;

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'producer', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'DB::Producer',

    # Columns required to create
    create_requires         =>  [qw/name/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/name/],
    # Columns that list returns
    list_returns            =>  [qw/producerid name/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/cd_to_producer/], {  'cd_to_producer' => [qw//] },
		[qw/tags/], {  'tags' => [qw//] },
		[qw/tracks/], {  'tracks' => [qw//] },

    ],

    # Order of generated list
    list_ordered_by         => [qw/producerid/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/producerid name/,

    ],);

=head1 NAME

 - REST Controller for

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class producer

=head1 AUTHOR

Amiri Barksdale,,,

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE



=cut

1;
