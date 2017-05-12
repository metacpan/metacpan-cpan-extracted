package AI::Gene::Simple;
require 5.6.0;
use strict;
use warnings;

BEGIN {
  use Exporter   ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION     = 0.20;
  @ISA         = qw(Exporter);
  @EXPORT      = ();
  %EXPORT_TAGS = ();
  @EXPORT_OK   = qw();
}
our @EXPORT_OK;

my ($probs,$mut_keys) = _normalise( { map {$_ => 1} 
				      qw(insert remove overwrite 
					 duplicate minor major 
					 switch shuffle reverse) } );
##
# calls mutation method at random
# 0: number of mutations to perform
# 1: ref to hash of probs to use (otherwise uses default mutations and probs)

sub mutate {
  my $self = shift;
  my $num_mutates = +$_[0] || 1;
  my $rt = 0;
  my ($hr_probs, $muts);
  if (ref $_[1] eq 'HASH') { # use non standard mutations or probs
    ($hr_probs, $muts) = _normalise($_[1]);
  }
  else {                     # use standard mutations and probs
    $hr_probs = $probs;
    $muts = $mut_keys;
  }

 MUT_CYCLE: for (1..$num_mutates) {
    my $rand = rand;
    foreach my $mutation (@{$muts}) {
      next unless $rand < $hr_probs->{$mutation};
      my $mut = 'mutate_' . $mutation;
      $rt += $self->$mut(1);
      next MUT_CYCLE;
    }
  }
  return $rt;
}

##
# creates a normalised and cumulative prob distribution for the
# keys of the referenced hash

sub _normalise {
  my $hr = $_[0];
  my $h2 = {};
  my $muts = [keys %{$hr}];
  my $sum = 0;
  foreach (values %{$hr}) {
    $sum += $_;
  }
  if ($sum <= 0) {
    die "Cannot randomly mutate with bad probability distribution";
  }
  else {
    my $cum;
    @{$h2}{ @{$muts} } = map {$cum +=$_; $cum / $sum} @{$hr}{ @{$muts} };
    return ($h2, $muts);
  }
}

##
# inserts one element into the sequence
# 0: number to perform ( or 1)
# 1: position to mutate (undef for random)

sub mutate_insert {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $pos = defined($_[1]) ? $_[1] : int rand $glen;
    next if $pos > $glen; # further than 1 place after gene
    my $token = $self->generate_token;
    splice @{$self->[0]}, $pos, 0, $token;
    $rt++;
  }
  return $rt;
}

##
# removes element(s) from sequence
# 0: number of times to perform
# 1: position to affect (undef for rand)
# 2: length to affect, undef => 1, 0 => random length

sub mutate_remove {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $length = !defined($_[2]) ? 1 : ($_[2] || int rand $glen);
    return $rt if ($glen - $length) <= 0;
    my $pos = defined($_[1]) ? $_[1] : int rand $glen;
    next if $pos >= $glen; # outside of gene
    splice @{$self->[0]}, $pos, $length;
    $rt++;
  }
  return $rt;
}

##
# copies an element or run of elements into a random place in the gene
# 0: number to perform (or 1)
# 1: posn to copy from (undef for rand)
# 2: posn to splice in (undef for rand)
# 3: length            (undef for 1, 0 for random)

sub mutate_duplicate {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $length = !defined($_[3]) ? 1 : ($_[3] || int rand $glen);
    my $pos1 = defined($_[1]) ? $_[1] : int rand $glen;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $glen;
    next if ($pos1 + $length) > $glen;
    next if $pos2 > $glen;
    splice @{$self->[0]}, $pos2, 0, @{$self->[0]}[$pos1..($pos1+$length-1)];
    $rt++;
  }
  return $rt;
}

##
# Duplicates a sequence and writes it on top of some other position
# 0: num to perform  (or 1)
# 1: pos to get from          (undef for rand)
# 2: pos to start replacement (undef for rand)
# 3: length to operate on     (undef => 1, 0 => rand)

