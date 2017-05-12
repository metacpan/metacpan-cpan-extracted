package RestTest::Controller::API::REST::Track;

use strict;
use warnings;
use JSON::XS;

use parent qw/RestTest::ControllerBase::REST/;

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'track', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'DB::Track',

    # Columns required to create
    create_requires         =>  [qw/cd position title/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw/last_updated_on/],
    # Columns that update allows
    update_allows           =>  [qw/cd position title last_updated_on/],
    # Columns that list returns
    list_returns            =>  [qw/trackid cd position title last_updated_on/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/cd_to_producer/], {  'cd_to_producer' => [qw//] },
		[qw/tags/], {  'tags' => [qw//] },
		[qw/tracks/], {  'tracks' => [qw//] },

    ],

    # Order of generated list
    list_ordered_by         => [qw/trackid/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/trackid cd position title last_updated_on/,

    ],);

=head1 NAME

 - REST Controller for

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class track

=head1 AUTHOR

Amiri Barksdale,,,

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE



=cut

1;
