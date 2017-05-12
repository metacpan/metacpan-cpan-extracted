# vim: cindent ft=perl sm sw=4

use warnings;
use strict;

use Test::More tests => 20;

BEGIN { use_ok('Config::Scoped') }
my ( $p, $cfg );

ok( $p = Config::Scoped->new( warnings => 'off' ),
    'constructor with warnings' );
ok( !$p->warnings_on( name => 'all' ),    'warnings_on: all' );
ok( !$p->warnings_on( name => 'digest' ), 'warnings_on: digest' );
ok( !$p->warnings_on( name => 'foo' ),    'warnings_on: foo' );
ok( $p->set_warnings( name => 'foo', switch => 'on' ), 'set_warnings: foo' );
ok( $p->warnings_on( name  => 'foo' ),       'warnings_on: foo' );
ok( !$p->warnings_on( name => 'all' ),       'warnings_on: all' );
ok( !$p->warnings_on( name => 'parameter' ), 'warnings_on: parameter' );

ok(
    $p = Config::Scoped->new(
        warnings => { param => 'off', foo => 'off', perm => 'on' }
    ),
    'constructor with warnings hash'
);

my $warnings = { parameter => 'off', permissions => 'on', foo => 'off' };
is_deeply( $p->{local}{warnings}, $warnings, 'warnings hash' );
ok( $p->warnings_on( name => 'all' ),  'warnings_on: all' );
ok( $p->warnings_on( name => 'perm' ), 'warnings_on: permissions' );
ok( !$p->warnings_on( name => 'foo' ), 'warnings_on: foo' );

ok( $p->set_warnings( name => 'all', switch => 'off' ), 'set_warnings: all' );
ok( ! $p->warnings_on( name => 'perm' ), 'warnings_on: permissions' );

ok( $p->parse( text=> '%warnings permissions on'), 'warnings directive');
ok( $p->warnings_on( name => 'perm' ), 'warnings_on: permissions' );

ok( $p->parse( text=> '%warnings off'), 'warnings directive');
$warnings = { all => 'off'};
is_deeply( $p->{local}{warnings}, $warnings, 'warnings hash' );
