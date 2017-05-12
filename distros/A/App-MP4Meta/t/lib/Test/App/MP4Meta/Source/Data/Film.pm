use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::Data::Film;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Source::Data::Film;

# underscored so we run first
sub _create_new : Test(2) {
    my $self = shift;

    my $film = new_ok('App::MP4Meta::Source::Data::Film');
    can_ok( $film, 'merge' );
}

sub film : Test(2) {
    my $self = shift;

    my $film = App::MP4Meta::Source::Data::Film->new(
        genre => 'Comedy',
        year  => '2012',
    );

    is( $film->genre, 'Comedy' );
    is( $film->year,  '2012' );
}

1;
