#!perl -T
use Test::More tests => 3;
use App::Unix::RPasswd;

if ( $ENV{PATH} =~ /(.+)/ ) { $ENV{PATH} = $1; }    # untaint the var
my $rpasswd = App::Unix::RPasswd->new( args => {} );
isa_ok($rpasswd, 'App::Unix::RPasswd');
can_ok( $rpasswd, 'ask_key' );
can_ok( $rpasswd, 'pexec' );

