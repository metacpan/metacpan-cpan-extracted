use strict;
use warnings;
use Test::More;

use FindBin;
use File::Spec;
use lib File::Spec->catfile( $FindBin::Bin, '..', '12_session', 'lib' );
use MyTest11;
use DBIx::ObjectMapper::Metadata::Query;

MyTest11->mapping;
MyTest11->setup_default_data;
my $mapper = MyTest11->mapper;

sub check {
    my $class = shift;
    my $session = $mapper->begin_session;
    my $cd_num = $session->get($class => 1);
    is $cd_num->artist_id, 1;
    is $cd_num->num, 10;
}

my $cd = $mapper->metadata->t('cd');

{
    my $query = $cd->select->column(
        $cd->c('artist_id'),
        [ { count => $cd->c('id') } => 'num' ],
    )->group_by( $cd->c('artist_id') );

    ok $mapper->maps(
        [
            $query => 'artist_num',
            { primary_key => ['artist_id'] }
        ] => 'MyArtistNum',
        accessors => { auto => 1 },
        constructor => { auto => 1 },
    );
    check('MyArtistNum');
};

{
    my $query = $cd->select->column(
        $cd->c('artist_id'),
        [ $cd->c('id')->func('count') => 'num' ],
    )->group_by( $cd->c('artist_id') );

    ok my $class_mapper = $mapper->maps(
        [
            $query => 'artist_num2',
            { primary_key => ['artist_id'] }
        ] => 'MyArtistNum2',
        accessors => { auto => 1 },
        constructor => { auto => 1 },
    );

    check('MyArtistNum2');
};

{
    my $tracks = $mapper->metadata->t('track');
    my $query = $tracks->select->column(
        $tracks->c('cd_id'),
        $tracks->c('id')->func('count')->as('count'),
    )->group_by( $tracks->c('cd_id') );

    ok $mapper->maps(
        [
            $query => 'track_static',
            { primary_key => ['cd_id'] }
        ] => 'MyTrackStatic',
        accessors => { auto => 1 },
        constructor => { auto => 1 },
    );

    my $session = $mapper->begin_session;
    my $it = $session->search('MyTrackStatic')->execute;
    my $loop_cnt = 0;
    while( my $t = $it->next ) {
        ok $t->cd_id;
        ok $t->count;
        $loop_cnt++;
    }
    is $loop_cnt, 10;
};


done_testing;

