use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::TVDB;
use base qw(TestBase);

use Test::More;
use Test::Exception;
use Test::MockObject;

use App::MP4Meta::Source::TVDB;

use WebService::TVDB;
use WebService::TVDB::Series;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    my $tvdb = new_ok('App::MP4Meta::Source::TVDB');

    $self->{tvdb} = $tvdb;
}

sub name : Test(1) {
    my $self = shift;
    my $t    = $self->{tvdb};

    is( $t->name, 'theTVDB.com' );
}

sub get_tv_episode_not_found : Test(1) {
    my $self = shift;
    my $t    = App::MP4Meta::Source::TVDB->new();

    my $mock = Test::MockObject->new();
    $mock->set_always( 'search', [] );
    $t->{tvdb} = $mock;

    throws_ok {
        $t->get_tv_episode(
            { show_title => 'foo', season => 1, episode => 2 } );
    }
    qr/no series found/, 'no series found';
}

sub live : Test(6) {
    my $self = shift;

    return 'no live testing' unless $self->can_live_test();

    # TODO: return unless api key exists

    my $t = $self->{tvdb};

    my $e = $t->get_tv_episode(
        { show_title => 'Men Behaving Badly', season => 2, episode => 1 } );

    isa_ok( $e, 'App::MP4Meta::Source::Data::TVEpisode' );
    ok(   $e->overview,                     'got overview' );    # assume its sensible
    like( $e->title, qr/Gary (and|&) Tony/, 'got title' );
    is(   $e->year,  1992,                  'got year' );
    is(   $e->genre, 'Comedy',              'got comedy' );
    like( $e->cover, qr/\.jpg$/,            'got cover image' );
}

1;
