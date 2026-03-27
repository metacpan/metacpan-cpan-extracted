use strict;
use warnings;
use Test::More tests => 3;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-verify', store_dir => $dir);

# Store and verify
my $content = 'verify this content';
my $id = $ca->store(\$content);
ok($ca->verify($id), 'verify returns true for intact content');

# Corrupt the file and verify fails
my $path = $ca->path_for($id);
open my $fh, '>', $path or die "Cannot write $path: $!";
print $fh 'corrupted data';
close $fh;
ok(!$ca->verify($id), 'verify returns false for corrupted content');

# Verify nonexistent returns false
ok(!$ca->verify('00000000-0000-5000-8000-000000000000'),
   'verify returns false for nonexistent ID');
