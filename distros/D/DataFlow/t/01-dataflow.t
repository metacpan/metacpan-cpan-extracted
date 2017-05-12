use Test::More tests => 25;

use strict;

BEGIN {
    use_ok('DataFlow');
}

use DataFlow::Proc;

diag('constructor and basic tests');
my $proc_uc = DataFlow::Proc->new( p => sub { uc } );
ok($proc_uc);
is( ( $proc_uc->process('iop') )[0], 'IOP' );
my $f = DataFlow->new( procs => [$proc_uc] );
ok($f);

# scalars
diag('scalar params');
ok( !defined( $f->process() ) );
is( $f->process('aaa'), 'AAA' );
isnt( $f->process('aaa'), 'aaa' );
is( $f->process(1), 1 );

# array
diag('array params');
my @allyourbase = qw/all your base is belong to us/;

my @r = $f->process(@allyourbase);
is( scalar(@r), 7, 'has the right size' );
is( $r[0],      'ALL' );
is( $r[1],      'YOUR' );
is( $r[2],      'BASE' );
is( $r[3],      'IS' );
is( $r[4],      'BELONG' );
is( $r[5],      'TO' );
is( $r[6],      'US' );
my ( $all, $your, $base ) = $f->process(@allyourbase);
is( $all,  'ALL' );
is( $your, 'YOUR' );
is( $base, 'BASE' );

ok( !defined( $f->output ) );
my $r1 = $f->process(@allyourbase);
ok( !defined( $f->output ) );

$f->flush;
ok( !$f->output );

$f->input(qw/aaa bbb ccc ddd/);
is( $f->has_queued_data, 4 );
$f->output;
is( $f->has_queued_data, 3 );
$f->flush;
is( $f->has_queued_data, 0 );

