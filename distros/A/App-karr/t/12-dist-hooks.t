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
    qr/docker build .*--target runtime-root .*raudssus\/karr:latest/s,
    'run_after_build builds the dynamic latest Docker tag from runtime-root',
);

like(
    join( '', @run_after_build ),
    qr/docker build .*--target runtime-user .*raudssus\/karr:user/s,
    'run_after_build also builds the fixed user Docker tag from runtime-user',
);

like(
    join( '', @run_after_release ),
    qr/release upload %v -R Getty\/p5-app-karr %a --clobber/,
    'run_after_release uploads the documented release archive placeholder',
);

like(
    join( '', @run_after_release ),
    qr/docker build .*--target runtime-root .*raudssus\/karr:%v .*raudssus\/karr:\$\(echo %v \| cut -d\. -f1\)/s,
    'run_after_release still builds versioned Docker tags from runtime-root',
);

like(
    join( '', @run_after_release ),
    qr/docker build .*--target runtime-user .*raudssus\/karr:user/s,
    'run_after_release also publishes the fixed user Docker tag',
);

like(
    join( '', @run_after_release ),
    qr/docker push raudssus\/karr:user/,
    'run_after_release pushes the fixed user Docker tag',
);

done_testing;
