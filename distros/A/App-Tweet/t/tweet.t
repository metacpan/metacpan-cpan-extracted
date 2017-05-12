use warnings;
use strict;
use Test::More tests => 6;
use Test::MockObject;
use Net::Twitter;

my $fhd = Test::MockObject->new();
$fhd->fake_module( 'File::HomeDir', my_data => sub { '.' } );
$fhd->fake_new('File::HomeDir');

my $ntw = Test::MockObject->new();

$ntw->fake_module(
    'Net::Twitter',
    new => sub {
        my ( $class, %args ) = @_;
        is( $args{username}, 'test',     'correct username sent' );
        is( $args{password}, 'password', 'correct password sent' );
        return $ntw;
    }
);

$ntw->mock(
    update => sub { is( $_[1], 'Testing App::Tweet', 'correct message sent' ); }
);

use_ok('App::Tweet');

eval { App::Tweet->run(); };
ok( $@, 'caught message-less run' );

eval { App::Tweet->run( message => 'Testing App::Tweet' ); };
ok( $@, 'caught non-interactive run' );

App::Tweet->run(
    message  => 'Testing App::Tweet',
    username => 'test',
    password => 'password'
);
