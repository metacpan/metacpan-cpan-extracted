# 
# Part of Comedi::Lib
#
# Copyright (c) 2009 Manuel Gebele <forensixs@gmx.de>, Germany
#
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required ",
                 "for testing POD coverage" if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
   if $@;

all_pod_coverage_ok({
   also_private => [
      qr/^lib_\w+$/,
      qr/^utility_\w+$/,
      qr/^CR_PACK$/,
      qr/^CR_PACK_FLAGS$/,
      qr/^CR_CHAN$/,
      qr/^CR_RANGE$/,
      qr/^CR_AREF$/,
      qr/^RANGE_LENGTH$/,
      qr/^RANGE_OFFSET$/,
      qr/^RF_UNIT$/,
      qr/^dl_load_flags$/, # Inline->init()
   ]
});
