use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::Data::TVEpisode;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Source::Data::TVEpisode;

# underscored so we run first
sub _create_new : Test(2) {
    my $self = shift;

    my $episode = new_ok('App::MP4Meta::Source::Data::TVEpisode');
    can_ok( $episode, 'merge' );
}

sub episode : Test(3) {
    my $self = shift;

    my $e = App::MP4Meta::Source::Data::TVEpisode->new(
        genre      => 'Comedy',
        year       => '2012',
        show_title => 'The Office',
    );

    is( $e->genre,      'Comedy' );
    is( $e->year,       '2012' );
    is( $e->show_title, 'The Office' );
}

1;
