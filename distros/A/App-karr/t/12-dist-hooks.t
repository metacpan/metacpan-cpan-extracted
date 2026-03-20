use strict;
use warnings;
use Test::More;

my $dist_ini = 'dist.ini';
ok( -f $dist_ini, 'dist.ini exists' ) or BAIL_OUT('dist.ini missing');

open my $fh, '<', $dist_ini or BAIL_OUT("Could not open $dist_ini: $!");
my @lines = <$fh>;
close $fh;

my @run_after_build = grep { /^run_after_build = / } @lines;
my @run_after_release = grep { /^run_after_release = / } @lines;

ok( @run_after_build, 'docker build hooks exist for run_after_build' );
like(
    join( '', @run_after_build ),
    qr/docker build .*raudssus\/karr:latest/,
    'run_after_build builds the latest Docker tag',
);

like(
    join( '', @run_after_release ),
    qr/docker build .*raudssus\/karr:%v .*raudssus\/karr:\$\(echo %v \| cut -d\. -f1\)/s,
    'run_after_release still builds versioned Docker tags',
);

done_testing;
