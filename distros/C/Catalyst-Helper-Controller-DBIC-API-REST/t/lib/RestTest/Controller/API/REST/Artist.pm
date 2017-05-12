package RestTest::Controller::API::REST::Artist;

use strict;
use warnings;
use JSON::XS;

use parent qw/RestTest::ControllerBase::REST/;

__PACKAGE__->config(
    # Define parent chain action and partpath
    action                  =>  { setup => { PathPart => 'artist', Chained => '/api/rest/rest_base' } },
    # DBIC result class
    class                   =>  'DB::Artist',

    # Columns required to create
    create_requires         =>  [qw/name/],
    # Additional non-required columns that create allows
    create_allows           =>  [qw//],
    # Columns that update allows
    update_allows           =>  [qw/name/],
    # Columns that list returns
    list_returns            =>  [qw/artistid name/],


    # Every possible prefetch param allowed
    list_prefetch_allows    =>  [
        [qw/cds/], {  'cds' => [qw/cd_to_producer tags tracks/] },

    ],

    # Order of generated list
    list_ordered_by         => [qw/artistid/],
    # columns that can be searched on via list
    list_search_exposes     => [
        qw/artistid name/,
        { 'cds' => [qw/cdid artist title year/] },

    ],);

=head1 NAME

 - REST Controller for

=head1 DESCRIPTION

REST Methods to access the DBIC Result Class artist

=head1 AUTHOR

Amiri Barksdale,,,

=head1 SEE ALSO

L<Catalyst::Controller::DBIC::API>
L<Catalyst::Controller::DBIC::API::REST>
L<Catalyst::Controller::DBIC::API::RPC>

=head1 LICENSE



=cut

1;
