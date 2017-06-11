package CracTools::BitVector;

{
  $CracTools::BitVector::DIST = 'CracTools';
}
# ABSTRACT: Full Perl BitVector implementation
$CracTools::BitVector::VERSION = '1.251';
use Exporter;
our @ISA = qw(Exporter);

use strict;
use POSIX qw(floor ceil);
use constant BITNESS => 64;


sub new {
    my ($class, $length)  = @_;
    my $this = {};
    bless($this, $class);
    
    $this->{n} = $length;
    $this->{set} = 0;
    $this->{first_bit_set} = $length + 1;

    my $max = int($length / BITNESS);
    if ($length % BITNESS > 0) {
        $max++;
    }
    $this->{maxCases} = $max;

    for (my $i=0; $i < $max; $i++) {
        push @{$this->{bits}}, 0;
    }

    return $this;
}


sub firstBitSet {
  my $self = shift;
  return $self->{first_bit_set};
}


sub copy {
    my ($this) = @_;
    my $new = {};
    $new->{n} = $this->{n};
    $new->{set} = $this->{set};
    $new->{maxCases} = $this->{maxCases};
    @{$new->{bits}} = @{$this->{bits}};
    if (defined($this->{block})) {
	@{$new->{block}} = @{$this->{block}};
    }
    bless $new, ref($this);
    return $new;
}


sub set {
    my ($this, $i) = @_;
    $this->{first_bit_set} = $i if $i < $this->{first_bit_set};
    if (! $this->get($i)) {
        $this->{set}++;
        $this->{bits}[int($i / BITNESS)] |= (1 << ($i % BITNESS));
        $this->{block}[int($i / BITNESS)]++;
    }
}


sub unset {
    my ($this, $i) = @_;
    if ($this->get($i)) {
        $this->{set}--;
        $this->{bits}[int($i / BITNESS)] &= (~(1 << ($i % BITNESS)));
        $this->{block}[int($i / BITNESS)]--;
    }
}


sub get {
    my ($this, $i) = @_;
    if (! defined($this) || ! defined($this->{bits})
	|| ! defined($this->{bits}[int($i / BITNESS)])) {
	die("Bad position i=$i case -> ".int($i/BITNESS)."\n");
    }
    return ($this->{bits}[int($i / BITNESS)] & (1 << ($i % BITNESS)))? 1 : 0;
}


sub prev {
    my ($this, $i, $max) = @_;
    my $start = $i;
    
    # Is there a 1 in the current block?
    if ($this->{bits}[int($i / BITNESS)] 
        & ((~0) >> (BITNESS-1) - ($i % BITNESS))) {
        while ($this->get($i) == 0) {
            $i--;
        }
	if (defined($max) && $i < $start - $max) {
	    return -1;
	}
        return $i;
    } else {
        # Look for a block with a 1-bit set.

        my $block = int($i / BITNESS) - 1;
        while ($block >= 0
               && (! defined($this->{block}[$block])
                   || ! $this->{block}[$block])
	       && (! defined($max) 
		   || $i - ($block+1) * (BITNESS) + 1  <= $max)) {
            $block--;
        }
        if ($block < 0 || (defined($max) 
			   && $i - ($block+1) * (BITNESS) + 1 > $max)) {
            return -1;
        }
        $i = ($block + 1) * (BITNESS) - 1;
        while ($this->get($i) == 0) {
            $i--;
        }
	if (defined($max) && $i < $start - $max) {
	    return -1;
	}	
        return $i;
    }
}


sub succ {
    my ($this, $i, $max) = @_;
    my $start = $i;

    # Is there a 1 in the current block?
    if ($this->{bits}[int($i / BITNESS)] 
        & ((~0) << ($i % BITNESS))) {
        while ($i < $this->{n} && $this->get($i) == 0) {
            $i++;
        }
	if ($i == $this->{n} || (defined($max) && $i > $max + $start)) {
	    return -1;
	}
        return $i;
    } else {
        # Look for a block with a 1-bit set.

        my $block = int($i / BITNESS) + 1;
        while ($block < $this->{maxCases} 
               && (! defined($this->{block}[$block])
                   || ! $this->{block}[$block])
	       && (! defined($max) 
		   || $block * (BITNESS) - $i <= $max)) {
            $block++;
        }
        if ($block >= $this->{maxCases} 
	    || (defined($max) 
		&& $block * (BITNESS) - $i > $max)) {
            return -1;
        }
        $i = $block * (BITNESS);
        while ($i < $this->{n} && $this->get($i) == 0) {
            $i++;
        }
	if ($i == $this->{n} || defined($max) && $i > $max + $start) {
	    return -1;
	}	
        return $i;
    }
}


