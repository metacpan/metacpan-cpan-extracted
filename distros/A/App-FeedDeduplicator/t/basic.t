use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use_ok('App::FeedDeduplicator');

# Mock the configuration file
my ($fh, $mock_config_file) = tempfile();
print $fh '{"feeds": [], "output_format": "Atom"}';
close $fh;

local $ENV{FEED_DEDUP_CONFIG} = $mock_config_file;

# Test creating an instance of App::FeedDeduplicator
my $deduplicator;
ok($deduplicator = App::FeedDeduplicator->new(), 'Created an instance of App::FeedDeduplicator');

# Test that the run method can be called
can_ok($deduplicator, 'run');

# Test that the run method executes without errors
ok(eval { $deduplicator->run(); 1 }, 'run() method executed without errors') or diag($@);

done_testing();
