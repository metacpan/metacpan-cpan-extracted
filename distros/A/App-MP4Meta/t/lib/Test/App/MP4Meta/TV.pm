use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::TV;
use base qw(TestBase);
use Test::More;

use App::MP4Meta::TV;

use App::MP4Meta::Source::Data::TVEpisode;

# underscored so we run first
sub _create_new : Test(4) {
    my $self = shift;

    my @args = ( { genre => 'Comedy' } );
    my $t = new_ok( 'App::MP4Meta::TV', \@args );
    is( $t->{'genre'},      'Comedy' );
    is( $t->{'media_type'}, 'TV Show' );

    $self->{tv} = new_ok('App::MP4Meta::TV');
}

sub live_apply_meta_tvdb_default : Test(12) {
    my $self = shift;

    return 'no live testing' unless $self->can_live_test();

    my $path = 'Heroes.S01E01';
    my $t    = App::MP4Meta::TV->new( { sources => ['TVDB'] } );
    my $mock = $self->mock_ap();
    $t->{ap} = $mock;

    my $result = $t->apply_meta($path);
    ok( !$result );

    # check we called AP correctly
    my ( $name, $args ) = $mock->next_call();
    my $write_path = $args->[1];
    my $tags       = $args->[2];

    is( $name,       'write_tags' );
    is( $write_path, $path );

    isa_ok( $tags, 'AtomicParsley::Command::Tags' );
    is( $tags->TVEpisode, 1,                  'episode num' );
    is( $tags->artist,    'Heroes',           'artist' );
    is( $tags->album,     'Heroes, Season 1', 'album' );
    is( $tags->title,     'Genesis',          'title' );
    is( $tags->genre,     'Drama',            'genre' );
    is( $tags->year,      '2006',             'year' );
    ok( $tags->description, 'description' );
    like( $tags->artwork, qr/\.jpg$/, 'artwork' );
}

sub apply_meta_set_title : Test(9) {
    my $self = shift;

    my $path    = 'Heroes.S01E01';
    my $t       = App::MP4Meta::TV->new( { title => 'Setting Title' } );
    my $ap_mock = $self->mock_ap();
    $t->{ap} = $ap_mock;
    my $tv_mock = $self->mock_tv_source();
    $t->{sources_objects} = [$tv_mock];

    my $result = $t->apply_meta($path);
    ok( !$result );

    # check we called AP correctly
    my ( $name, $args ) = $ap_mock->next_call();
    my $write_path = $args->[1];
    my $tags       = $args->[2];

    is( $name,       'write_tags' );
    is( $write_path, $path );

    isa_ok( $tags, 'AtomicParsley::Command::Tags' );
    is( $tags->artist, 'Setting Title',           'artist' );
    is( $tags->album,  'Setting Title, Season 1', 'album' );
    is( $tags->title,  'Test TV Episode',         'title' );
    is( $tags->genre,  'Comedy',                  'genre' );
    is( $tags->year,   '2012',                    'year' );
}

# test $tv->_parse_filename($filename)
sub parse_filename : Test(45) {
    my $self = shift;
    my $t    = $self->{tv};

    my $title;
    my $season;
    my $episode;

    ( $title, $season, $episode ) =
      $t->_parse_filename('Heroes.S03E01.HDTV.XviD-XOR.m4v');
    is( $title,   'Heroes' );
    is( $season,  3 );
    is( $episode, 1 );
    ( $title, $season, $episode ) = $t->_parse_filename('Miranda S01 E02.m4a');
    is( $title,   'Miranda' );
    is( $season,  1 );
    is( $episode, 2 );
    ( $title, $season, $episode ) = $t->_parse_filename('Miranda S01 E02.m4b');
    is( $title,   'Miranda' );
    is( $season,  1 );
    is( $episode, 2 );
    ( $title, $season, $episode ) = $t->_parse_filename('Miranda S01 E02.m4p');
    is( $title,   'Miranda' );
    is( $season,  1 );
    is( $episode, 2 );
    ( $title, $season, $episode ) = $t->_parse_filename('Miranda S01 E02.mp4');
    is( $title,   'Miranda' );
    is( $season,  1 );
    is( $episode, 2 );
    ( $title, $season, $episode ) = $t->_parse_filename('Miranda S01 E02.m4v');
    is( $title,   'Miranda' );
    is( $season,  1 );
    is( $episode, 2 );
    ( $title, $season, $episode ) =
      $t->_parse_filename('gossip.girl.s01e01.m4v');
    is( $title,   'Gossip Girl' );
    is( $season,  1 );
    is( $episode, 1 );
    ( $title, $season, $episode ) = $t->_parse_filename('THE_OFFICE-S1E3.m4v');
    is( $title,   'The Office' );
    is( $season,  1 );
    is( $episode, 3 );
    ( $title, $season, $episode ) =
      $t->_parse_filename('THE_MIGHTY_BOOSH_S1E4.m4v');
    is( $title,   'The Mighty Boosh' );
    is( $season,  1 );
    is( $episode, 4 );
    ( $title, $season, $episode ) = $t->_parse_filename('Dexter - s01e01.m4v');
    is( $title,   'Dexter' );
    is( $season,  1 );
    is( $episode, 1 );
    ( $title, $season, $episode ) =
      $t->_parse_filename('Dexter - 2x12 - The British Invasion.m4v');
    is( $title,   'Dexter' );
    is( $season,  2 );
    is( $episode, 12 );
    ( $title, $season, $episode ) =
      $t->_parse_filename('Dexter S02E12 - The British Invasion.m4v');
    is( $title,   'Dexter' );
    is( $season,  2 );
    is( $episode, 12 );
    $t->{title} = 'Extras';
    ( $title, $season, $episode ) = $t->_parse_filename('Foo S01E01.m4v');
    is( $title,   'Extras' );
    is( $season,  1 );
    is( $episode, 1 );
    
    #-- Plex style rules
    $t->{title} = '';
    ( $title, $season, $episode ) = $t->_parse_filename('S06E01-E02 - Bargaining.mkv', '/Volumes/Media3/TV Shows/Buffy the Vampire Slayer/Season 6/');
    is ( $title, 'Buffy The Vampire Slayer');
    is ( $season, 6);
    is ( $episode, 1);

    ( $title, $season, $episode ) = $t->_parse_filename('S06E01-E02 - Bargaining.mkv', '/Volumes/Media3/TV Shows/Buffy the Vampire Slayer/');
    is ( $title, 'Buffy The Vampire Slayer');
    is ( $season, 6);
    is ( $episode, 1);
}

sub episode_is_complete : Test(2) {
    my $self = shift;
    my $t    = $self->{tv};

    my $e = App::MP4Meta::Source::Data::TVEpisode->new(
        genre => 'Comedy',
        year  => '2012',
        cover => '/path/to/cover.jpg'
    );

    ok( !App::MP4Meta::TV::_episode_is_complete($e) );

    $e->{overview} = 'Foo';
    ok( App::MP4Meta::TV::_episode_is_complete($e) );
}

1;
