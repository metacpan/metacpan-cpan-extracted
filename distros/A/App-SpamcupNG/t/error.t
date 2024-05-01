use warnings;
use strict;
use Test::More tests => 15;
use Test::Exception;

use App::SpamcupNG::Error;
use App::SpamcupNG::Error::Mailhost;
use App::SpamcupNG::Error::Bounce;

note('Error messages content are tested in find_errors!');

note('superclass tests');
my $error_ref = ['error message'];
my $instance  = new_ok( 'App::SpamcupNG::Error' => [$error_ref] );
can_ok( $instance, qw(new message is_fatal) );
is( $instance->is_fatal, 0, 'errors are not fatal by default' );
$instance = App::SpamcupNG::Error->new( $error_ref, 1 );
is( $instance->message, $error_ref->[0], 'error has the expected message' );
ok( $instance->is_fatal, 'second error instance is fatal' );
throws_ok { App::SpamcupNG::Error->new } qr/non empty array reference/,
    'new requires proper parameter';
throws_ok { App::SpamcupNG::Error->new(1) } qr/non empty array reference/,
    'new requires an array reference';
throws_ok { App::SpamcupNG::Error->new( [] ) } qr/non empty array reference/,
    'new requires an array reference with length of at least 1';

note('bounce tests');
$instance = new_ok( 'App::SpamcupNG::Error::Bounce' => [ [1] ] );
isa_ok( $instance, 'App::SpamcupNG::Error' );
ok( $instance->is_fatal, 'bounce error is fatal' );

note('mailhost tests');
$instance = new_ok( 'App::SpamcupNG::Error::Mailhost' => [ [ 1, 2, 3 ] ] );
isa_ok( $instance, 'App::SpamcupNG::Error' );
is( $instance->is_fatal, 0, 'mailhost error is not fatal' );
throws_ok { App::SpamcupNG::Error::Mailhost->new( [1] ) } qr/size\s=\s3/,
    'new parameter must be an array reference with lenght = 3';

# vim: filetype=perl
