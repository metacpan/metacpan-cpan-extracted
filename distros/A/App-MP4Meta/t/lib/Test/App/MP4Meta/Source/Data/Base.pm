use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::Data::Base;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Source::Data::Base;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    my $base = new_ok('App::MP4Meta::Source::Data::Base');

    $self->{base} = $base;
}

# test merging two metadata
sub merge : Test(3) {
    my $self = shift;

    my $base1 = App::MP4Meta::Source::Data::Base->new(
        genre => 'Comedy',
        year  => '2012',
    );
    my $base2 = App::MP4Meta::Source::Data::Base->new(
        genre    => 'Horror',
        overview => 'Scary comedy',
    );

    $base1->merge($base2);

    is( $base1->genre,    'Comedy' );
    is( $base1->year,     '2012' );
    is( $base1->overview, 'Scary comedy' );
}

1;