sub mutate_overwrite {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $length = !defined($_[3]) ? 1 : ($_[3] || int rand $glen);
    my $pos1 = defined($_[1]) ? $_[1] : int rand $glen;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $glen;
    next if ( ($pos1 + $length) >= $glen
	      or $pos2 > $glen);
    splice (@{$self->[0]}, $pos2, $length,
	    @{$self->[0]}[$pos1..($pos1+$length-1)] );
    $rt++;
  }

  return $rt;
}

##
# Takes a run of tokens and reverses their order, is a noop with 1 item
# 0: number to perform
# 1: posn to start from (undef for rand)
# 2: length             (undef=>1, 0=>rand)

sub mutate_reverse {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  
  for (1..$num) {
    my $length = scalar @{$self->[0]};
    my $pos = defined($_[1]) ? $_[1] : int rand $length;
    my $len = !defined($_[2]) ? 1 : ($_[2] || int rand $length);

    next if ($pos >= $length
	    or $pos + $len > $length);

    splice (@{$self->[0]}, $pos, $len,
	    reverse( @{$self->[0]}[$pos..($pos+$len-1)] ));
    $rt++;
  }
  return $rt;
}

##
# Changes token into one of same type (ie. passes type to generate..)
# 0: number to perform
# 1: position to affect (undef for rand)

sub mutate_minor {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $pos = defined $_[1] ? $_[1] : int rand $glen;
    next if $pos >= $glen;  # pos lies outside of gene
    my $type = $self->[0][$pos];
    my $token = $self->generate_token($type);
    $self->[0][$pos] = $token;
    $rt++;
  }
  return $rt;
}

##
# Changes one token into some other token
# 0: number to perform
# 1: position to affect (undef for random)

sub mutate_major {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $pos = defined $_[1] ? $_[1] : int rand $glen;
    next if $pos >= $glen ; # outside of gene
    my $token = $self->generate_token();
    $self->[0][$pos] = $token;
    $rt++;
  }
  return $rt;
}

##
# swaps over two sequences within the gene
# any sort of oddness can occur if regions overlap
# 0: number to perform
# 1: start of first sequence   (undef for rand)
# 2: start of second sequence  (undef for rand)
# 3: length of first sequence  (undef for 1, 0 for rand)
# 4: length of second sequence (undef for 1, 0 for rand)

sub mutate_switch {
  my $self = shift;
  my $num = $_[0] || 1;
  my $rt = 0;
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $pos1 = defined $_[1] ? $_[1] : int rand $glen;
    my $pos2 = defined $_[2] ? $_[2] : int rand length $glen;
    next if $pos1 == $pos2;
    my $len1 = !defined($_[3]) ? 1 : ($_[3] || int rand $glen);
    my $len2 = !defined($_[4]) ? 1 : ($_[4] || int rand $glen);

    if ($pos1 > $pos2) { # ensure $pos1 comes first
      ($pos1, $pos2) = ($pos2, $pos1);
      ($len1, $len2) = ($len2, $len1);
    }

    if ( ($pos1 + $len1) > $pos2 # ensure no overlaps
	 or ($pos2 + $len2) > $glen
	 or $pos1 >= $glen ) {
      next;
    }

    my @chunk1 = splice(@{$self->[0]}, $pos1, $len1,
			splice(@{$self->[0]}, $pos2, $len2) );
    splice @{$self->[0]}, $pos2 + $len2 - $len1,0, @chunk1;
    $rt++;
  }
  return $rt;
}

##
# takes a sequence, removes it, then inserts it at another position
# odd things might occur if posn to replace to lies within area taken from
# 0: number to perform
# 1: posn to get from   (undef for rand)
# 2: posn to put        (undef for rand)
# 3: length of sequence (undef for 1, 0 for rand)

sub mutate_shuffle {
  my $self = shift;
  my $num = +$_[0] || 1;
  my $rt = 0;
  
  for (1..$num) {
    my $glen = scalar @{$self->[0]};
    my $pos1 = defined($_[1]) ? $_[1] : int rand $glen;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $glen;
    my $len = !defined($_[3]) ? 1 : ($_[3] || int rand $glen);

    next if ($pos1 +$len > $glen                      # outside gene
	     or $pos2 >= $glen                        # outside gene
	     or ($pos2 < ($pos1 + $len) and $pos2 > $pos1)); # overlap

    if ($pos1 < $pos2) {
      splice (@{$self->[0]}, $pos2-$len, 0, 
	      splice(@{$self->[0]}, $pos1, $len) );
    }
    else {
      splice(@{$self->[0]}, $pos2, 0,
	     splice(@{$self->[0]}, $pos1, $len) );
    }
    $rt++;
  }
  return $rt;
}

