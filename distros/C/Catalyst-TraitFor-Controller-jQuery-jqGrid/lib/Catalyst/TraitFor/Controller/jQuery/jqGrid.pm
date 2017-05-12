package Catalyst::TraitFor::Controller::jQuery::jqGrid;
use 5.008;

our $VERSION   = '0.04';
$VERSION = eval $VERSION;

use Moose::Role;
use POSIX qw(ceil);

use namespace::autoclean;

#
# page_params:
#
# Common role to calculate the paging parameters
#
sub jqgrid_page {
    my ($self, $c, $result_set) = @_;

    my $config = $c->config->{'Catalyst::TraitFor::Controller::jQuery::jqGrid'};
    my $page_key = 'page';
    my $rows_key = 'rows';
    my $sidx_key = 'sidx';
    my $sord_key = 'sord';
    my $json_key = 'json_data';

    if ($config) {
        $page_key = $config->{page_key} || 'page';
        $rows_key = $config->{rows_key} || 'rows';
        $sidx_key = $config->{sidx_key} || 'sidx';
        $sord_key = $config->{sord_key} || 'sord';
        $json_key = $config->{json_key} || 'json_data';
    }

    my $page        = $c->request->param($page_key) || 0;
    my $rows        = $c->request->param($rows_key) || 10;
    my $index_row   = $c->request->param($sidx_key);
    my $sort_order  = $c->request->param($sord_key);

    # get the count of the maximum number of records
    my $records = $result_set->count();

    my $total_pages = $records > 0 ? ceil($records / $rows) : 0;

    if ($page > $total_pages) {
        $page = $total_pages;
    }

    if ($index_row && $sort_order) {

        my $order_by = { -asc => $index_row };
        if (lc($sort_order) eq 'desc') {
            $order_by = { - desc => $index_row };
        }

        $result_set = $result_set->search({}, {
            order_by    => $order_by,
            page        => $page,
            rows        => $rows,
        });
    }
    else {
        $result_set = $result_set->search({}, {
            page        => $page,
            rows        => $rows,
        });
    }

    $c->stash->{$json_key}{page}    = $page;
    $c->stash->{$json_key}{total}   = $total_pages;
    $c->stash->{$json_key}{records} = $records;

    return $result_set;
}

=pod

=head1 NAME

Catalyst::TraitFor::Controller::jQuery::jqGrid - Resultset helper for jQuery plugin jqGrid

=head1 SYNOPSIS

This module provides a helper module to retrieve resultsets on request from the
jQuery plugin jqGrid, a useful Javascript Grid control.

In your Catalyst Controller.

    package MyApp::Web::Controller::Root;

    use Moose;
    use namespace::autoclean;

    with 'Catalyst::TraitFor::Controller::jQuery::jqGrid';

Then later on in your controllers you can do

    sub foo : Local {
        my ($self, $c) = @_;

        my $bar_rs = $c->model('DB::Bar')->search({});

        # put any other constraints on the result set here and then finally

        $bar_rs = $self->jqgrid_page($c, $bar_rs);

        # do your stuff to read this resultset into a JSON structure.
    }

=head1 DESCRIPTION

The jQuery L<http://jquery.com/> Javascript library simplifies the writing of
Javascript and does for Javascript what the MVC model does for Perl.

A very useful plugin to jQuery in a Grid control which can be used to page
through data obtained from a back-end database. Ajax calls to the back-end
retrieve JSON data. See L<http://www.trirand.com/blog/>

This module provides helper functions which remove some of the repetition
you get if you have several grid controls on multiple web pages.

It is assumed that data for the jqGrid is obtained from a backend
database which is accessed via DBIx::Class so the methods provided by this
module will work on a DBIx::Class resultset.

=head1 METHODS

=head2 jqgrid_page

Do the pagination for a resultset.

    sub artists_list : Local {
        my ($self, $c) = @_;

        my $artist_rs = $c->model('DB::Artist')->search({});

        $artist_rs    = $self->jqgrid_page($c, $artist_rs);

        my $row = 0;
        my @row_data;

        while (my $artist = $artist_rs->next) {
            my $artist_id = $artist->id;

            my $single_row = {
                cell    => [
                    $artist->id,
                    $artist->firstname,
                    $artist->surname,
                ],
            };
            push @row_data, $single_row;
        }
        $c->stash->{json_data}{rows} = \@row_data;
        $c->stash->{current_view} = 'JSON';
    }

This example assumes a jqGrid control that displays three columns, an Artist ID,
an Artist Firstname and an Artist Surname.

It is also assumed that there are no 'filters' on the data. That is the grid
shows all Artists from the database. (If you wished to apply filters then you
could do this in the first DBIC search method in the example)

The method jqgrid_page will take the standard CGI parameters, page, rows, sord and
sidx and apply them to the resultset in order to modify it to return the
resultset for that page of data.

e.g. if page was '2' and rows was '10' then the resultset returned would be
rows 11 - 20 from the resultset.

The method takes two parameters, the $c catalyst object and the resultset.

It returns a modified resultset.

Note that since the jqgrid_page method puts the 'page', 'total' and 'records'
information onto the stash you should not modify the resultset after calling
this method otherwise these numbers will be wrong on the jqGrid control.

=head1 Configuration

By default there is no configuration required. The method will assume that
the jqGrid is using the standard arguments 'page', 'rows', 'sord' and 'sidx'
and that JSON data is put onto the stash in the 'json_data' hash.

If any of defaults are changed you can specify them in the Catalyst config as
so.

    package MyApp::Web;

    ...

    __PACKAGE__->config( 'Catalyst::TraitFor::Controller::jQuery::jqGrid' => {
        page_key    => 'my_page',
        rows_key    => 'my_rows',
        sord_key    => 'my _sord',
        sidx_key    => 'my _sidx',
        json_key    => 'json_data',
    });

Note however that this assumes that all grid controls use the same CGI
parameter names. If this is not so then this module cannot (as yet) work
for you.

=head1 SUPPORT

You can find information at:

=over 4

=item * Github repository

L<http://github.com/icydee/Catalyst-TraitFor-Controller-jQuery-jqGrid>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-TraitFor-Controller-jQuery-jqGrid>

=back

=head1 THANKS TO

Pete Smith <pete@cubabit.net> for patch fixes.

=head1 AUTHOR

Ian Docherty <pause@iandocherty.com>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2010-2011 the aforementioned authors. All rights
    reserved. This program is free software; you can redistribute
    it and/or modify it under the same terms as Perl itself.

=cut

1;
