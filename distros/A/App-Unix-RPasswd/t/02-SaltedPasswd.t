#!perl -T
use Test::More tests => 7;
use App::Unix::RPasswd::SaltedPasswd;

# if ( $ENV{PATH} =~ /(.+)/ ) { $ENV{PATH} = $1; }    # untaint the var
my $spasswd = App::Unix::RPasswd::SaltedPasswd->new( salt => '12345678' );
isa_ok( $spasswd, 'App::Unix::RPasswd::SaltedPasswd' );
can_ok( $spasswd, ( 'generate', '_encode_string' ) );
is( $spasswd->generate('supay19700101supay'),
    'p81liXLlNc7w', 'Generate salted passwords' );

$spasswd = App::Unix::RPasswd::SaltedPasswd->new( salt => '12345678BOE' );
is( $spasswd->generate('supay19700101supay'),
    'p81liXLlNc7w', 'Generate salted passwords' );
isnt( $spasswd->generate('upay19700101supa'),
    'p81liXLlNc7w', 'Generate different salted passwords' );

is($spasswd->_minalpha_conv('abcdefghijklmnopqr'),
    '7bcdefghijklmnopqr', 'Pass mininimal alpha tests' );
    
is($spasswd->_minalpha_conv('zzzzzzzzzzzzzzzzzzzzz'),
    '5zzzzzzzzzzzzzzzzzzzz', 'Pass mininimal alpha tests' );