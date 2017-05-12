#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Dancer::Logger::Spinner;

my $logger = Dancer::Logger::Spinner->new;

{
    no warnings qw/redefine once/;
    *Dancer::Logger::Spinner::DESTROY = sub {
        ok( 1, 'DESTROY called' );
    };
}

isa_ok( $logger->{'spinner_chars'}, 'ARRAY' );
cmp_ok( $logger->{'spinner_count'}, '==', 0, 'count starts at zero' );
can_ok( $logger, qw/ _log advance_spinner / );

{
    no warnings qw/redefine once/;
    *Dancer::Logger::Spinner::advance_spinner = sub {
        ok( 1, 'advance_spinner() called' );
        cmp_ok( scalar @_, '==', 1, 'One parameter' );
        isa_ok( $_[0], 'Dancer::Logger::Spinner' );
    };
}

$logger->_log();
