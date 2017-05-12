#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok 'BSD::devstat' }

my $o = BSD::devstat->new();
ok $o, 'new';

$_ = $o->numdevs;
ok $_ > 0, 'num()=' . ($_||0);

eval { $o->devices(-1) };
ok $@, 'devices(-1) should die';

eval { $o->devices(100) };
ok $@, 'devices(100) should die';

$_ = $o->devices(0);
is ref $_, 'HASH', 'devices() returns HASH';

is join(',', sort keys %$_), 'block_size,busy_time_frac,busy_time_sec,bytes_free,bytes_read,bytes_write,creation_time_frac,creation_time_sec,device_name,device_type,duration_free_frac,duration_free_sec,duration_read_frac,duration_read_sec,duration_write_frac,duration_write_sec,flags,operations_free,operations_other,operations_read,operations_write,priority,tag_head,tag_ordered,tag_simple,unit_number', 'keys';

ok exists $_->{device_name}, 'exists {device_name}';
ok length($_->{device_name}) > 0, '  has len: ' . ($_->{device_name}||'');
ok exists $_->{unit_number}, 'exists {unit_number}';
like $_->{unit_number}, qr/^\d+$/, '  like number';

$_ = $o->compute_statistics(0, 0.5);
is ref $_, 'HASH', 'compute_statistics() returns HASH';

is join(',', sort keys %$_), 'BLOCKS_PER_SECOND,BLOCKS_PER_SECOND_FREE,BLOCKS_PER_SECOND_READ,BLOCKS_PER_SECOND_WRITE,BUSY_PCT,KB_PER_TRANSFER,KB_PER_TRANSFER_FREE,KB_PER_TRANSFER_READ,KB_PER_TRANSFER_WRITE,MB_PER_SECOND,MB_PER_SECOND_FREE,MB_PER_SECOND_READ,MB_PER_SECOND_WRITE,MS_PER_TRANSACTION,MS_PER_TRANSACTION_FREE,MS_PER_TRANSACTION_OTHER,MS_PER_TRANSACTION_READ,MS_PER_TRANSACTION_WRITE,QUEUE_LENGTH,TOTAL_BLOCKS,TOTAL_BLOCKS_FREE,TOTAL_BLOCKS_READ,TOTAL_BLOCKS_WRITE,TOTAL_BYTES,TOTAL_BYTES_FREE,TOTAL_BYTES_READ,TOTAL_BYTES_WRITE,TOTAL_TRANSFERS,TOTAL_TRANSFERS_FREE,TOTAL_TRANSFERS_OTHER,TOTAL_TRANSFERS_READ,TOTAL_TRANSFERS_WRITE,TRANSFERS_PER_SECOND,TRANSFERS_PER_SECOND_FREE,TRANSFERS_PER_SECOND_OTHER,TRANSFERS_PER_SECOND_READ,TRANSFERS_PER_SECOND_WRITE', 'keys';

like $_->{TOTAL_BYTES}, qr/^\d+$/, '$_->{TOTAL_BYTES}';
like $_->{BLOCKS_PER_SECOND}, qr/^[\d.]+$/, '$_->{BLOCKS_PER_SECOND}';
