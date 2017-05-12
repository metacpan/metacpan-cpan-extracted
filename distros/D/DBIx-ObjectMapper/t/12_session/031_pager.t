use strict;
use warnings;
use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, 'lib' );

use MyTest11;

MyTest11->mapping;
MyTest11->setup_default_data;
my $mapper = MyTest11->mapper;

my $session = $mapper->begin_session;
my $attr = $mapper->attribute('MyTest11::Track');
my $query = $session->search('MyTest11::Track')->order_by(
    $attr->p('cd_id'), $attr->p('track_no')
)->limit(10);

my %track_id;
{
    my ( $it, $pager ) = $query->page(1);
    is ref($pager), 'Data::Page';
    is ref($it), 'DBIx::ObjectMapper::Engine::DBI::Iterator';
    my $loop_cnt = 0;
    while( my $track = $it->next ) {
        ok $track->id;
        $track_id{$track->id} = 1;
        $loop_cnt++;
    }
    is $loop_cnt, 10;
    is $pager->current_page, 1;
    is $pager->total_entries, 100;
    is $pager->entries_per_page, 10;
    is $pager->first_page, 1;
    is $pager->last_page, 10;
};

{
    my ( $it, $pager ) = $query->page(2);
    my $loop_cnt = 0;
    while( my $track = $it->next ) {
        ok $track->id;
        ok !$track_id{$track->id};
        $track_id{$track->id} = 1;
        $loop_cnt++;
    }
    is $loop_cnt, 10;
    is $pager->current_page, 2;
    is $pager->total_entries, 100;
    is $pager->entries_per_page, 10;
    is $pager->first_page, 1;
    is $pager->last_page, 10;
};

{
    my ( $it, $pager ) = $query->page(10);
    my $loop_cnt = 0;
    while( my $track = $it->next ) {
        ok $track->id;
        ok !$track_id{$track->id};
        $track_id{$track->id} = 1;
        $loop_cnt++;
    }
    is $loop_cnt, 10;
    is $pager->current_page, 10;
    is $pager->total_entries, 100;
    is $pager->entries_per_page, 10;
    is $pager->first_page, 1;
    is $pager->last_page, 10;
};

{
    my ( $it, $pager ) = $query->page(11);
    my $loop_cnt = 0;
    while( my $track = $it->next ) {
        $loop_cnt++;
    }
    is $loop_cnt, 0;
};


done_testing;

