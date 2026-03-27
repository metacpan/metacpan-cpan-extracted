use strict;
use warnings;
use Test::More tests => 4;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-sharding', store_dir => $dir);

# path_for returns 2-level sharded path
my $id = 'a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a';
my $path = $ca->path_for($id);
like($path, qr{\Qa3/bb/a3bb189e-8bf9-5f18-b3f6-1b2f5f5c1e3a\E$},
     'path_for uses 2-level hex sharding');

# Path starts with store_dir
like($path, qr{^\Q$dir\E/}, 'path starts with store_dir');

# Store creates sharded directory structure
my $content = 'sharding test';
my $stored_id = $ca->store(\$content);
my $stored_path = $ca->path_for($stored_id);
ok(-f $stored_path, 'stored file exists at sharded path');

# Verify directory structure
my $hex = $stored_id;
$hex =~ s/-//g;
my $d1 = substr($hex, 0, 2);
my $d2 = substr($hex, 2, 2);
ok(-d "$dir/$d1/$d2", 'shard directories created');
