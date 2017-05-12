use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::Base;
use base qw(TestBase);

use Test::More;
use Test::Exception;

use App::MP4Meta::Source::Base;

# underscored so we run first
sub _create_new : Test(3) {
    my $self = shift;

    my $base = new_ok('App::MP4Meta::Source::Base');
    ok( $base->{cache} );
    ok( $base->{banner_cache} );

    $self->{base} = $base;
}

sub get_film : Test(1) {
    my $self = shift;
    my $base = $self->{base};

    throws_ok { $base->get_film( {} ) } qr/no title/, 'no title';
}

sub get_tv_episode : Test(3) {
    my $self = shift;
    my $base = $self->{base};

    throws_ok { $base->get_tv_episode( {} ) } qr/no title/, 'no title';
    throws_ok { $base->get_tv_episode( { show_title => 'foo' } ) }
    qr/no season/,
      'no season';
    throws_ok { $base->get_tv_episode( { show_title => 'foo', season => 1 } ) }
    qr/no episode/, 'no episode';
}

1;
