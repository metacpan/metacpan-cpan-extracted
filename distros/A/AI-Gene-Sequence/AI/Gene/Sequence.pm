package AI::Gene::Sequence;
require 5.6.0;
use strict;
use warnings;

BEGIN {
  use Exporter   ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION     = 0.22;
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
    my $length = length $self->[0];
    my $pos = defined($_[1]) ? $_[1] : int rand $length;
    next if $pos > $length; # further than 1 place after gene
    my @token = $self->generate_token;
    my $new = $self->[0];
    substr($new, $pos, 0) = $token[0];
    next unless $self->valid_gene($new, $pos);
    $self->[0] = $new;
    splice @{$self->[1]}, $pos, 0, $token[1];
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
    my $length = length $self->[0];
    my $len = !defined($_[2]) ? 1 : ($_[2] || int rand $length);
    next if ($length - $len) <= 0;
    my $pos = defined($_[1]) ? $_[1] : int rand $length;
    next if $pos >= $length; # outside of gene
    my $new = $self->[0];
    substr($new, $pos, $len) = '';
    next unless $self->valid_gene($new, $pos);
    $self->[0] = $new;
    splice @{$self->[1]}, $pos, $len;
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
    my $length = length $self->[0];
    my $len = !defined($_[3]) ? 1 : ($_[3] || int rand $length);
    my $pos1 = defined($_[1]) ? $_[1] : int rand $length;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $length;
    my $new = $self->[0];
    next if ($pos1 + $len) > $length;
    next if $pos2 > $length;
    my $seq = substr($new, $pos1, $len);
    substr($new, $pos2,0) = $seq;
    next unless $self->valid_gene($new);
    $self->[0] = $new;
    splice @{$self->[1]}, $pos2, 0, @{$self->[1]}[$pos1..($pos1+$len-1)];
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
    my $new = $self->[0];
    my $length = length $self->[0];
    my $len = !defined($_[3]) ? 1 : ($_[3] || int rand $length);
    my $pos1 = defined($_[1]) ? $_[1] : int rand $length;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $length;
    next if ( ($pos1 + $len) >= $length
	      or $pos2 > $length);
    substr($new, $pos2, $len) = substr($new, $pos1, $len);
    next unless $self->valid_gene($new);
    $self->[0] = $new;
    splice (@{$self->[1]}, $pos2, $len,
	    @{$self->[1]}[$pos1..($pos1+$len-1)] );
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
    my $length = length $self->[0];
    my $new = $self->[0];
    my $pos = defined($_[1]) ? $_[1] : int rand $length;
    my $len = !defined($_[2]) ? 1 : ($_[2] || int rand $length);

    next if ($pos >= $length
	    or $pos + $len > $length);

    my $chunk = reverse split('', substr($new, $pos, $len));
    substr($new, $pos, $len) = join('', $chunk);
    next unless $self->valid_gene($new);
    $self->[0] = $new;
    splice (@{$self->[1]}, $pos, $len,
	    reverse( @{$self->[1]}[$pos..($pos+$len-1)] ));
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
    my $pos = defined $_[1] ? $_[1] : int rand length $self->[0];
    next if $pos >= length($self->[0]); # pos lies outside of gene
    my $type = substr($self->[0], $pos, 1);
    my @token = $self->generate_token($type, $self->[1][$pos]);
    # still need to check for niceness, just in case
    if ($token[0] eq $type) {
      $self->[1][$pos] = $token[1];
    }
    else {
      my $new = $self->[0];
      substr($new, $pos, 1) = $token[0];
      next unless $self->valid_gene($new, $pos);
      $self->[0] = $new;
      $self->[1][$pos] = $token[1];
    }
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
    my $pos = defined $_[1] ? $_[1] : int rand length $self->[0];
    next if $pos >= length($self->[0]); # outside of gene
    my @token = $self->generate_token();
    my $new = $self->[0];
    substr($new, $pos, 1) = $token[0];
    next unless $self->valid_gene($new, $pos);
    $self->[0] = $new;
    $self->[1][$pos] = $token[1];
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
    my $length = length $self->[0];
    my $pos1 = defined $_[1] ? $_[1] : int rand $length;
    my $pos2 = defined $_[2] ? $_[2] : int rand $length;
    my $len1 = !defined($_[3]) ? 1 : ($_[3] || int rand $length);
    my $len2 = !defined($_[4]) ? 1 : ($_[4] || int rand $length);

    my $new = $self->[0];
    next if $pos1 == $pos2;
    if ($pos1 > $pos2) { # ensure $pos1 comes first
      ($pos1, $pos2) = ($pos2, $pos1);
      ($len1, $len2) = ($len2, $len1);
    }
    if ( ($pos1 + $len1) > $pos2 # ensure no overlaps
	 or ($pos2 + $len2) > $length
	 or $pos1 >= $length ) {
      next;
    }
    my $chunk1 = substr($new, $pos1, $len1, substr($new, $pos2, $len2,''));
    substr($new,$pos2 -$len1 + $len2,0) = $chunk1;
    next unless $self->valid_gene($new);
    $self->[0]= $new;
    my @chunk1 = splice(@{$self->[1]}, $pos1, $len1,
			splice(@{$self->[1]}, $pos2, $len2) );
    splice @{$self->[1]}, $pos2 + $len2 - $len1,0, @chunk1;
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
    my $length = length $self->[0];
    my $pos1 = defined($_[1]) ? $_[1] : int rand $length;
    my $pos2 = defined($_[2]) ? $_[2] : int rand $length;
    my $len = !defined($_[3]) ? 1 : ($_[3] || int rand $length);

    my $new = $self->[0];
    if ($pos1 +$len > $length   # outside gene
	or $pos2 >= $length      # outside gene
	or ($pos2 < ($pos1 + $len) and $pos2 > $pos1)) { # overlap
      next;
    }
    if ($pos1 < $pos2) {
      substr($new, $pos2-$len,0) = substr($new, $pos1, $len, '');
    }
    else {
      substr($new, $pos2, 0) = substr($new, $pos1, $len, '');
    }
    next unless $self->valid_gene($new);
    $self->[0] = $new;
    if ($pos1 < $pos2) {
      splice (@{$self->[1]}, $pos2-$len, 0, 
	      splice(@{$self->[1]}, $pos1, $len) );
    }
    else {
      splice(@{$self->[1]}, $pos2, 0,
	     splice(@{$self->[1]}, $pos1, $len) );
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
    return ($letter) x2;
  }
  return ($token_type) x2;
}

# takes sting of token types to be checked for validity.
# If a mutation affects only one place, then the position of the
# mutation can be passed as a second argument.
sub valid_gene {1}

## You might also want to have methods like the following,
# they will not be called by the 'sequence' methods.

# Default constructor
sub new {
  my $gene = ['',[]];
  return bless $gene, ref $_[0] || $_[0];
}

# remember that clone method may require deep copying depending on
# your specific needs

sub clone {
  my $self = shift;
  my $new = [$self->[0]];
  $new->[1] = [@{$self->[1]}];
  return bless $new, ref $self;
}

# You need some way to use the gene you've made and mutated, but
# this will let you have a look, if it starts being odd.

sub render_gene {
  my $self = shift;
  my $return =  "$self\n";
  $return .= $self->[0] . "\n";
  $return .= (join ',', @{$self->[1]}). "\n";
  return $return;
}

# used for testing

sub _test_dump {
  my $self = shift;
  my @rt = ($self->[0], join('',@{$self->[1]}));
  return @rt;
}
1;

__END__;

=pod

=head1 NAME

 AI::Gene::Sequence

=head1 SYNOPSIS

A base class for storing and mutating genetic sequences.

 package Somegene;
 use AI::Gene::Sequence;
 our @ISA = qw(AI::Gene::Sequence);

 my %things = ( a => [qw(a1 a2 a3 a4 a5)],
	       b => [qw(b1 b2 b3 b4 b5)],);

 sub generate_token {
  my $self = shift;
  my ($type, $prev) = @_;
  if ($type) {
    $prev = ${ $things{$type} }[rand @{ $things{$type} }];
  } 
  else {
    $type = ('a','b')[rand 2];
    $prev = ${$things{$type}}[rand @{$things{$type}}];
  }
  return ($type, $prev); 
 }

 sub valid_gene {
   my $self = shift;
   return 0 if $_[0] =~ /(.)\1/;
   return 1;
 }

 sub seed {
   my $self = shift;
   $self->[0] = 'ababab';
   @{$self->[1]} = qw(A1 B1 A2 B2 A3 B3);
 }

 sub render {
   my $self = shift;
   return join(' ', @{$self->[1]});
 } 

 # elsewhere
 package main;

 my $gene = Somegene->new;
 $gene->seed;
 print $gene->render, "\n";
 $gene->mutate(5);
 print $gene->render, "\n";
 $gene->mutate(5);
 print $gene->render, "\n";

