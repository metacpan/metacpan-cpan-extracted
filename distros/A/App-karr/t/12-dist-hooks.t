use strict;
use warnings;
use Test::More;

my $dist_ini = 'dist.ini';
ok( -f $dist_ini, 'dist.ini exists' ) or BAIL_OUT('dist.ini missing');

open my $fh, '<', $dist_ini or BAIL_OUT("Could not open $dist_ini: $!");
my @lines = <$fh>;
close $fh;

my $config = join( '', @lines );

my $docker_marker = '@Author::GETTY::Docker / ';
my @docker_subsections = grep { index( $_, $docker_marker ) >= 0 } @lines;

ok( scalar(@docker_subsections) >= 2, 'two [@Author::GETTY::Docker] subsections exist' );

ok( index( $config, '[@Author::GETTY::Docker / runtime-root]' ) >= 0,
    'runtime-root subsection exists' );

ok( index( $config, '[@Author::GETTY::Docker / runtime-user]' ) >= 0,
    'runtime-user subsection exists' );

ok( index( $config, "target = runtime-root" ) >= 0 && index( $config, "image = raudssus/karr" ) >= 0,
    'runtime-root has target and image' );

ok( index( $config, "target = runtime-user" ) >= 0 && index( $config, "image = raudssus/karr" ) >= 0,
    'runtime-user has target and image' );

# runtime-root carries no explicit tags line — it relies on the
# [@Author::GETTY::Docker] default (latest %V %v).
my ($root_block) = $config =~ /^\[\@Author::GETTY::Docker \/ runtime-root\](.*?)(?=^\[|\z)/ms;
ok( defined $root_block && $root_block !~ /^\s*tags\s*=/m,
    'runtime-root has no hard-coded tags (uses default latest %V %v)' );

ok( index( $config, "tags = user" ) >= 0,
    'runtime-user has user tag' );

done_testing;