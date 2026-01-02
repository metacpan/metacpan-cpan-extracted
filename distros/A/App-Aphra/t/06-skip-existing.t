use strict;
use warnings;

use FindBin '$Bin';

use Test::More;
use App::Aphra;

# Easy way to bail out if the pandoc executable isn't installed
use Pandoc;
plan skip_all => "pandoc isn't installed; this module won't work"
  unless pandoc;

chdir("$Bin/data3");

@ARGV = ('build');

my $outfile = 'docs/test/index.html';

# Clean up any existing output
unlink $outfile if -e $outfile;

my $app = App::Aphra->new;

# Capture warnings
my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

$app->run;

# Check that the redirect file was created
ok(-e $outfile, 'Redirect file was created');

# Read the redirect file content
open my $fh, '<', $outfile or die "Cannot open $outfile: $!";
my $content = do { local $/; <$fh> };
close $fh;

# Verify it's a redirect (contains meta refresh)
like($content, qr/meta http-equiv="refresh"/, 'File contains redirect meta tag');
like($content, qr/url=\/newpage\//, 'Redirect points to correct location');

# Check that a warning was issued about skipping the source file
ok(scalar(@warnings) > 0, 'Warning was issued');
like($warnings[0], qr/already exists/, 'Warning mentions file already exists');
like($warnings[0], qr/skipping/, 'Warning mentions skipping');

# Clean up
unlink $outfile if -e $outfile;

done_testing;
