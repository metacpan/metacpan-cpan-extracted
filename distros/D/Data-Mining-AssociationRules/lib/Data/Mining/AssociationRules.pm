package Data::Mining::AssociationRules;

use strict;
use warnings;

BEGIN {
        use Exporter ();
        use vars qw ($AUTHOR $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
        $AUTHOR      = 'Dan Frankowski <dfrankow@winternet.com>';
        @EXPORT      = @EXPORT_OK = qw(generate_frequent_sets
                                       generate_rules
                                       read_frequent_sets
                                       read_transaction_file
                                       set_debug);
                                       
        %EXPORT_TAGS = ();
        @ISA         = qw(Exporter);
        $VERSION     = 0.1;
}

my $debug = 0;

=head1 NAME

Data::Mining:AssociationRules - Mine association rules and frequent
sets from data.

=head1 SYNOPSIS

 use Data::Mining::AssociationRules;

 my %transaction_map;
 my $transaction_file = "foo.txt";

 read_transaction_file(\%transaction_map, $transaction_file);

 generate_frequent_sets(\%transaction_map, $output_file_prefix,
                        $support_threshold, $max_n);

 generate_rules($output_file_prefix, $support_threshold,
                $confidence_threshold, $max_n);

 read_frequent_sets($set_map_ref, $file_prefix)

 set_debug(1);

 perl arm.pl -transaction-file foo.txt -support 2 -confidence-threshold 0.01 -max-set-size 6

 See also FUNCTIONS, DESCRIPTION, and EXAMPLES below.

=head1 INSTALLATION

The typical:

=over

=item 0 perl Makefile.PL

=item 0 make test

=item 0 make install

=back

=head1 FUNCTIONS

=cut

=pod

=head2 read_transaction_file($transaction_map_ref, $transaction_file)

Read in a transaction map from a file which has lines of two
whitespace-separated columns:

=over

 transaction-id item-id

=back

=cut

sub read_transaction_file {
  my $transaction_map_ref = shift;
  my $transaction_file = shift;

  open(BFILE, $transaction_file) or die "Couldn't open $transaction_file: $!\n";
  while ( <BFILE> ) {
    my @data = split;
    die "Expected 2 columns, found ", int(@data), "\n" if int(@data) != 2;
    my ($tid, $item) = @data;
    $$transaction_map_ref{$item}{$tid}++;
  }
  close(BFILE);
}

=pod

=head2 generate_frequent_sets ($transaction_map_ref, $file_prefix, $support_threshold, $max_n)

Given

=over

=item 0 a map of transactions

=item 0 a file prefix

=item 0 a support threshold

=item 0 a maximum frequent set size to look for (optional)

=back

generate the frequent sets in some files, one file per size of the set.
That is, all 1-sets are in a file, all 2-sets in another, etc.

The files are lines of the form:

=over

 support-count item-set

=back

where

=over

=item 0 support-count is the number of transactions in which the item-set appears

=item 0 item-set is one or more space-separated items

=back

=cut

sub generate_frequent_sets {
  my $transaction_map_ref = shift;
  my $file_prefix = shift;
  my $support_threshold = shift;
  my $max_n = shift;

  # Generate 1-sets
  my $n = 1;
  my $out_nset = nset_filename($n, $file_prefix, $support_threshold);
  open(OUT, ">$out_nset") or die "Couldn't open $out_nset for writing: $!\n";
  while (my ($item, $item_map) = each %{$transaction_map_ref}) {
    my $support = int(keys(%$item_map));
    if ($support >= $support_threshold) {
      print OUT "$support $item\n";
    }
  }
  my $num_nsets = int(keys(%{$transaction_map_ref}));
  print STDERR "$num_nsets $n-sets\n" if $debug;
  close(OUT);

  # Generate n-sets
  my $done = 0;
  while ($num_nsets > 0) {
    $n++;
    $num_nsets = 0;

    last if defined($max_n) && ($n > $max_n);

    # Go through (n-1)-sets, pruning as you go
    my $prior_nset = nset_filename($n-1, $file_prefix, $support_threshold);
    open(PRIOR, $prior_nset) or die "Couldn't open $prior_nset: $!\n";
    $out_nset = nset_filename($n, $file_prefix, $support_threshold);
    open(OUT, ">$out_nset") or die "Couldn't open $out_nset: $!\n";
    while ( <PRIOR> ) {
      my ($count, @set) = split;
      
      # Create userset, which contains the intersection of $transaction{@set}
      my %userset = % {$$transaction_map_ref{$set[0]}};
      foreach my $item ( @set[1 .. $#set] ) {
        while (my ($user, $dummy) = each %userset) {
          if (!exists($$transaction_map_ref{$item}{$user})) {
            delete($userset{$user});
          }
        }
      }
      
      # For each 1-set, intersect further, and spit out if > support_threshold
      while (my ($item, $user_set) = each %{$transaction_map_ref}) {
	# Only spit sets of non-decreasing elements
	# This keeps out duplicates
	my $dup_set = 0;
	foreach my $set_item ( @set ) {
          if ($set_item ge $item) {
            $dup_set = 1;
            last;
          }
	}
        
	if (!$dup_set) {
          my %newset = %userset;
          while (my ($user, $dummy) = each %newset) {
            if (!exists($$user_set{$user})) {
              delete($newset{$user});
            }
          }
          #print "newset is now " . map_str(\%newset) . "\n";
          my $num_users = int(keys(%newset));
          #print "item $item set @set numusers is $num_users\n";
          if ($num_users >= $support_threshold) {
            print OUT "$num_users @set $item\n";
            $num_nsets++;
          }
	}
      }
    }
    close(PRIOR);
    close(OUT);
    print STDERR "$num_nsets $n-sets\n" if ($num_nsets > 0) && $debug;
    unlink($out_nset) if 0 == $num_nsets;
  }
}

=pod

=head2 read_frequent_sets($set_map_ref, $file_prefix)

Given

=over

=item 0 a set map

=item 0 a file prefix

=item 0 support threshold

=item 0 max frequent set size (optional)

=back

read all the frequent sets into a single map, which has as its key the
frequent set (joined by single spaces) and as its value the support.

=cut

sub read_frequent_sets {
  my $set_map_ref = shift;
  my $file_prefix = shift;
  my $support_threshold = shift;
  my $max_n = shift;

  opendir(DIR, '.') || die "can't opendir '.': $!";
  my @files = grep { /^$file_prefix/ && -f "./$_" } readdir(DIR);
  closedir DIR;

  foreach my $file (@files) {
    # print STDERR "Read file $file ..\n";
    if ( $file =~ /${file_prefix}\-support\-(\d+)\-(\d+)set/ ) {
      my $support = $1;
      my $n = $2;
      next if ($support != $support_threshold)
              || (defined($max_n) && ($n > $max_n));

      open(SETS, $file) or die "Couldn't open $file: $!\n";
      while ( <SETS> ) {
        my ($count, @set) = split;
        $$set_map_ref{join(' ', @set)} = $count;
      }
      close(SETS);
    }
  }
}

# =pod

# =head2 nset_filename($n, $file_prefix, $support_threshold)

# Given

# =over

# =item 0 set size

# =item 0 a file prefix

# =item 0 a support threshold

# =back

# return the name of the file that contains the specified frequent sets.

# =cut
sub nset_filename {
  my $n = shift;
  my $file_prefix = shift;
  my $support_threshold = shift;

  return $file_prefix . "-support-" . $support_threshold . "-" . $n . "set.txt";
}

=pod

=head2 generate_rules($file_prefix, $support_threshold, $max_n)

Given

=over

=item 0 a file prefix

=item 0 a support threshold (optional)

=item 0 a confidence threshold (optional)

=item 0 maximum frequent set size to look for (optional)

=back

create a file with all association rules in it.  The output file is of
the form:

 support-count confidence left-hand-set-size right-hand-set-size frequent-set-size left-hand-set => right-hand-set

=cut

sub generate_rules {
  my $file_prefix = shift;
  my $support_threshold = shift;
  my $confidence_threshold = shift;
  my $max_n = shift;

  $support_threshold = 1 if !defined($support_threshold);
  $confidence_threshold = 0 if !defined($confidence_threshold);

  my $num_rules = 0;

  # Read in frequent set supports
  my %frequent_set;
  read_frequent_sets(\%frequent_set, $file_prefix, $support_threshold, $max_n);

  die "Found no frequent sets from file prefix $file_prefix support $support_threshold " if (0 == int(keys(%frequent_set)));

  # Go through the sets computing stats
  my $rulefile = $file_prefix . '-support-' . $support_threshold . '-conf-' .
    $confidence_threshold . '-rules.txt';
  open(RULES, ">$rulefile") or die "Couldn't open $rulefile: $!\n";
  while (my ($set, $count) = each %frequent_set) {
    # Traverse all subsets (save full and empty)
    my $support = $frequent_set{$set};
    die "Couldn't find frequent set '$set'" if !defined($support);
    my @set = split('\s+', $set);

    for my $lhs_selector (1..(1<<int(@set))-2) {
      my @lhs_set = @set[grep $lhs_selector&1<<$_, 0..$#set];
      my $all_ones = (1<<int(@set))-1;
      my $rhs_selector = $all_ones ^ $lhs_selector;
      my @rhs_set = @set[grep $rhs_selector&1<<$_, 0..$#set];
      # print "lhs_selector $lhs_selector 1<<int(@set) ", 1<<int(@set), " rhs_selector $rhs_selector\n";

      # print "lhs_set @lhs_set ";
      # print "rhs_set @rhs_set\n";

      my $lhs_set = join(' ', @lhs_set);
      my $rhs_set = join(' ', @rhs_set);

      # Spit out rule
      my $lhs_support = $frequent_set{$lhs_set};
      #my $rhs_support = $frequent_set{$rhs_set};
      die "Couldn't find frequent set '$lhs_set'" if !defined($lhs_support);
      #die "Couldn't find frequent set '$rhs_set'" if !defined($rhs_support);

      # For rule A => B,  support = T(AB), conf = T(AB) / T(A)
      my $conf = $support / $lhs_support;

      if ($conf >= $confidence_threshold) {
        $num_rules++;
        print RULES "$support ", sprintf("%.3f ", $conf),
                    int(@lhs_set), ' ', int(@rhs_set), ' ', int(@set), ' ',
                    "$lhs_set => $rhs_set\n";
      }
    }
  }
  close(RULES);
  print STDERR "$num_rules rules\n" if $debug;
}

sub set_debug {
  $debug = $_[0];
}

1;

=head1 DESCRIPTION

This module contains some functions to do association rule mining from
text files.  This sounds obscure, but really measures beautifully
simple things through counting.

=head2 FREQUENT SETS

Frequent sets answer the question, "Which events occur together more
than N times?"

=head3 The detail

The 'transaction file' contains items in transactions.  A set of items
has 'support' s if all the items occur together in at least s
transactions.  (In many papers, support is a number between 0 and 1
representing the fraction of total transactions.  I found the absolute
number itself more interesting, so I use that instead.  Sorry for the
confusion.)  For an itemset "A B C", the support is sometimes notated
"T(A B C)" (the number of 'T'ransactions).

A set of items is called a 'frequent set' if it has support at least
the given support threshold. Generating frequent set produces all
frequent sets, and some information about each set (e.g., its
support).

=head2 RULES

Association rules answer the (related) question, "When these events
occur, how often do those events also occur?"

=head3 The detail

A rule has a left-hand set of items and a right-hand set
of items.  A rule "LHS => RHS" with a support s and 'confidence' c means
that the underlying frequent set (LHS + RHS) occured together in at
least s transactions, and for all the transactions LHS occurred in,
RHS also occured in at least the fraction c (a number from 0 to 1).

Generating rules produces all rules with support at least the given
support threshold, and confidence at least the given confidence
threshold.  The confidence is sometimes notated "conf(LHS => RHS) =
T(LHS + RHS) / T(LHS)".  There is also related data with each rule
(e.g., the size of its LHS and RHS, the support, the confidence,
etc.).

=head3 FREQUENT SETS AND ASSOCIATION RULES GENERALLY USEFUL

Although association rule mining is often described in commercial
terms like "market baskets" or "transactions" (collections of events)
and "items" (events), one can imagine events that make this sort of
counting useful across many domains.  Events could be

=over

=item 0 stock market went down at time t

=item 0 patient had symptom X

=item 0 flower petal length was > 5mm

=back

For this reason, I believe counting frequent sets and looking at
association rules to be a fundamental tool of any data miner, someone
who is looking for patterns in pre-existing data, whether commercial
or not.

=head1 EXAMPLES

Given the following input file:

 234 Orange
 463 Strawberry
 53 Apple
 234 Banana
 412 Peach
 467 Pear
 234 Pear
 147 Pear
 141 Orange
 375 Orange

Generating frequent sets at support threshold 1 (a.k.a.  'at support 1')
produces three files:

The 1-sets:

 1 Strawberry
 1 Banana
 1 Apple
 3 Orange
 1 Peach
 3 Pear

The 2-sets:

 1 Banana Orange
 1 Banana Pear
 1 Orange Pear

The 3-sets:

 1 Banana Orange Pear

Generating the rules at support 1 produces the following:

  1 0.333 1 1 2 Orange => Pear
  1 0.333 1 1 2 Pear => Orange
  1 1.000 1 2 3 Banana => Orange Pear
  1 0.333 1 2 3 Orange => Banana Pear
  1 1.000 2 1 3 Banana Orange => Pear
  1 0.333 1 2 3 Pear => Banana Orange
  1 1.000 2 1 3 Banana Pear => Orange
  1 1.000 2 1 3 Orange Pear => Banana
  1 1.000 1 1 2 Banana => Orange
  1 0.333 1 1 2 Orange => Banana
  1 1.000 1 1 2 Banana => Pear
  1 0.333 1 1 2 Pear => Banana

Generating frequent sets at support 2 produces one file:

 3 Orange
 3 Pear

Generating rules at support 2 produces nothing.

Generating rules at support 1 and confidence 0.5 produces:

  1 1.000 1 2 3 Banana => Orange Pear
  1 1.000 2 1 3 Banana Orange => Pear
  1 1.000 2 1 3 Banana Pear => Orange
  1 1.000 2 1 3 Orange Pear => Banana
  1 1.000 1 1 2 Banana => Orange
  1 1.000 1 1 2 Banana => Pear

Note all the lower confidence rules are gone.

=head1 ALGORITHM

=head2 Generating frequent sets

Generating frequent sets is straight-up Apriori.  See for example:

http://www.almaden.ibm.com/software/quest/Publications/papers/vldb94_rj.pdf

I have not optimized.  It depends on having the transactions all in
memory.  However, given that, it still might scale decently (millions
of transactions).

=head2 Generating rules

Generating rules is a very vanilla implementation.  It requires
reading all the frequent sets into memory, which does not scale at
all.  Given that, since computers have lots of memory these days, you
might still be able to get away with millions of frequent sets (which
is <<millions of transactions).

=head1 BUGS

There is an existing tool (written in C) to mine frequent sets I kept
running across:

http://fuzzy.cs.uni-magdeburg.de/~borgelt/software.html#assoc

I should check it out to see if it is easy or desirable to be
file-level compatible with it.

One could imagine wrapping it in Perl, but the Perl-C/C++ barrier is
where I have encountered all my troubles in the past, so I wouldn't
personally pursue that.

=head1 VERSION

This document describes Data::Mining::AssociationRules version 0.1.

=head1 AUTHOR

 Dan Frankowski
 dfrankow@winternet.com
 http://www.winternet.com/~dfrankow

 Hey, if you download this module, drop me an email! That's the fun
 part of this whole open source thing.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
in the distribution and available in the CPAN listing for
Data::Mining::AssociationRules (see www.cpan.org or search.cpan.org).

=head1 DISCLAIMER

To the maximum extent permitted by applicable law, the author of this
module disclaims all warranties, either express or implied, including
but not limited to implied warranties of merchantability and fitness
for a particular purpose, with regard to the software and the
accompanying documentation.

=cut
