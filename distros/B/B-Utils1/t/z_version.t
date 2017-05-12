#!perl
use strict;
use warnings;
use Test::More tests => 7;

open my $fh, '<', 'lib/B/Utils1.pm'
  or die "Can't open lib/B/Utils1.pm: $!";
undef $/;
my $doc = <$fh>;
close $fh;

ok( my ( $pod_version ) = $doc =~ /^=head1\s+VERSION\s+([\d._]+)/m,
    "Extract version from pod in lib/B/Utils1.pm" );
ok( my ( $pm_version ) = $doc =~ /^our\s+\$VERSION\s+=\s+'([\d._]+)';/m,
    "Extract version from code in lib/B/Utils1.pm" );
is( $pod_version, $pm_version, 'Documentation & $VERSION are the same' );


open $fh, '<', 'lib/B/Utils1/OP.pm'
    or die "Can't open lib/B/Utils1/OP.pm: $!";
$doc = <$fh>;
close $fh;
ok( my ( $op_pm_version ) = $doc =~ /^our\s+\$VERSION\s+=\s+'([\d._]+)';/m,
    "Extract version from code in lib/B/Utils1/OP.pm" );
is( $op_pm_version, $pm_version, 'OP & PM $VERSION are the same' );


open $fh, '<', 'README.md'
  or die "Can't open README.md: $!";
$doc = <$fh>;
close $fh;
ok( my ( $readme_version ) = $doc =~ /^# VERSION\n\n([\d._]+)/sm,
    "Extract version from README.md" );

is( $readme_version, $pm_version, 'README.md & $VERSION are the same' );
