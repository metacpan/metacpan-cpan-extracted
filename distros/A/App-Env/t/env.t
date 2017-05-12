#!perl

use Test::More tests => 13;

use strict;
use warnings;

use Env::Path;

use lib 't';
use File::Temp;
use App::Env;

my $app1 = App::Env->new( 'App1' );

my ( $env, $output, $value, @values );

# context 0
$env = $app1->env;
ok( 'HASH' eq ref $env, 'context 0: type' );
is( $env->{Site1_App1}, '1', 'context 0: value' );

# context 1
$value = $app1->env( 'Site1_App1' );
ok( ! ref $value, 'context 1: type' );
is ( $value, 1, 'context 1: value' );

# context 2
@values = $app1->env( 'Site1_App1', 'NotExist', 'Site1_App1_v1' );
ok( @values == 3, 'context 2: nelem' );
is_deeply ( \@values, [ 1, undef, 1 ], 'context 2: value' );

# context 3
$env = $app1->env( qr/Site1_App1.*/ );
ok( 'HASH' eq ref $env, 'context 3: type' );
is_deeply ( $env,
	    { Site1_App1 => 1,
	      Site1_App1_v1 => 1 }, 'context 3: value' );

sub test_exclude {
    my ( $exclude, $expect, $label ) = @_;

    my $env = $app1->env( qr/Site1_App1.*/,
                        {Exclude => $exclude} );

    is_deeply( $env, $expect, $label );
}

# what's left after the excludes below
my %subexp = ( Site1_App1_v1 => 1 );

# test exclusion
test_exclude( qr/Site1_.*/, {}, 'exclude: re, all' );
test_exclude( qr/Site1_App1$/, \%subexp, 'exclude: re, partial' );

test_exclude( 'Site1_App1', \%subexp, 'exclude: scalar' );

test_exclude( [ 'Site1_App1' ], \%subexp, 'exclude: array of scalar' );

test_exclude( sub { my( $var, $val ) = @_;
		    return $var eq 'Site1_App1' ? 1 : 0 },
              \%subexp,
	      'exclude: code' );

