use warnings;
use strict;
use Test::More tests => 5;
use Test::Exception;

use App::SpamcupNG::Warning;

note('Warning messages content are tested in find_errors!');

note('superclass tests');
my $warn_ref = ['warning message'];
my $instance = new_ok( 'App::SpamcupNG::Warning' => [$warn_ref] );
can_ok( $instance, qw(new message) );
$instance = App::SpamcupNG::Warning->new( $warn_ref, 1 );
is( $instance->message, 'warning message.',
    'error has the expected message' );
throws_ok { App::SpamcupNG::Warning->new(1) }
qr/must\sbe\san\sarray\sreference/, 'new requires an array reference';
throws_ok { App::SpamcupNG::Warning->new( [] ) }
qr/with\slength\sof\sat\sleast\s1/,
    'new requires an array reference with length of at least 1';

# vim: filetype=perl

