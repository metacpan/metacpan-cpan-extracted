use strict;
use FindBin;

use Module::Load;

local $ENV{CPANPLUS_SOURCE_ENGINE} = 'CPANPLUS::Internals::Source::SQLite';

my $old = select STDERR; $|++;
select $old;             $|++;
do("$FindBin::Bin/03_CPANPLUS-Internals-Source.t");