# These are intended to be overriden, simple versions are
# provided for the sake of testing.

# Generates things to make up genes
# can be called with a token type to produce, or with none.
# if called with a token type, it will also be passed the original
# token as the second argument.
# should return a two element list of the token type followed by the token itself.

sub generate_token {
  my $self = shift;
  my $token_type = $_[0];
  my $letter = ('a'..'z')[rand 25];
  unless ($token_type) {
    return $letter;
  }
  return $token_type;
}

## You might also want to have methods like the following,
# they will not be called by the 'sequence' methods.

# Default constructor
sub new {
  my $gene = [[]]; # leave space for other info
  return bless $gene, ref $_[0] || $_[0];
}

# remember that clone method may require deep copying depending on
# your specific needs

sub clone {
  my $self = shift;
  my $new = [];
  $new->[0] = [@{$self->[0]}];
  return bless $new, ref $self;
}

# You need some way to use the gene you've made and mutated, but
# this will let you have a look, if it starts being odd.

sub render_gene {
  my $self = shift;
  my $return =  "$self\n";
  $return .= (join ',', @{$self->[0]}). "\n";
  return $return;
}

# used for testing

sub _test_dump {
  my $self = shift;
  my $rt = (join('',@{$self->[0]}));
  return $rt;
}
1;

__END__;

=pod

=head1 NAME

 AI::Gene::Simple

=head1 SYNOPSIS

A base class for storing and mutating genetic sequences.

 package Somegene;
 use AI::Gene::Simple;
 our @ISA = qw (AI::Gene::Simple);

 sub generate_token {
   my $self = shift;
   my $prev = $_[0] ? $_[0] + (1-rand(1)) : rand(1)*10;
   return $prev;
 }

 sub calculate {
   my $self = shift;
   my $x = $_[0];
   my $rt=0;
   for (0..(scalar(@{$self->[0]}) -1)) {
     $rt += $self->[0][$_] * ($x ** $_);
   }
   return $rt;
 }

 sub seed {
   my $self = shift;
   $self->[0][$_] = rand(1) * 10 for (0..$_[0]);
   return $self;
 }

 # ... then elsewhere

 package main;

 my $gene = Somegene->new;
 $gene->seed(5);
 print $gene->calculate(2), "\n";
 $gene->mutate_minor;
 print $gene->calculate(2), "\n";
 $gene->mutate_major;
 print $gene->calculate(2), "\n";

=head1 DESCRIPTION

This is a class which provides generic methods for the
creation and mutation of genetic sequences.  Various mutations
are provided but the resulting mutations are not checked
for a correct syntax.  These classes are suitable for genes
where it is only necessary to know what lies at a given
position in a gene.  If you need to ensure a gene maintains
a sensible grammar, then you should use the AI::Gene::Sequence
class instead, the interfaces are the same though so you
will only need to modify your overiding classes if you need to
switch from one to the other.

A suitable use for this module might be a series of coefficients
in a polynomial expansion or notes to be played in a musical
score.

This module should not be confused with the I<bioperl> modules
which are used to analyse DNA sequences.

It is intended that the methods in this code are inherited
by other modules.

=head2 Anatomy of a gene

A gene is a linear sequence of tokens which tell some unknown
system how to behave.  These methods all expect that a gene
is of the form:

 [ [ 'token0', 'token1', ...  ], .. other elements ignored ]

=head2 Using the module

To use the genetic sequences, you must write your own
implementations of the following methods along with some
way of turning your encoded sequence into something useful.

=over 4

=item generate_token

=back

You may also want to override the following methods:

=over 4

=item new

=item clone

=item render_gene

=back

The calling conventions for these methods are outlined below.

=head2 Mutation methods

Mutation methods are all named C<mutate_*>.  In general, the
first argument will be the number of mutations required, followed
by the positions in the genes which should be affected, followed
by the lengths of sequences within the gene which should be affected.
If positions are not defined, then random ones are chosen.  If
lengths are not defined, a length of 1 is assumed (ie. working on
single tokens only), if a length of 0 is requested, then a random
length is chosen.

