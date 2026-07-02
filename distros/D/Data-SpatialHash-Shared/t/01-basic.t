use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;

# anonymous
my $s = Data::SpatialHash::Shared->new(undef, 1000, 0, 2.0);
isa_ok $s, 'Data::SpatialHash::Shared';
is $s->max_entries, 1000, 'max_entries';
cmp_ok $s->num_buckets, '>=', 1000, 'num_buckets defaulted to >= max_entries';
is $s->num_buckets & ($s->num_buckets - 1), 0, 'num_buckets is power of two';
is $s->cell_size, 2.0, 'cell_size';
is $s->count, 0, 'starts empty';
is $s->path, undef, 'anon has no path';

# explicit num_buckets rounds up to power of two
my $s2 = Data::SpatialHash::Shared->new(undef, 10, 100, 1.0);
is $s2->num_buckets, 128, 'num_buckets 100 -> 128';

# memfd round-trip via new_from_fd
my $m = Data::SpatialHash::Shared->new_memfd('sph', 50, 64, 1.0);
my $fd = $m->memfd;
cmp_ok $fd, '>=', 0, 'memfd fd';
my $m2 = Data::SpatialHash::Shared->new_from_fd($fd);
is $m2->max_entries, 50, 'reopened max_entries';
is $m2->cell_size, 1.0, 'reopened cell_size';

# bad args croak
eval { Data::SpatialHash::Shared->new(undef, 10, 0, 0) }; ok $@, 'cell_size 0 croaks';
eval { Data::SpatialHash::Shared->new(undef, 0, 0, 1) }; ok $@, 'max_entries 0 croaks';
eval { Data::SpatialHash::Shared->new(undef, 0x40000001, 0, 1) }; like $@, qr/too large/, 'max_entries > 2^30 croaks';
eval { Data::SpatialHash::Shared->new(undef, 10, 0x40000001, 1) }; like $@, qr/too large/, 'num_buckets > 2^30 croaks';

# file-backed create + reopen + unlink
my $path = "/tmp/sph-test-$$.bin";
{ my $f = Data::SpatialHash::Shared->new($path, 20, 0, 1.0); is $f->count, 0, 'file map empty'; }
ok -f $path, 'backing file created';
my $f2 = Data::SpatialHash::Shared->new($path, 20, 0, 1.0);
is $f2->max_entries, 20, 'reopened file map';
is $f2->path, $path, 'file-backed path() returns the backing file';
$f2->insert(1, 1, 7);
eval { $f2->sync }; ok !$@, 'sync (file-backed) does not croak';
$f2->unlink; ok !-f $path, 'unlinked';

# class-method form of unlink
my $cpath = "/tmp/sph-clsunlink-$$.bin";
{ my $cf = Data::SpatialHash::Shared->new($cpath, 20, 0, 1.0); $cf->insert(1, 1, 1); }
ok -f $cpath, 'class-unlink: backing file exists';
Data::SpatialHash::Shared->unlink($cpath);
ok !-f $cpath, 'class-method unlink removes the file';

done_testing;
