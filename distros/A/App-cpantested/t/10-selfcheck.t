#!perl
use strict;
use utf8;
use warnings qw(all);

use File::Spec::Functions;
use IO::Socket::INET;
use Test::More;

plan skip_all => q(no direct Internet connection)
    unless IO::Socket::INET->new(
        PeerHost  => q(cpantesters.org),
        PeerPort  => 80,
        Proto     => q(tcp),
        Timeout   => 10,
    );

my $reference = catfile(qw(t dists));
my $utility = catfile(qw(bin cpan-tested));

ok(-f $reference, q(reference exists));
ok(-f $utility, q(utility exists));

my $fh;
ok(open($fh, q(<), $reference), q(reference file));
my @reference = <$fh>;
close $fh;
is(scalar @reference, 5, q(reference count));

ok(open($fh, q(-|), qq($^X $utility --no-osname --verbose $reference)), q(pipe));
my @tested = <$fh>;
close $fh;

is_deeply(\@reference, \@tested, q(identity));

done_testing 6;
