#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Dancer::Logger::Spinner;

my $logger = Dancer::Logger::Spinner->new;

{
    no warnings qw/redefine once/;
    *Dancer::Logger::Spinner::DESTROY = sub {
        ok( 1, 'DESTROY called' );
    };
}

cmp_ok( $logger->{'spinner_count'}, '==', 0, 'Default spinner count' );
# spinning once
$logger->advance_spinner();
cmp_ok( $logger->{'spinner_count'}, '==', 1, 'First spin' );

# spinning 4 more times, should be back at 1 again
$logger->advance_spinner() for 1 .. 4;
cmp_ok( $logger->{'spinner_count'}, '==', 0, 'Back to the start' );