=head1 DESCRIPTION

This is a class which provides generic methods for the
creation and mutation of genetic sequences.  Various mutations
are provided as is a way to ensure that genes created by
mutations remain useful (for instance, if a gene gives rise to
code, it can be tested for correct syntax).

If you do not need to keep check on what sort of thing is
currently occupying a slot in the gene, you would be better
off using the AI::Gene::Simple class instead as this
will be somewhat faster.  The interface to the mutations is
the same though, so if you need to change in future, then
it will not be too painful.

This module should not be confused with the I<bioperl> modules
which are used to analyse DNA sequences.

It is intended that the methods in this code are inherited
by other modules.

=head2 Anatomy of a gene

A gene is a sequence of tokens, each a member of some group
of simillar tokens (they can of course all be members of a
single group).  This module encodes genes as a string
representing token types, and an array containing the
tokens themselves, this allows for arbitary data to be
stored as a token in a gene.

For instance, a regular expression could be encoded as:

 $self = ['ccartm',['a', 'b', '|', '[A-Z]', '\W', '*?'] ]

Using a string to indicate the sort of thing held at the
corresponding part of the gene allows for a simple test
of the validity of a proposed gene by using a regular
expression.

=head2 Using the module

To use the genetic sequences, you must write your own
implementations of the following methods:

=over 4

=item generate_token

=item valid_gene

=back

You may also want to override the following methods:

=over 4

=item new

=item clone

=item render_gene

=back

=head2 Mutation methods

Mutation methods are all named C<mutate_*>.  In general, the
first argument will be the number of mutations required, followed
by the positions in the genes which should be affected, followed
by the lengths of sequences within the gene which should be affected.
If positions are not defined, then random ones are chosen.  If
lengths are not defined, a length of 1 is assumed (ie. working on
single tokens only), if a length of 0 is requested, then a random
length is chosen.

Also, if a mutation is suggested but would result in an invalid
sequence, then the mutation will not be carried out.
If a mutation is attempted which could corrupt your gene (copying
from a region beyond the end of the gene for instance) then it
will be silently skipped.  Mutation methods all return the number
of mutations carried out (not the number of tokens affected).

These methods all expect to be passed positive integers, undef or zero,
other values could (and likely will) do something unpredictable.

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

=item C<generate_token([token type, current token])>

This is used by the mutation methods when changing tokens or 
creating new ones.  It is expected to return a list consisting
of a single character to indicate the token type being produced
and the token itself.  Where it makes sense to do so the token
which is about to be modifed is passed along with the token type.
If the calling methods require a token of any type, then no
arguments will be passed to this method.

The provided version of this method returns a random character
from 'a'..'z' as both the token type and token.

=item C<valid_gene(string [, posn])>

This is used to determine if a proposed mutation is allowed.  This
method is passed a string of the whole gene's token types, it will
also be passed a position in the gene where this makes sense (for
instance, if only one token is to change).  It is expected to
return a true value if a change is acceptable and a false one
if it is not.

The provided version of this method always returns true.

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

For an illustration of the use of this module, see Regexgene.pm,
Musicgene.pm, spamscan.pl and music.pl from the gziped distribution.

=head1 COPYRIGHT

Copyright (c) 2000 Alex Gough <F<alex@rcon.org>>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 BUGS

This is very slow if you do not need to check that your mutations
create valid genes, but fast if you do, thems the breaks.  There
is a AI::Gene::Simple class instead if this bothers you.

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
