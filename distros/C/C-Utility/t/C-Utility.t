use warnings;
use strict;
use Test::More tests => 3;
BEGIN { use_ok('C::Utility') };
use C::Utility ':all';

my $in = <<EOF;
This is the " input string.
EOF

my $out = convert_to_c_string ($in);
#print "$out\n";
ok ($out eq '"This is the \" input string.\n"'."\n");

my $percent = 'This has a percent %';

my $out2 = convert_to_c_string_pc ($percent);

ok ($out2 eq '"This has a percent %%"');

# Local variables:
# mode: perl
# End:
