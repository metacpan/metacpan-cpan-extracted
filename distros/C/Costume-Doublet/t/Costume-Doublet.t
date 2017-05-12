# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Costume-Doublet.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
BEGIN { use_ok('Costume::Doublet') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $pattern_image = "test_pat.png";
unlink ($pattern_image);
Costume::Doublet::make_pattern( chest       => 46,
				waist       => 40,
				back_length => 23,
				shoulder     => 6.75,
				front_width => 15.75,
				back_width  => 17,
				unit        => "inch",
				name        => "Zach Kessin",
				output      => $pattern_image);

system "eog -n $pattern_image";
