use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-meta', store_dir => $dir);

# Store with metadata
my $content = 'metadata test';
my $id = $ca->store(\$content, meta => {
    mime_type     => 'text/plain',
    original_name => 'test.txt',
});

# Fetch metadata
my $meta = $ca->meta($id);
ok(defined $meta, 'meta returns defined value');
is(ref $meta, 'HASH', 'meta returns hash ref');
is($meta->{mime_type}, 'text/plain', 'mime_type preserved');
is($meta->{original_name}, 'test.txt', 'original_name preserved');

# No metadata returns undef
my $content2 = 'no meta here';
my $id2 = $ca->store(\$content2);
my $meta2 = $ca->meta($id2);
ok(!defined $meta2, 'meta returns undef when no metadata stored');

# Remove cleans up metadata
my $path = $ca->path_for($id);
ok(-f "$path.meta", 'meta sidecar file exists');
$ca->remove($id);
ok(!-f "$path.meta", 'meta sidecar removed with content');
