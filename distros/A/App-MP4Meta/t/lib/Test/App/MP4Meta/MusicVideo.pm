use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::MusicVideo;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::MusicVideo;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    $self->{music_video} = new_ok('App::MP4Meta::MusicVideo');
}

sub apply_meta_default : Test(7) {
    my $self = shift;

    my $path = 'Michael Jackson vs Prodigy - Bille Girl.m4v';
    my $t    = App::MP4Meta::MusicVideo->new();
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
    is( $tags->stik,   'Music Video',                'type' );
    is( $tags->artist, 'Michael Jackson Vs Prodigy', 'artist' );
    is( $tags->title,  'Bille Girl',                 'title' );
}

sub apply_meta_genre : Test(8) {
    my $self = shift;

    my $path = 'Michael Jackson vs Prodigy - Bille Girl.m4v';
    my $t    = App::MP4Meta::MusicVideo->new( { genre => 'Pop' } );
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
    is( $tags->stik,   'Music Video',                'type' );
    is( $tags->artist, 'Michael Jackson Vs Prodigy', 'artist' );
    is( $tags->title,  'Bille Girl',                 'title' );
    is( $tags->genre,  'Pop',                        'genre' );
}

# test $music_video->_parse_filename($filename)
sub parse_filename : Test(5) {
    my $self = shift;
    my $mv   = $self->{music_video};

    my $title;
    my $artist;
    ( $title, $artist ) =
      $mv->_parse_filename('Michael Jackson vs Prodigy - Bille Girl.m4v');
    is( $title,  'Michael Jackson Vs Prodigy' );
    is( $artist, 'Bille Girl' );
    ( $title, $artist ) = $mv->_parse_filename(
        'Gotye - Somebody That I Used To Know (feat. Kimbra).m4v');
    is( $title,  'Gotye' );
    is( $artist, 'Somebody That I Used To Know (feat. Kimbra)' );

    ok( !$mv->_parse_filename('foo') );
}

1;
