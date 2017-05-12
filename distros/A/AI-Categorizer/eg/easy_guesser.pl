#!/usr/bin/perl

# This script can be helpful for getting a set of baseline scores for
# a categorization task.  It simulates using the "Guesser" learner,
# but is much faster.  Because it doesn't leverage using the whole
# framework, though, it expects everything to be in a very strict
# format.  <cats-file> is in the same format as the 'category_file'
# parameter to the Collection class.  <training-dir> and <test-dir>
# give paths to directories of documents, named as in <cats-file>.

use strict;
use Statistics::Contingency;

die "Usage: $0 <cats-file> <training-dir> <test-dir>\n" unless @ARGV == 3;
my ($cats, $training, $test) = @ARGV;

die "$cats isn't a plain file\n" unless -f $cats;
die "$training isn't a directory\n" unless -d $training;
die "$test isn't a directory\n" unless -d $test;

my %cats;
print "Reading category file\n";
open my($fh), $cats or die "Can't read $cats: $!";
while (<$fh>) {
    my ($doc, @cats) = split;
    $cats{$doc} = \@cats;
}

my (%freq, $docs);
print "Scanning training set\n";
opendir my($dh), $training or die "Can't opendir $training: $!";
while (defined(my $file = readdir $dh)) {
    next if $file eq '.' or $file eq '..';
    unless ($cats{$file}) {
	warn "No category information for '$file'";
	next;
    }
    $docs++;
    $freq{$_}++ foreach @{$cats{$file}};
}
closedir $dh;

print "Calculating probabilities (@{[ %freq ]})\n";
$_ /= $docs foreach values %freq;
my @cats = keys %freq;

print "Scoring test documents\n";
my $c = Statistics::Contingency->new(categories => \@cats);
opendir $dh, $test or die "Can't opendir $test: $!";
while (defined(my $file = readdir $dh)) {
    next if $file eq '.' or $file eq '..';
    unless ($cats{$file}) {
	warn "No category information for '$file'";
	next;
    }
    my @assigned;
    foreach (@cats) {
	push @assigned, $_ if rand() < $freq{$_};
    }
    $c->add_result(\@assigned, $cats{$file});
}

print $c->stats_table(4);
