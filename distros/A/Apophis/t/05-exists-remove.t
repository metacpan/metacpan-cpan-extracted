use strict;
use warnings;
use Test::More tests => 5;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-exists', store_dir => $dir);

# Nonexistent ID
ok(!$ca->exists('00000000-0000-5000-8000-000000000000'),
   'exists returns false for nonexistent ID');

# Store, then check exists
my $content = 'exists test';
my $id = $ca->store(\$content);
ok($ca->exists($id), 'exists returns true after store');

# Remove
my $removed = $ca->remove($id);
ok($removed, 'remove returns true');
ok(!$ca->exists($id), 'exists returns false after remove');

# Remove nonexistent returns false
ok(!$ca->remove('00000000-0000-5000-8000-000000000000'),
   'remove returns false for nonexistent ID');
