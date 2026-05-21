#!/usr/bin/env perl
# Walk every leaf of a nested structure, emitting "PATH = VALUE" lines.
#
# Data::Path::XS itself doesn't traverse — it answers point queries —
# but the array API composes naturally with a recursive walker that
# keeps the path components on the stack.
#
# Usage:
#   perl eg/walk.pl file.json
#   echo '{"a":[1,{"b":2},3]}' | perl eg/walk.pl
#
# Output:
#   /a/0 = 1
#   /a/1/b = 2
#   /a/2 = 3

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use JSON::PP;
use Data::Path::XS qw(patha_get);

my $json = @ARGV ? do { local $/; open my $f, '<', $ARGV[0] or die "$ARGV[0]: $!"; <$f> }
                 : do { local $/; <STDIN> };
my $data = decode_json($json);

sub walk {
    my ($v, $path, $cb) = @_;
    if (ref $v eq 'HASH') {
        for my $k (sort keys %$v) {
            walk($v->{$k}, [@$path, $k], $cb);
        }
    } elsif (ref $v eq 'ARRAY') {
        for my $i (0 .. $#$v) {
            walk($v->[$i], [@$path, $i], $cb);
        }
    } else {
        $cb->($path, $v);
    }
}

walk($data, [], sub {
    my ($path, $value) = @_;
    my $str = '/' . join('/', @$path);
    no warnings 'uninitialized';
    print "$str = $value\n";

    # Round-trip sanity: patha_get with the recorded path returns the
    # same scalar value.
    my $back = patha_get($data, $path);
    die "round-trip mismatch at $str" if (defined($back) ne defined($value))
                                      || (defined($back) && $back ne $value);
});
