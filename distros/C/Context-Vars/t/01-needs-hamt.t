#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);

# HAMT is required, with nothing to fall back to, so each way of not having a
# usable one has to stop the load and say which it was. Each case is a child
# perl, because a module that failed to load cannot be loaded again in the
# same process to try the next one.
#
# The child is started with the list form of open, so no shell is involved,
# and it sends its own STDERR to STDOUT so the message comes back down the
# one pipe.

my @inc = map { "-I$_" } grep { !ref } @INC;

sub child {
    my ($code) = @_;
    my $pid = open(my $out, '-|', $^X, @inc, '-e',
                   'BEGIN { open STDERR, ">&", \*STDOUT or die $! } ' . $code);
    defined $pid or die "cannot start $^X: $!";
    local $/;
    my $text = <$out>;
    close $out;
    return ($? >> 8, defined $text ? $text : '');
}

# The control: the same child, with nothing in the way, loads. Without this
# the three cases below would pass against a module that never loads at all.
{
    my ($rc, $text) = child('require Context::Vars; print "loaded ", Context::Vars::_hamt_abi_version(), "\n"');
    is($rc, 0, 'with HAMT available the child loads Context::Vars') or diag($text);
    like($text, qr/^loaded \d+$/m, 'and reports the table it resolved');
}

# HAMT cannot be found.
{
    my ($rc, $text) = child(
        'BEGIN { unshift @INC, sub { die "HAMT is hidden for this test\n" if $_[1] eq "HAMT.pm"; return } } '
      . 'require Context::Vars; print "LOADED\n"');
    isnt($rc, 0, 'with HAMT hidden the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/Context::Vars needs HAMT/, 'the message names what is needed');
    like($text, qr/could not load it/, 'says it could not be loaded');
    like($text, qr/HAMT is hidden for this test/, 'and carries the reason perl gave');
}

# A HAMT that loads and has no table to give.
my $fake = tempdir(CLEANUP => 1);
sub fake_hamt {
    my ($body) = @_;
    my $file = File::Spec->catfile($fake, 'HAMT.pm');
    open(my $fh, '>', $file) or die "cannot write $file: $!";
    print {$fh} "package HAMT;\nour \$VERSION = '0.00';\n$body\n1;\n";
    close $fh or die "cannot close $file: $!";
}
my $use_fake = 'BEGIN { unshift @INC, q{' . $fake . '} } ';

{
    fake_hamt('sub _abi_ptr { 0 }');
    my ($rc, $text) = child($use_fake . 'require Context::Vars; print "LOADED\n"');
    isnt($rc, 0, 'with a HAMT that returns no table the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/has no C ABI table/, 'and the message says there is no table');
}

# A HAMT whose table is older than the one this module was built against.
# The table's first member is an int, so a packed int is a table of version
# 0, and `pack "p"` gives the address of that string's buffer. The address is
# pointer-sized, which is not the IV size on a 32-bit perl built with 64-bit
# integers, so it is read back as Q or L to match, never as J.
{
    fake_hamt('our $TABLE = pack("i", 0); '
            . 'sub _abi_ptr { unpack(length(pack("p", "")) == 8 ? "Q" : "L", pack("p", $TABLE)) }');
    my ($rc, $text) = child($use_fake . 'require Context::Vars; print "LOADED\n"');
    isnt($rc, 0, 'with a HAMT whose table is too old the load fails');
    unlike($text, qr/LOADED/, 'nothing after the require ran');
    like($text, qr/at version (\d+) or later: the HAMT that loaded has version 0/,
         'and the message names the version needed and the version found');
}

done_testing;
