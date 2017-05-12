use strict;
use warnings;
use Test::More;
BEGIN { plan tests => 12 }

use_ok('Cache');
use_ok('Cache::Entry');
use_ok('Cache::RemovalStrategy');
use_ok('Cache::RemovalStrategy::LRU');
use_ok('Cache::RemovalStrategy::FIFO');
use_ok('Cache::IOString');
use_ok('Cache::Tester');

use_ok('Cache::Null');
use_ok('Cache::Memory');
use_ok('Cache::File');

use_ok('Cache::File::Heap');
use_ok('Cache::File::Handle');
