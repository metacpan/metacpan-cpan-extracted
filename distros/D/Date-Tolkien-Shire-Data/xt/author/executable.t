package main;

use strict;
use warnings;

use ExtUtils::Manifest qw{maniread};
use Test::More 0.47;	# The best we can do with Perl 5.6.2.

my $manifest = maniread();

my @file;

foreach ( sort keys %{ $manifest } ) {
    m{ \A bin / }smx
	and next;
    m{ \A eg / }smx
	and next;
    m{ \A tools / }smx
	and next;

    push @file, $_;
}

plan tests => scalar @file;

foreach ( @file ) {
    ok( ! is_executable(), "$_ should not be executable" );
}

sub is_executable {
    my @stat = stat $_;
    $stat[2] & oct(111)
	and return 1;
    open my $fh, '<', $_ or die "Unable to open $_: $!\n";
    local $_ = <$fh>;
    close $fh;
    return m{ \A [#]! .* perl }smx;
}

1;

# ex: set textwidth=72 :
