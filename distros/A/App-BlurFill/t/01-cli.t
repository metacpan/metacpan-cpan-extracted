use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Basename;
use App::BlurFill::CLI;

my $image = "t/test.jpg";
plan skip_all => "Test image $image not found" unless -e $image;

# Simulate @ARGV as CLI would receive it
local @ARGV = ($image);

# Run the CLI logic
App::BlurFill::CLI->new->run;

# Check for the expected output file
my ($name, $path, $ext) = fileparse($image, qr/\.[^.]*$/);
my $expected = "${path}${name}_blur$ext";

ok(-e $expected, "Output file $expected exists");

# Clean up
unlink $expected;

done_testing;

