#!perl
use warnings; use strict;
use Test::More tests => 6;
use Test::Fatal;

use version;

use lib '.';
use t::Bb::Collaborate::V3;

use Bb::Collaborate::V3::Connection;
use Bb::Collaborate::V3::Session::Attendance;

our $t = Test::More->builder;
our $class = 'Bb::Collaborate::V3::Session::Attendance' ;

our $connection;

use Carp;
$SIG{__DIE__} = \&Carp::confess;

SKIP: {

    my $skippable = 6;

    my %result = t::Bb::Collaborate::V3->test_connection();
    my $auth = $result{auth};
    my $connection_class = $result{class};

   skip ($result{reason} || 'skipping live tests', $skippable)
	unless $auth && @$auth;

    $connection = $connection_class->connect(@$auth);
    Bb::Collaborate::V3->connection($connection);

    my $password = $connection->pass;

    is( exception {
	my $c2 = Bb::Collaborate::V3::Connection->connect($connection->url, $connection->user, $password, ping => 1 );
	$c2->disconnect;
	     } => undef, 'connect/disconnect with good credentials - lives' );

    isnt( exception {
	# add some junk to the password
	my $bad_password =  $password . t::Bb::Collaborate::V3::generate_id();
	Bb::Collaborate::V3::Connection->connect($connection->url, $connection->user, $bad_password, ping => 1 )
	     } => undef, 'attempted connect with bad password - dies' );

    my $good_som;
    {
	is( exception {$good_som = $connection->call('GetSchedulingManager')} => undef, 'legitimate soap call - lives...');
    }

    is( exception {$connection->_check_for_errors($good_som)} => undef, '...and lives when checked');

   my $bad_som;
    {
	local($connection->known_commands->{'UnknownCommandXXX'}) = 'r';
	is( exception {$bad_som = $connection->call('UnknownCommandXXX')} => undef, 'call to unknown command - intially lives...');
    }

    isnt( exception {$connection->_check_for_errors($bad_som)} => undef, '...but dies when checked');
}

Bb::Collaborate::V3->disconnect;

