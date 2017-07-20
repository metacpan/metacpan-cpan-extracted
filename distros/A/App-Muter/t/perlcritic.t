#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use File::Find;
use Test::More;

unless (eval { require Perl::Critic; }) {
    plan skip_all => 'perlcritic is missing';
}

unless (-d "$FindBin::Bin/../.git") {
    plan skip_all => 'perlcritic tests broken by Dist::Zilla';
}

my $critic = Perl::Critic->new(
    -profile  => '',
    -severity => 4,
);

File::Find::find(
    sub {
        my $name = $File::Find::name;
        return unless $name =~ /\.pm$/;
        my @violations = $critic->critique($name);
        is(scalar @violations, 0, "no violations in $name") or
            diag explain \@violations;
    },
    "$FindBin::Bin/../lib"
);

done_testing();
