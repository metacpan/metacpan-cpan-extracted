
#
# Bug in 2.02 and earlier meant things like i_am_speedy couldn't be called
# from within a BEGIN block.
#

print "1..2\n";

use Config qw(%Config);

sub am_speedy { my $prog = shift;
    my $v = `$prog t/scripts/begin_block`;
    return $v ne '' && $v > 0;
}

print &am_speedy($Config{perlpath}) ? "not ok\n" : "ok\n";
print &am_speedy($ENV{SPEEDY})      ? "ok\n"     : "not ok\n";
