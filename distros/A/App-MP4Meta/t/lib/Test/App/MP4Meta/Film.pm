use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Film;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Film;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    $self->{film} = new_ok('App::MP4Meta::Film');
}

sub apply_meta_default : Test(9) {
    my $self = shift;

    my $path    = 'In-Brugges.m4v';
    my $f       = App::MP4Meta::Film->new();
    my $ap_mock = $self->mock_ap();
    $f->{ap} = $ap_mock;
    my $film_mock = $self->mock_film_source();
    $f->{sources_objects} = [$film_mock];

    my $result = $f->apply_meta($path);
    ok( !$result );

    # check we called AP correctly
    my ( $name, $args ) = $ap_mock->next_call();
    my $write_path = $args->[1];
    my $tags       = $args->[2];

    is( $name,       'write_tags' );
    is( $write_path, $path );

    isa_ok( $tags, 'AtomicParsley::Command::Tags' );
    is( $tags->artwork,     '/foo/bar.jpg', 'artwork' );
    is( $tags->title,       'Test Film',    'title' );
    is( $tags->description, 'nice',         'description' );
    is( $tags->genre,       'Comedy',       'genre' );
    is( $tags->year,        '2012',         'year' );
}

sub apply_meta_test_title : Test(10) {
    my $self = shift;

    my $path    = 'In-Brugges.m4v';
    my $f       = App::MP4Meta::Film->new( { title => 'Setting Title' } );
    my $ap_mock = $self->mock_ap();
    $f->{ap} = $ap_mock;
    my $film_mock = $self->mock_film_source();
    $f->{sources_objects} = [$film_mock];

    my $result = $f->apply_meta($path);
    ok( !$result );

    # check we called AP correctly
    my ( $name, $args ) = $ap_mock->next_call();
    my $write_path = $args->[1];
    my $tags       = $args->[2];

    is( $name,       'write_tags' );
    is( $write_path, $path );

    isa_ok( $tags, 'AtomicParsley::Command::Tags' );
    is( $tags->artwork,     '/foo/bar.jpg', 'artwork' );
    is( $tags->title,       'Test Film',    'title' );
    is( $tags->description, 'nice',         'description' );
    is( $tags->genre,       'Comedy',       'genre' );
    is( $tags->year,        '2012',         'year' );
    is( $tags->stik,        'Short Film',   'stik' );
}

# test $film->_parse_filename($filename)
sub parse_filename : Test(22) {
    my $self = shift;
    my $f    = $self->{film};

    my $title;
    my $year;

    ( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4a');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4b');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4p');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.mp4');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4v');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE-TRUMAN-SHOW.m4v');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE-TRUMAN_SHOW.m4v');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE TRUMAN SHOW.m4v');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE TRUMAN_SHOW.m4v');
    is( $title, 'The Truman Show' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('IF....m4v');
    is( $title, 'If...' );
    ok( !$year );
    ( $title, $year ) = $f->_parse_filename('THE_ITALIAN_JOB_2003.m4v');
    is( $title, 'The Italian Job' );
    is( $year,  2003 );
}

sub film_is_complete : Test(2) {
    my $self = shift;
    my $f    = $self->{film};

    my $film = App::MP4Meta::Source::Data::Film->new(
        genre => 'Comedy',
        year  => '2012',
        cover => '/path/to/cover.jpg'
    );

    ok( !App::MP4Meta::Film::_film_is_complete($film) );

    $film->{overview} = 'Foo';
    ok( App::MP4Meta::Film::_film_is_complete($film) );
}

1;
