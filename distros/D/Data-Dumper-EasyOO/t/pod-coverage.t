#-*-perl-*-
use strict;
use Test::More tests => 1;
eval "use Pod::Coverage";
plan skip_all => "Pod::Coverage not installed here: $@" if $@;

my $pc = Pod::Coverage->new(package => 'Data::Dumper::EasyOO');
is($pc->coverage, 1, "POD has good coverage");