If a mutation is attempted which could corrupt your gene (copying
from a region beyond the end of the gene for instance) then it
will be silently skipped.  Mutation methods all return the number
of mutations carried out (not the number of tokens affected).

=over 4

=item C<mutate([num, ref to hash of probs & methods])>

This will call at random one of the other mutation methods.
It will repeat itself I<num> times.  If passed a reference
to a hash as its second argument, it will use that to
decide which mutation to attempt.

This hash should contain keys which fit $1 in C<mutate_(.*)>
and values indicating the weight to be given to that method.
The module will normalise this nicely, so you do not have to.
This lets you define your own mutation methods in addition to
overriding any you do not like in the module.

=item C<mutate_insert([num, pos])>

Inserts a single token into the string at position I<pos>.
The token will be randomly generated by the calling object's 
C<generate_token> method.

=item C<mutate_overwrite([num, pos1, pos2, len])>

Copies a section of the gene (starting at I<pos1>, length I<len>)
and writes it back into the gene, overwriting current elements,
starting at I<pos2>.

=item C<mutate_reverse([num, pos, len])>

Takes a sequence within the gene and reverses the ordering of the
elements within that sequence.  Starts at position I<pos> for
length I<len>.

=item C<mutate_shuffle([num, pos1, pos2, len])>

This takes a sequence (starting at I<pos1> length I<len>)
 from within a gene and moves
it to another position (starting at I<pos2>).  Odd things might occur if the
position to move the sequence into lies within the
section to be moved, but the module will try its hardest
to cause a mutation.

=item C<mutate_duplicate([num, pos1, pos2, length])>

This copies a portion of the gene starting at I<pos1> of length
I<length> and then splices it into the gene before I<pos2>.

=item C<mutate_remove([num, pos, length]))>

Deletes I<length> tokens from the gene, starting at I<pos>. Repeats
I<num> times.

=item C<mutate_minor([num, pos])>

This will mutate a single token at position I<pos> in the gene 
into one of the same type (as decided by the object's C<generate_token>
method).

=item C<mutate_major([num, pos])>

This changes a single token into a token of any token type.
Token at postition I<pos>.  The token is produced by the object's
C<generate_token> method.

=item C<mutate_switch([num, pos1, pos2, len1, len2])>

This takes two sequences within the gene and swaps them
into each other's position.  The first starts at I<pos1>
with length I<len1> and the second at I<pos2> with length
I<len2>.  If the two sequences overlap, then no mutation will
be attempted.

=back

The following methods are also provided, but you will probably
want to overide them for your own genetic sequences.

=over 4

=item C<generate_token([current token])>

This is used by the mutation methods when changing tokens or 
creating new ones.  It is expected to return a single token.
If a minor mutation is being attempted, then the method will
also be passed the current token.

The provided version of this method returns a random character
from 'a'..'z' as both the token type and token.

=item C<clone()>

This returns a copy of the gene as a new object.  If you are using
nested genes, or other references as your tokens, then you may need
to produce your own version which will deep copy your structure.

=item C<new>

This returns an empty gene, into which you can put things.  If you
want to initialise your gene, or anything useful like that, then
you will need another one of these.

=item C<render_gene>

This is useful for debugging, returns a serialised summary of the
gene.

=back

=head1 AUTHOR

This module was written by Alex Gough (F<alex@rcon.org>).

=head1 SEE ALSO

If you are encoding something which must maintain a correct
syntax (executable code, regular expressions, formal poems)
then you might be better off using AI::Gene::Sequence .

=head1 COPYRIGHT

Copyright (c) 2000 Alex Gough <F<alex@rcon.org>>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS

Some methods will do odd things if you pass them weird values,
so try not to do that.  So long as you stick to passing
positive integers or C<undef> to the methods then they should
recover gracefully.

While it is easy and fun to write genetic and evolutionary
algorithms in perl, for most purposes, it will be much slower
than if they were implemented in another more suitable language.
There are some problems which do lend themselves to an approach
in perl and these are the ones where the time between mutations
will be large, for instance, when composing music where the
selection process is driven by human whims.

=cut