sub rank {
  my ($self, $i) = @_;
  my $rank = $self->get($i)? 1 : 0;
  my $found_bit = 1;
  while($found_bit) {
    $i = $self->prev($i-1);
    if ($i != -1) {
      $rank++;
    } else {
      $found_bit = 0;
    }
  }
  return $rank;
}


sub select {
  my ($self, $nb) = @_;
  my $i = $self->firstBitSet;
  while ($nb > 1 && $i != -1) {
    $i = $self->succ($i+1);
    $nb--;
  }
  return $i;
}


sub length {
    my ($this) = @_;
    return $this->{n};
}


sub nbSet {
    my ($this) = @_;
    return $this->{set};
}

# Retro-compatibility alias
sub nb_set { my $self = shift; $self->nbSet(@_);}


sub toString {
    my $this = shift;
    my $sep = shift;
    my $output = '';

    $sep = ' ' unless defined $sep;
    
    for (my $i=0; $i < $this->{n}; $i++) {
        if ($i % BITNESS == 0 && $i > 0) {
            $output .= $sep;
        }
        $output .= $this->get($i);
    }
    return $output
}

# Retro-compatibility alias
sub to_string { my $self = shift; $self->toString(@_);}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CracTools::BitVector - Full Perl BitVector implementation

=head1 VERSION

version 1.251

=head1 SYNOPSIS

  my $bv = CracTools::BitVector->new(1000);

  # Setting bits
  my $bv->set(1);
  my $bv->set(12);

  # Query bits
  if($bv->get(12)) {
    print STDERR "I knew this one was set!!\n";
  }

=head1 DESCRIPTION

This module based implements a bitvector datastructure where individual bits
can be set, unset and check. It also implement "rank", "select" functions, but
it is poorly optimised. 

=head1 SEE ALSO

You may want to check L<CracTools::GenomeMask> that uses this BitVector
implementation to define a complete bitset over a genome.

=head1 METHODS

=head2 new

  Arg [1] : Integer - lenght of the bitvector

  Description : Return a new CracTools::BitVector object
  ReturnType  : CracTools::BitVector

=head2 firstBitSet

  Description : Return the position of the first bit set
  ReturnType  : Integer

=head2 copy

  Description : Return a copy of the curent bitvector
  ReturnType  : CracTools::BitVector

=head2 set

  Arg [1] : Integer - position in the bitvector

  Description : Set 1-bit at position i
  ReturnType  : undef

=head2 unset

  Arg [1] : Integer - position in the bitvector

  Description : Unset 1-bit at position i
  ReturnType  : undef

=head2 get

  Arg [1] : Integer - position in the bitvector

  Description : Return the value of the bit at position i
  ReturnType  : Boolean

=head2 prev

  Arg [1] : Integer - position in the bitvector
  Arg [2] : (Optional) Integer - max shift from i

  Description : Return the previous position that has a bit set.
                ie. a position j <= i such that get(j) == 1
                && get(k) == 0 , j < k <= i
                If max is set, j >= i - max
                -1 if no such position exists
  ReturnType  : Integer

=head2 succ

  Arg [1] : Integer - position in the bitvector
  Arg [2] : (Optional) Integer - max shift from i

  Description : Return the next position that has a bit set.
                ie. a position j >= i such that get(j) == 1
                && get(k) == 0 , j > k >= i
                If max is set, j <= i + max
                -1 if no such position exists
  ReturnType  : Integer

=head2 rank

  Arg [1] : Integer - position in the bitvector

  Description : Return the number of bit set up to
                position i
  ReturnType  : Integer

=head2 select

  Arg [1] : Integer - position in the bitvector

  Description : Return the next position that has a bit set.
                ie. a position j >= i such that get(j) == 1
                && get(k) == 0 , j > k >= i
                If max is set, j <= i + max
                -1 if no such position exists
  ReturnType  : Integer

=head2 length

  Description : Return the length of the bitvector
  ReturnType  : Integer

=head2 nbSet

  Description : Return the number of bit set
  ReturnType  : Integer

=head3 alias: nb_set

=head2 toString

  Arg [1] : (Optional) String - Separator character (space by default)
  
  Description : Return a string representation of the bitvector
                where each bit is separated with a space character.
  ReturnType  : String

=head3 alias: to_string

=head1 AUTHORS

=over 4

=item *

Nicolas PHILIPPE <nphilippe.research@gmail.com>

=item *

Jérôme AUDOUX <jaudoux@cpan.org>

=item *

Sacha BEAUMEUNIER <sacha.beaumeunier@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by IRMB/INSERM (Institute for Regenerative Medecine and Biotherapy / Institut National de la Santé et de la Recherche Médicale) and AxLR/SATT (Lanquedoc Roussilon / Societe d'Acceleration de Transfert de Technologie).

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
