use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

my $cmd = qq[$^X -I"$Bin/../lib" -MO=Deparse "$Bin/actually_constant.t" 2>/dev/null];
my $output = qx[$cmd];

# Some platforms like Windows don't like this test, just skip it there
# but try to perform it elsewhere.
if (defined $output) {
    chomp $output;
    if ($output =~ /\bpackage TestConstant\b/) {
        plan(tests => 5);
        like($output, qr/\buse Constant::Export::Lazy\b/, "we found a Constant::Export::Lazy 'use' line");
        unlike($output, qr/my\s*\(\s*\$sub\s*,\s*\$what\s*\)\s*=\s*\@\$test.*?ARRAY/m, "Our output should have the ARRAY; call optimized out");
        like(  $output, qr/my\s*\(\s*\$sub\s*,\s*\$what\s*\)\s*=\s*\@\$test.*?'sub'\s*,\s*'what'/m , "That ARRAY; call should be inlined");
        unlike($output, qr/\bif\s*\(\s*TRUE/m, "Our output should have if TRUE call optimized out");
        unlike($output, qr/\bfail\b.*?\bHASH\b.*'out'/m, "Our output should have the fail() call optimized out");
    } else {
        plan(skip_all => "We couldn't get output we could work with from <$cmd> on this platform. Got <$output>");
    }
} else {
    plan(skip_all => "We couldn't get any output from <$cmd>");
}
