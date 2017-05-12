#!/usr/bin/perl -w

# for your own pleasure and curiosity
use strict;
use blib;
use Algorithm::Permute 'permute';
use Benchmark ':all';
use Getopt::Std;

# process options
my %opts;
getopts('yrhl:n:', \%opts) or usage();
$opts{h} and usage();
$opts{n} ||= 9;
$opts{l} ||= 5;
my @arr = (1..$opts{n});

# runners
my %runners = (
   'Combinatorial::Permutations' => sub { 
        my @res = Combinatorial::Permutations::permutate(@arr);
    },
    'Memoization' => sub {
        my $num_permutations = PMemoization::factorial(scalar @arr);
        for (my $i=0; $i < $num_permutations; $i++) {
            my @permutation = @arr[PMemoization::n2perm($i, $#arr)];
            # print "@permutation\n";
        }
    },
    'LISPy' => sub { LISPy::faq_permute([@arr], []) },
    'List::Permutor' => sub {
        my $l = new List::Permutor(@arr);
        while (my @res = $l->next) {}
    },
    'Algorithm::Permute' => sub {
        my $p = new Algorithm::Permute([@arr]);
        while (my @res = $p->next) {}
    },
    'Algorithm::Permute qw(permute)' => sub { 
        permute { my @res = @arr } @arr;
    },
    'Algorithm::Combinatorics' => sub { 
        my $i = Algorithm::Combinatorics::permutations(\@arr);
        while (my $p = $i->next) {} 
    },
    'Math::Combinatorics' => sub {
        my $combinat = Math::Combinatorics->new(count => $opts{n}, data => \@arr);
        while (my @res = $combinat->next_permutation) {}
    },
);

my @modules;
# load optional modules
my @optionals = 
    qw/Algorithm::Combinatorics Math::Combinatorics List::Permutor/;
foreach my $m (@optionals) {
    eval "require $m";
    if ($@) {
        print "Unable to load $m. Not yet installed?\n";
    } else {
        print "Module $m loaded.\n";
        push @modules, $m;
    }
}

# give user a chance to select modules to his/her interest
print "\nRun benchmark against:\n";
my @selected = grep {
    print "$_ [Y/n]? "; 
    if ($opts{'y'}) { print "Y\n"; 1 }
    else { my $ans = <>; $ans !~ /^N/i }
} @modules, qw/Combinatorial::Permutations Memoization LISPy/;
print "\n";

my $i = 0;
my %modules = map {
    sprintf("%02d_", $i++) . $_ => $runners{$_} 
} 'Algorithm::Permute qw(permute)', 'Algorithm::Permute', @selected;

# run benchmark
my $b = timethese($opts{l}, \%modules);
$opts{r} and do { print "\n"; cmpthese($b); };

sub usage {
    print <<"USAGE";
$0 [options]

-h  this help
-l  number of loop (default: 5)
-n  size of array  (default: 9)
-r  print benchmark comparison chart (default: no)
-y  yes to all confirmation question (default: no) 

Example: 
Run permutation of 8 objects in 10 loop, and print comparison chart:
perl benchmark.pl -l 10 -n 8 -r

USAGE
    exit;
}

package LISPy;

no strict;
no warnings;

sub faq_permute{
    my @items = @{ $_[0] };
    my @perms = @{ $_[1] };
    unless (@items) {
        # print "@perms\n";
        @res = @perms;
    } else {
        my(@newitems,@newperms,$i);
        foreach $i (0 .. $#items) {
            @newitems = @items;
            @newperms = @perms;
            unshift(@newperms, splice(@newitems, $i, 1));
            faq_permute([@newitems], [@newperms]);
        }
    }
}

package PMemoization; # permutation utilizing memoization

use strict;

# Utility function: factorial with memorizing
BEGIN {
  no warnings;
  my @fact = (1);
  sub factorial($) {
      my $n = shift;
      return $fact[$n] if defined $fact[$n];
      $fact[$n] = $n * factorial($n - 1);
  }
}

# n2pat($N, $len) : produce the $N-th pattern of length $len
sub n2pat {
    my $i   = 1;
    my $N   = shift;
    my $len = shift;
    my @pat;
    while ($i <= $len + 1) {   # Should really be just while ($N) { ...
        push @pat, $N % $i;
        $N = int($N/$i);
        $i++;
    }
    return @pat;
}

# pat2perm(@pat) : turn pattern returned by n2pat() into
# permutation of integers.  XXX: splice is already O(N)
sub pat2perm {
    my @pat    = @_;
    my @source = (0 .. $#pat);
    my @perm;
    push @perm, splice(@source, (pop @pat), 1) while @pat;
    return @perm;
}

# n2perm($N, $len) : generate the Nth permutation of S objects
sub n2perm {
    pat2perm(n2pat(@_));
}

package Combinatorial::Permutations; # from abigail

use strict;
use Exporter;

use vars qw /@EXPORT @EXPORT_OK @ISA/;

@ISA       = qw /Exporter/;
@EXPORT    = ();
@EXPORT_OK = qw /permutate/;

sub permutate (@);

# Return a list of permutations of the given list.
sub permutate (@) {
    return () unless @_;
    my $first = shift;
    return ([$first]) unless @_;

    map {my $row = $_;
         map {my $tmp = [@$row];
              splice @$tmp, $_, 0, $first; $tmp;} (0 .. @$row);} permutate @_;
}

