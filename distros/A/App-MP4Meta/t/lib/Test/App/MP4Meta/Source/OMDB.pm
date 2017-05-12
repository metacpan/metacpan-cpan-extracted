use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::OMDB;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Source::OMDB;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    my $imdb = new_ok('App::MP4Meta::Source::OMDB');

    $self->{imdb} = $imdb;
}

sub name : Test(1) {
    my $self = shift;
    my $i    = $self->{imdb};

    is( $i->name, 'OMDB' );
}

sub live_film : Test(6) {
    my $self = shift;

    return 'no live testing' unless $self->can_live_test();

    my $i = $self->{imdb};

    my $f =
      $i->get_film( { title => 'Tinker Tailor Soldier Spy', year => 2011 } );

    isa_ok( $f, 'App::MP4Meta::Source::Data::Film' );
    ok( $f->overview, 'got overview' );    # assume its sensible
    is( $f->title, 'Tinker Tailor Soldier Spy', 'got title' );
    is( $f->year,  2011,                        'got year' );
    is( $f->genre, 'Drama, Mystery, Thriller',  'got comedy' );

    like( $f->cover, qr/\.jpg$/, 'got cover image' );
}

1;
