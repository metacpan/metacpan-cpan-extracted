#!perl

use strict;
use warnings;

use lib 'lib';

use Data::Dumper;
use Getopt::Long;
use BackPAN::Index;

my $index_url;
GetOptions( 'index' => \$index_url );

my $args = $index_url ? { backpan_index_url => $index_url } : {};
my $backpan = BackPAN::Index->new($args);

sub usage {
    my $cmd = shift;

    print STDERR <<USAGE if $cmd;
Unknown command '$cmd'

USAGE

    print STDERR <<USAGE;
Usage:
  $0 dist     <dist name>
  $0 dists_by <cpanid>
USAGE

    exit 1;
}

my $cmd = shift;
my $arg = shift;

my %Commands = (
    dist        => \&command_dist,
    dists_by    => \&command_dists_by
);

main($cmd, $arg);

sub main {
    my $func = $Commands{$cmd} || do { usage($cmd) };

    $func->($arg);
}

sub command_dist {
    my $name = shift;

    my $backpan = BackPAN::Index->new;
    my $dist = $backpan->dist($name);

    do { print "Unknown dist '$dist'.\n"; exit 1; } unless $dist;

    print <<OUT;
Name:      @{[ $dist->name ]}
Authors:   @{[ join ", ", $dist->authors ]}
Releases:
OUT

    for my $release ($dist->releases->search(undef, { order_by => "version" })) {
        my $distvname = $release->distvname;
        print "           $distvname\n";
    }
}


sub command_dists_by {
    my $cpanid = shift;

    my $backpan = BackPAN::Index->new;
    my @dists = $backpan->dists_by($cpanid);

    do { print "CPANID '$cpanid' has no distributions.\n"; exit 1; } unless @dists;

    print join "\n", map { $_->name } @dists;
}

__END__

=head1 NAME

examples/backpan.pl - a simple demo for BackPAN::Index

=head1 USAGE

  $ perl examples/backpan.pl dist Dist-Name

  $ perl examples/backpan.pl dist_by CPANID

=head1 DESCRIPTION

This demo creates a BackPAN::Index instance,
which downloads from web and parses a BACKPAN index
and then shows up either the distributions of a given
name or the the distributions of a certain CPAN author.

=cut
