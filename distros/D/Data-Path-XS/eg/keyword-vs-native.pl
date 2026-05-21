#!/usr/bin/env perl
# Side-by-side comparison: native Perl deref vs Data::Path::XS keyword.
#
# Both forms produce the same value; the goal is to show that the
# keyword form is just as readable and just as fast (sometimes faster
# on the missing-key path because of early termination).

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Benchmark qw(cmpthese);
use Data::Path::XS ':keywords';

my $data = {
    users => [
        { id => 1, name => 'alice', addr => { city => 'NYC',    zip => '10001' } },
        { id => 2, name => 'bob',   addr => { city => 'Boston', zip => '02101' } },
    ],
};

# === Side-by-side readability ===
my $a = $data->{users}[0]{addr}{city};   # native
my $b = pathget $data, "/users/0/addr/city";   # keyword
print "native : $a\n";
print "kw     : $b\n";
$a eq $b or die 'sanity check failed';

# === Missing-key safety: native autovivifies under deref-on-write ===
my $miss_native = exists $data->{users}[5] ? $data->{users}[5]{name} : undef;
my $miss_kw     = pathget $data, "/users/5/name";
defined $miss_native and die 'native test data wrong';
defined $miss_kw     and die 'kw test data wrong';
print "missing key: both undef, but pathget did NOT autovivify users[5]\n";
print "  users count after pathget: ", scalar(@{$data->{users}}), "\n";

# === Throughput ===
print "\nBenchmark (1M iterations each):\n";
cmpthese(-1, {
    'native deref'   => sub { my $v = $data->{users}[0]{addr}{city}; },
    'pathget const'  => sub { my $v = pathget $data, "/users/0/addr/city"; },
    'pathget dyn'    => sub { my $p = "/users/0/addr/city";
                              my $v = pathget $data, $p; },
});

print "\nMissing-key throughput:\n";
cmpthese(-1, {
    'native (exists chain)' => sub {
        my $v = exists $data->{users} && exists $data->{users}[5]
              && exists $data->{users}[5]{name}
              ? $data->{users}[5]{name} : undef;
    },
    'pathget' => sub { my $v = pathget $data, "/users/5/name"; },
});
