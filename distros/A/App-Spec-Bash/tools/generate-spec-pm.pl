#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;
use FindBin '$Bin';

use Data::Dumper;
use YAML::PP;

my $specfile = "$Bin/../share/appspec-bash.yaml";
my $pm = "$Bin/../lib/App/Spec/Bash/Spec.pm";

my $yp = YAML::PP->new( schema => [qw/ JSON /] );

my $SPEC = $yp->load_file($specfile);
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Indent = 1;
my $dump = Data::Dumper->Dump([$SPEC], ['SPEC']);

open my $fh, '<', $pm or die $!;
my $module = do { local $/; <$fh> };
close $fh;

$module =~ s/(# START INLINE\n).*(# END INLINE\n)/$1$dump$2/s;

open $fh, '>', $pm or die $!;
print $fh $module;
close $fh;
