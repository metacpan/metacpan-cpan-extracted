use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Base;
use base qw(TestBase);

use Test::More;
use Test::Exception;

use App::MP4Meta::Base;

# underscored so we run first
sub _create_new : Test(5) {
    my $self = shift;

    my $base = new_ok('App::MP4Meta::Base');

    isa_ok( $base->{ap}, 'AtomicParsley::Command' );
    ok( !$base->{'noreplace'} );

    my @args = ( { noreplace => 1 } );
    $base = new_ok( 'App::MP4Meta::Base', \@args );
    ok( $base->{'noreplace'} );

    $self->{base} = $base;
}

# test $base->_clean_title($title)
sub clean_title : Test(4) {
    my $self = shift;
    my $b    = $self->{base};

    is( $b->_clean_title('THE_OFFICE'),  'The Office' );
    is( $b->_clean_title('Gossip.girl'), 'Gossip Girl' );
    is( $b->_clean_title('EXTRAS'),      'Extras' );
    is( $b->_clean_title('IF...'),       'If...' );
}

sub new_source : Test(2) {
    my $self = shift;
    my $b    = $self->{base};

    my $source = $b->_new_source('TVDB');
    isa_ok( $source, 'App::MP4Meta::Source::TVDB' );
    dies_ok { $source = $b->_new_source('FooBar') };
}

1;
