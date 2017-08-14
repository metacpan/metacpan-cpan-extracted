#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Buddy system memory allocation in 100% Pure Perl
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2016
#-------------------------------------------------------------------------------

package Data::Layout::BuddySystem;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Data::Table::Text qw(:all);
use Carp;
our $VERSION = 20170808;

if (0)                                                                          # Save to S3:- this will not work, unless you're me, or you happen, to know the key
 {my $z = 'DataLayoutBuddySystem.zip';
  print for qx(zip $z $0 && aws s3 cp $z s3://AppaAppsSourceVersions/$z && rm $z);
 }

#1 Methods
sub new                                                                         # Create a new Buddy system
 {return bless {};
 }

sub freeChains{$_[0]{freeChains} //= []}                                        ## Addresses of free blocks organised by power of two size
sub usedSize  {$_[0]{usedSize}   //= {}}                                        ## {address} = size of allocation at that address
sub wentTo    {$_[0]{wentTo}     //= {}}                                        ## {address1} = address2 - where address 1 was relocated to by copy
sub cameFrom  {$_[0]{cameFrom}   //= {}}                                        ## {address1} = address2 - where address 1 came from before being copied
sub allFrees  {$_[0]{allFrees}   //= []}                                        ## [chain] = count of allocations minus frees on this chain
sub nameAlloc {$_[0]{nameAlloc}  //= {}}                                        ## {name}  = name of allocation if a name has been supplied
sub allocName {$_[0]{allocName}  //= {}}                                        ## {address}  = name of allocation at this address if a name has been supplied
sub size      {scalar @{$_[0]->freeChains}}                                     ## Number of free chains in use

sub allocField($$$)                                                             # Allocate a block in the buddy system, give it a name that is invariant even after this buddy system has been copied to a new buddy system to compact its storage, and return the address of its location in the buddy system
 {my ($buddySystem, $name, $size) = @_;                                         # Buddy system, name of block, integer log2(size of allocation)
  $name              or                                                         # Check name has been supplied
    confess "Name required";
  $name =~ /\A\w+\Z/ or                                                         # Check that only word characters are being used to construct the field name
    confess "Name must consist of word characters, not: $name";
  defined($buddySystem->nameAlloc->{$name}) and                                 # Check proposed name of allocation is not already in use
    confess "Name already defined: $name";
  my $alloc = $buddySystem->alloc($size);                                       # Perform allocation
  $buddySystem->nameAlloc->{$name}  = $alloc;                                   # Name to address of allocation
  $buddySystem->allocName->{$alloc} = $name;                                    # Address to name of allocation
  $alloc                                                                        # Return address of allocation
 } # allocField

sub alloc($$)                                                                   # Allocate a block and return its bit address
 {my ($buddySystem, $size) = @_;                                                # Buddy system, integer log2(size of allocation)
  $size >= 0          or confess "Size must be positive, not $size";
  $size == int($size) or confess "Size must be integral, not $size";
  $buddySystem->allFrees->[$size]++;                                            # Count allocations and frees on this chain - alloc always works

  if ($buddySystem->size == 0)                                                  # Initial allocation
   {my $alloc = 0;                                                              # Allocation address
    $buddySystem->freeChains->[$size] = {};                                     # Create chain for initial allocation
    $buddySystem->usedSize->{$alloc} = $size;                                   # Save size of allocation at offset
    return $alloc;                                                              # Return allocation
   }

  for my $F($size..$buddySystem->size-1)                                        # Look for space on the free chains
   {if (my $f = $buddySystem->freeChains->[$F])                                 # Each chain
     {if (keys %$f)                                                             # Free chain with space
       {for my $alloc(sort {$a <=> $b} keys %$f)                                # Allocation address
         {delete $f->{$alloc};
          $buddySystem->usedSize->{$alloc} = $size;                             # Save size of allocation at offset
          $buddySystem->freeChains->[$_]{$alloc + (1<<$_)}++ for $size..$F-1;   # Return excess space to lower chains
          return $alloc;                                                        # Return allocation
         }
       }
     }
   }
                                                                                # No space on any free chain - start a new chain to hold the allocation
  my $s = $buddySystem->size;                                                   # Size less than current allocation
  if ($size < $s-1)
   {my $F = $buddySystem->freeChains->[$s] = {};                                # Create new chain
    my $alloc = (1<<($s-1));                                                    # Allocation address
    $buddySystem->usedSize->{$alloc} = $size;                                   # Allocation size
    $buddySystem->freeChains->[$_]{$alloc + (1<<$_)}++ for $size..$s-2;         # Spread excess space across lower chains
    return $alloc
   }
  else                                                                          # Size greater than or equal to current allocation
   {my $F = $buddySystem->freeChains->[$size+1] = {};                           # Create new chain
    my $alloc = (1<<$size);                                                     # Allocation address
    $buddySystem->usedSize->{$alloc} = $size;                                   # Allocation size
    for($s..$size)                                                              # Spread excess space across lower chains
     {my $i = $size-($_+1-$s);
      $buddySystem->freeChains->[$i]{(1<<$i)}++;
     }
    return $alloc                                                               # Return allocation
   }
 } # alloc

sub locateAddress($$)                                                           # Find the current location of a block by its original address after it has been copied to a new buddy system
 {my ($buddySystem, $alloc) = @_;                                               # Buddy system, address at which the block was originally located
  $buddySystem->wentTo->{$alloc} // $alloc                                      # The relocated address if there is one, else the current address
 } # locateAddress

sub locateName($$)                                                              # Find the current location of a named block after it has been copied to a new buddy system
 {my ($buddySystem, $name) = @_;                                                # Buddy system, name of the block
  my $alloc = $buddySystem->nameAlloc->{$name};                                 # Address of named block
  defined($alloc) or confess "No such named block: $name";                      # Complain of no such block exists
  $buddySystem->locateAddress($alloc)                                           # The relocated address if there is one, else the current address
 } # locateName

sub sizeAddress($$)                                                             # Size of allocation at an address
 {my ($buddySystem, $address) = @_;                                             # Buddy system, address of allocation whiose size we want
  $buddySystem->{usedSize}{$address}                                            # Size of allocation at specified address
 } # sizeAddress

sub sizeName($$)                                                                # Size of a named allocation
 {my ($buddySystem, $name) = @_;                                                # Buddy system, address of allocation whiose size we want
  my $address = $buddySystem->locateName($name);                                # Address of allocation
  defined($address) or confess "No allocation with name $name";                 # Check allocation by this name exists
  $buddySystem->sizeAddress($address)                                           # Size of named allocation
 } # sizeName

sub freeName($$)                                                                # Free an allocated block via its name
 {my ($buddySystem, $name) = @_;                                                # Buddy system, name used to allocate block
  my $alloc = $buddySystem->locateName($name);                                  # Current address of named block
  delete $buddySystem->nameAlloc->{$name};                                      # Disassociate name from block
  $buddySystem->free($alloc);                                                   # Free block by address
 } # freeName

sub free($$)                                                                    # Free an allocation via its original allocation address
 {my ($buddySystem, $alloc) = @_;                                               # Buddy system, original allocation address
  my $s = delete $buddySystem->usedSize->{$alloc};                              # Size of allocation at this alloc
  return 0 unless defined($s);                                                  # No allocation present and so no free is possible
  $buddySystem->allFrees->[$s]--;                                               # Count allocations and frees on this chain - free always works beyond this point

  delete $buddySystem->usedSize->{$alloc};                                      # Remove information appertaining to this block
  delete $buddySystem->wentTo->{$alloc};
  delete $buddySystem->cameFrom->{$alloc};

  my $S = $buddySystem->size-1;                                                 # Freeing will not make the system larger
  for my $c($s..$S)                                                             # Merge buddies
   {my $f = $buddySystem->freeChains->[$c];                                     # Free chain involved
    my $C = (1<<($c+1));                                                        # Modulus to get upper or lower buddy of a pair
    my $u = $alloc % $C;                                                        # True if this the upper block of a buddy pair
    my $b = $alloc + ($u ? -$C : +$C) / 2;                                      # Locate possible buddy
    if (delete $buddySystem->freeChains->[$c]{$b})                              # Remove buddy if it exists
     {$alloc = $u ? $b : $alloc;                                                # New block to place on next free chain
     }
    elsif ($c < $S)
     {$buddySystem->freeChains->[$c]{$alloc}++;                                 # Place this unpaired block on free chain
      return 1;                                                                 # Finished successfully - no block merges
     }
    else                                                                        # Remove excess free chains
     {my $c = $buddySystem->freeChains;
      my $a = $buddySystem->allFrees;
      for(1..@$c)                                                               # Remove a chain if it has nothing allocated
       {my $i = @$c-$_;
        last if $a->[$i];
        pop @$a if $i < @$a;
        pop @$c;
       }
      return 2;                                                                 # Finished successfully - one or more blocks were merged
     }
   }
  confess "This code should be unreachable"                                     # Unreachable
 } # free

#2 Statistics                                                                   # These methods provide statistics on memory usage in the buddy system

sub usedSpace($)                                                                # Total allocated space in this buddy system
 {my ($buddySystem) = @_;                                                       # Buddy system
  my $n = 0;
  my $u = $buddySystem->usedSize;
  $n += (1<<$u->{$_}) for keys %$u;
  $n
 } # usedSpace

sub freeSpace($)                                                                # Total free space that can still be allocated in this buddy system without changing its size
 {my ($buddySystem) = @_;                                                       # Buddy system
  my $n = 0;
  for(0..$buddySystem->size-1)
   {my $f = $buddySystem->freeChains->[$_];
    next unless $f;
    $n += scalar(keys %$f) * (1<<$_);
   }
  $n
 } # freeSpace

sub totalSpace($)                                                               # Total space currently occupied by this buddy system
 {my ($buddySystem) = @_;                                                       # Buddy system
  my $n = $buddySystem->size;
  return 0 unless $n;
  1 << ($buddySystem->size-1)                                                   # System invariant
 } # totalSpace

sub fractionalFreeSpace($)                                                      ## Fraction of space currently free vs total space
 {my ($buddySystem) = @_;                                                       # Buddy system
  my $t = $buddySystem->totalSpace;
  my $f = $buddySystem->freeSpace;
  return 1 unless $t > 0;
  $f / $t
 } # fractionalFreeSpace

sub checkSpace($)                                                               ## Check free space and used space match total space
 {my ($buddySystem) = @_;                                                       # Buddy system
  my $b = $buddySystem;                                                         # Shorten
  my $u = $b->usedSpace;
  my $f = $b->freeSpace;
  my $t = $b->totalSpace;
  my $T = $u + $f;
  confess "checkSpace failed used=$u free=$f used+free=$T != total=$t\n"
#   .dump($b)."\n"
    unless $u+$f == $t;

  if (1)                                                                        # Confirm used space matches allocated space
   {my $n = 0;
    for my $s(0..$b->size-1)                                                    # All the free chains
     {$n += ($b->allFrees->[$s]//0) * (1<<$s);                                  # Number of currently allocated blocks of this size
     }
    confess "checkSpace failed used=$u n=$n"
#   .dump($b)."\n"
    unless $u == $n;
   }

  1
 } # checkSpace

sub visualise($$)                                                               ## Create a pictorial representation of the buddy system with free in lowercase and used in uppercase. Confess if free and used chains are inconsistent
 {my ($buddySystem, $title) = @_;                                               # BuddySystem, title
  my $S = $buddySystem->size;                                                   # Size of system
  my $L = 26;                                                                   # Length of alphabet
  my @A = map {chr(ord('a')-1+$_)} 1..$L;                                       # Use lowercase for free areas and upper case for used areas
  my $e = 0; my $x = 0;                                                         # Number of error cells, number of cells examined

  my @t = map {undef()} 1..$buddySystem->totalSpace;                            # Long representation
  for my $B(0..$S-1)                                                            # All the free/used blocks
   {my $s = (1<<$B);                                                            # Size of free blocks on this chain
    if (my $F = $buddySystem->freeChains->[$B])                                 # Free blocks of this size
     {for my $f(sort {$a <=> $b} keys %$F)                                      # Free block
       {for(0..$s-1)                                                            # Each cell of free block
         {my $o = $f+$_;                                                        # Offset
          my $c = $A[$B % $L];                                                  # Marker character for free block
          ++$x;                                                                 # Examined cells count
          if (defined($t[$o])) {++$e; $t[$o] = '*'} else {$t[$o] = $c}          # Do not overwrite previous free or used block
         }
       }
     }
   }
  if (my $U = $buddySystem->usedSize)                                           # Used blocks
   {for my $u(sort {$a <=> $b} keys %$U)                                        # Used blocks in ascending order of offset
     {my $s = $U->{$u};                                                         # Size of this used block
      for(1..(1<<$s))                                                           # Each cell of used block
       {my $o = $u+$_-1;                                                        # Offset
        my $c = $A[$s % $L];                                                    # Marker character for used block
        ++$x;
        if (defined($t[$o])) {++$e; $t[$o] = '*'} else {$t[$o] = uc $c}         # Do not overwrite previous free or used block
       }
     }
   }
  if ($e or $x != $buddySystem->totalSpace)                                     # Inconsistent state detected
   {use Data::Dump qw(dump);
    use Carp;
    say STDOUT "Inconsistent State!";
    say STDOUT "  e=$e  x=$x length=", $buddySystem->totalSpace;
    say STDOUT "  ", dump($buddySystem);
    say STDOUT '=', join '', map {$_//'*'} @t, "=";
    confess "Inconsistent state";
   }

  my @T = map {''} 1..$buddySystem->totalSpace;                                 # Short representation
  for my $B(0..$S-1)                                                            # All the free/used blocks
   {my $s = (1<<$B);                                                            # Size of free blocks on this chain
    if (my $F = $buddySystem->freeChains->[$B])                                 # Free blocks of this size
     {$T[$_] = $A[$B % $L] for sort {$a <=> $b} keys %$F;                       # Free block
     }
   }
  if (my $U = $buddySystem->usedSize)                                           # Used blocks
   {for my $u(sort {$a <=> $b} keys %$U)                                        # Used blocks in ascending order of offset
     {my $s = $U->{$u};                                                         # Size of this used block
      $T[$u] = uc $A[$s % $L];
     }
   }
  my $T = join '', @T;                                                          # Representation as a string
  say STDOUT "$title $T" if $title;
  $T
 } # visualise

#2 Relocation                                                                   # These methods copy one buddy system to another compacting free space in the process.
sub copy($$;$)                                                                  # Copy a buddy system to compact its free space, the largest blocks are placed in (0) - ascending, (1) - descending order of size, blocks that get relocated to new positions in the new buddy system will still be accessible by their original address or name
 {my ($buddySystem, $order, $copy) = @_;                                        # Buddy system, order, optional copy method to copy an old allocation into its corresponding new allocation
  my $n = new;                                                                  # The new buddy system

  if (my $u = $buddySystem->usedSize)                                           # Used blocks decreasing in size but increasing by address within each size
   {my @u = sort
     {my $c = $order ? $u->{$b} <=> $u->{$a} : $u->{$a} <=> $u->{$b};           # 0 - Ascending, 1 - Descending order
      return $c unless $c == 0;
      $a <=> $b                                                                 # Ascending address
     } keys %$u;

    for my $a(@u)                                                               # Each used block
     {my $size = $u->{$a};                                                      # Size of this block
      my $A;                                                                    # Address of relocated block
      if (my $name = $buddySystem->allocName->{$a})                             # Name attached to the block
       {$A = $n->allocField($name, $size);                                      # Create new block with same name in new buddy system
       }
      else
       {$A = $n->alloc($size);                                                  # Matching block in new buddy system
       }
      $copy->($a, $A, $size) if $copy;                                          # Copy data from old block to new block, using the specified size
      if (my $f = $buddySystem->cameFrom->{$a})                                 # Address this block originally came from if different from new address
       {if ($f != $A)                                                           # Record new position if different
         {$n->cameFrom->{$A} = $f;                                              # The original address at which the block was allocated
          $n->wentTo  ->{$f} = $A;                                              # The current address of a block from its original address
         }
       }
     }
   }
  $n
 } # copy

sub copyLargestLast($;$)                                                        # Copy a buddy system, compacting free space, the new addresses of allocations can be found in wentTo, the largest blocks are placed last
 {my ($buddySystem, $copy) = @_;                                                # BuddySystem, copy method to copy an old allocation into a new allocation
  copy($buddySystem, 0, $copy);                                                 # Copy the buddy system
 } # copyLargestLast

sub copyLargestFirst($;$)                                                       # Copy a buddy system, compacting free space, the new addresses of allocations can be found in wentTo, the largest blocks are placed first
 {my ($buddySystem, $copy) = @_;                                                # BuddySystem, copy method to copy an old allocation into a new allocation
  copy($buddySystem, 1, $copy);                                                 # Copy the buddy system
 } # copyLargestFirst


#2 Structure                                                                    # This method generates a blessed sub whose methods provide named access to allocations backed by a L<perlfunc/vec> string
sub generateStructureFields($$)                                                 # Return a blessed sub whose methods access the named blocks in the buddy system. The blessed sub returns a text representation of the method definitions
 {my ($buddySystem, $package) = @_;                                             # Buddy system, structure name
  my $new    = $buddySystem->copyLargestLast;                                   # Organise the buddy system by element size
  my %allocs = %{$new->allocName};                                              # Named allocations
  my %sizes  = %{$new->usedSize};                                               # Size of each named allocation
  my $s = <<END;                                                                # String of sub definitions in the specified package
package $package;
use utf8;
END
  my @s;
  for my $alloc(sort {$a<=>$b} keys %allocs)
   {my $name = $allocs{$alloc};                                                 # Name of block
    my $size = $sizes{$alloc};                                                  # Log2 width of block
    my $bits = 2**$size;                                                        # Block size in vec terms
    my $offset = $alloc/$bits;                                                  # Block offset in vec terms
    $offset == int($offset) or                                                  # Something has gone seriously wrong if this calculation fails to produce an integer
      confess "Offset should be an integer not $offset";
    push @s,                                                                    # Generate an lvalue sub to access the block by the assigned name
     ["sub $name", " :lvalue {vec(\$_[1], ", $offset.", ",  $bits, ")}\n"];
   }
  $s .= formatTableBasic([@s]);                                                 # Layout the method definitions so they are easy to read
  eval $s;                                                                      # Generate methods
  $@ and confess "$s\n$@";
  my $p = <<END;                                                                # Define the blessed sub whose value is the text representation if its methods
bless sub {\$s}, "$package";
END
  my $P = eval $p;                                                              # Generate the blessed sub whose value is the text representation if its methods
  $@ and confess "$p\n$@";
  $P
 } # generateStructureFields

# Test
sub test{eval join('', <Data::Layout::BuddySystem::DATA>) or die $@}

test unless caller;

# Documentation
#extractDocumentation() unless caller;                                          # Extract the documentation

1;

=encoding utf-8

=head1 Name

Data::Layout::BuddySystem - Layout data in memory allocated via a buddy system

=head1 Synopsis

 use Test::More tests=>10;
 use Data::Layout::BuddySystem;
 use utf8;

 my $b = Data::Layout::BuddySystem::new;                                        # Create a new buddy system

 $b->allocField(@$_) for                                                        # Allocate fields in the buddy system
   [𝝳=>6], [𝝰=>0], [𝝙=>6],[𝝱=>0],[𝞈 =>4], [𝝺=>5], [𝝲=>0], [𝝖=>3], [𝝗=>3];       # Name and log2 size of each field

 my $s = $b->generateStructureFields('Struct');                                 # Generate structure definition

 ok nws($s->()) eq nws(<<'END');                                                # String representation of methods associated with generated structure
package Struct;
use utf8;
sub 𝝰    :lvalue {vec($_[1],   0,    1  )}
sub 𝝱    :lvalue {vec($_[1],   1,    1  )}
sub 𝝲    :lvalue {vec($_[1],   2,    1  )}
sub 𝝖    :lvalue {vec($_[1],   1,    8  )}
sub 𝝗    :lvalue {vec($_[1],   2,    8  )}
sub 𝞈   :lvalue {vec($_[1],   2,   16  )}
sub 𝝺    :lvalue {vec($_[1],   2,   32  )}
sub 𝝳    :lvalue {vec($_[1],   2,   64  )}
sub 𝝙    :lvalue {vec($_[1],   3,   64  )}
END

  if (1)                                                                        # Set fields
   {$s->𝝰(my $𝕄) = 1; ok $𝕄 eq "\1";
    $s->𝝱(   $𝕄) = 0; ok $𝕄 eq "\1";
    $s->𝝲(   $𝕄) = 1; ok $𝕄 eq "\5";
    $s->𝝖(   $𝕄) = 3; ok $𝕄 eq "\x05\x03";                                      # Byte fields
    $s->𝝗(   $𝕄) = 7; ok $𝕄 eq "\x05\x03\x07";
    $s->𝞈(   $𝕄) = 9; ok $𝕄 eq "\x05\x03\x07\x00\x00\x09";                      # Word field
   }

  if (1)                                                                        # Set and get an integer field
   {$s->𝝺(my $𝕄) = 2; ok $s->𝝺($𝕄) == 2;                                        # Set field
    $s->𝝺(   $𝕄)++;   ok $s->𝝺($𝕄) == 3;                                        # Increment field
    ok $𝕄 eq "\0\0\0\0\0\0\0\0\0\0\0\3";                                        # Dump the memory organised by the buddy system
   }

=head1 Description

Implements the buddy system described at L<https://en.wikipedia.org/wiki/Buddy_memory_allocation>
in 100% Pure Perl.  Blocks can be identified by names or addresses which remain
invariant even after one buddy system has been copied to a new one to compact
free space. Each named allocation can be accessed via a generated method which
identifies an lvalue area of a L<perlfunc/vec> string used to back the memory
organised by the buddy system.


=head1 Methods

=head2 new()

Create a new Buddy system


=head2 allocField($buddySystem, $name, $size)

Allocate a block in the buddy system, give it a name that is invariant even after this buddy system has been copied to a new buddy system to compact its storage, and return the address of its location in the buddy system

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $name         name of block
  3  $size         integer log2(size of allocation)

=head2 alloc($buddySystem, $size)

Allocate a block and return its address

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $size         integer log2(size of allocation)

=head2 locateAddress($buddySystem, $alloc)

Find the current location of a block by its original address after it has been copied to a new buddy system

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $alloc        address at which the block was originally located

=head2 locateName($buddySystem, $name)

Find the current location of a named block after it has been copied to a new buddy system

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $name         name of the block

=head2 freeName($buddySystem, $name)

Free an allocated block via its name

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $name         name used to allocate block

=head2 free($buddySystem, $alloc)

Free an allocation via its original allocation address

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $alloc        original allocation address

=head2 Statistics

These methods provide statistics on memory usage in the buddy system

=head3 usedSpace($buddySystem)

Total allocated space in this buddy system

     Parameter     Description
  1  $buddySystem  Buddy system

=head3 freeSpace($buddySystem)

Total free space that can still be allocated in this buddy system without changing its size

     Parameter     Description
  1  $buddySystem  Buddy system

=head3 totalSpace($buddySystem)

Total space currently occupied by this buddy system

     Parameter     Description
  1  $buddySystem  Buddy system

=head2 Relocation

These methods copy one buddy system to another compacting free space in the process.

=head3 copy($buddySystem, $order, $copy)

Copy a buddy system to compact its free space, the largest blocks are placed in (0) - ascending, (1) - descending order of size, blocks that get relocated to new positions in the new buddy system will still be accessible by their original address or name

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $order        order
  3  $copy         optional copy method to copy an old allocation into its corresponding new allocation

=head3 copyLargestLast($buddySystem, $copy)

Copy a buddy system, compacting free space, the new addresses of allocations can be found in wentTo, the largest blocks are placed last

     Parameter     Description
  1  $buddySystem  BuddySystem
  2  $copy         copy method to copy an old allocation into a new allocation

=head3 copyLargestFirst($buddySystem, $copy)

Copy a buddy system, compacting free space, the new addresses of allocations can be found in wentTo, the largest blocks are placed first

     Parameter     Description
  1  $buddySystem  BuddySystem
  2  $copy         copy method to copy an old allocation into a new allocation

=head2 Structure

This method generates a blessed sub whose methods provide named access to allocations backed by a L<perlfunc/vec> string

=head3 generateStructureFields($buddySystem, $package)

Return a blessed sub whose methods access the named blocks in the buddy system. The blessed sub returns a text representation of the method definitions

     Parameter     Description
  1  $buddySystem  Buddy system
  2  $package      structure name

=head1 Index

The following methods will be exported by the :all tag

L</alloc($buddySystem, $size)>
L</allocField($buddySystem, $name, $size)>
L</copy($buddySystem, $order, $copy)>
L</copyLargestFirst($buddySystem, $copy)>
L</copyLargestLast($buddySystem, $copy)>
L</free($buddySystem, $alloc)>
L</freeName($buddySystem, $name)>
L</freeSpace($buddySystem)>
L</generateStructureFields($buddySystem, $package)>
L</locateAddress($buddySystem, $alloc)>
L</locateName($buddySystem, $name)>
L</new()>
L</totalSpace($buddySystem)>
L</usedSpace($buddySystem)>

=head1 Installation

This module is written in 100% Pure Perl and is thus easy to read, modify and
install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2016 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use utf8;
use Test::More tests=>231;

if (1)                                                                          # Size
 {my $b = Data::Layout::BuddySystem::new;
  my $i = 0;
  ok $b->size == 0;
  $b->alloc(0); ok $b->size == 1; ok $b->totalSpace ==  1; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 2; ok $b->totalSpace ==  2; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 3; ok $b->totalSpace ==  4; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 3; ok $b->totalSpace ==  4; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 4; ok $b->totalSpace ==  8; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 4; ok $b->totalSpace ==  8; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 4; ok $b->totalSpace ==  8; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 4; ok $b->totalSpace ==  8; ok $b->usedSpace == ++$i;

  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;
  $b->alloc(0); ok $b->size == 5; ok $b->totalSpace == 16; ok $b->usedSpace == ++$i;

  $b->alloc(0); ok $b->size == 6;
 }

if (1)
 {my @r = qw(. BAa CBb DCc EDd FEe GFf HGg IHh JIi);
  for my $s(2..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 2,1
    my @o = map {$b->alloc($_)} $s, $s-1;
    ok $b->visualise eq $r[$s];

    $b->free($_) for $s % 2 ? @o : reverse @o;
    ok !$b->visualise;
    $b->checkSpace;
   }
 }

if (1)                                                                          # Allocate and free while comparing visual free space with reported free space
 {my $f = 0;
  my $b = Data::Layout::BuddySystem::new;
  my @a = qw(9 7 2 4 8 3 8 5 0 7 3 5 7 4 3 8 1 9 9 6 7 2 6 2 3 -10 6 5 3 4 5 7 8 0 1 6 7 1 9 5 5 6 7 8 7 0 6 2 1 2 4 2 -12 9 6 6 1 4 7 0 4 3 3 6 5 5 6 7 0 8 4 4 2 0 7 0 5 5 7 0 5 5 -22 8 1 6 0 8 1 1 4 1 1 6 4 6 6 4 2 6 7 4 2 1 5 4 0 5 3 -10 3 1 9 1 1 2 9 8 1 0 5 9 2 2 5 7 4 6 6 6 -1 4 2 4 1 3 5 6 4 5 3 6 6 7 -22 1 8 7 2 8 7 8 2 0 0 1 7 2 1 1 8 3 2 3 5 9 9 -13 3 9 7 4 0 5 6 1 1 0 3 4 6 3 7 2 6 0 7 3 9 1 1 4 7 5 9 5 2 1 8 1 3 2 6 0 8 9 5 1 1 6 5 7 4 3 7 5 2 1 9 3 9 7 8 2 5 1 5 2 0 8 2 6 4 6 4 2 7 4 0 2 7 4 0 3 5 5 7 -40 5 3 6 5 8 1 0 7 5 2 1 9 8 1 9 7 4 8 6 3 8 1 0 8 0 9 4 1 9 7 2 6 8 1 5 9 5 6 0 7 7 1 9 3 8 7 0 5 5 9 4 1 7 6 8 5 9 3 0 6 4 3 9 2 3 4 2 1 9 7 6 8 4 7 5 9 7 9 8 5 4 0 4 0 8 4 8 1 8 2 1 8 8 0 6 1 1 3 9 0 7 9 4 8 0 5 6 7 7 4 7 7 1 0 1 9 9 1 6 6 5 1 6 7 3 1 5 3 5 7 6 7 1 6 4 8 5 2 9 1 9 3 1 8 6 8 6 6 9 3 0 2 0 8 2 6 -78 2 0 1 9 0 8 1 8 6 3 7 8 9 1 6 3 9 3 4 6 9 2 7 8 1 0 0 1 6 8 7 0 1 1 0 1 5 2 4 3 1 7 5 4 2 7 2 6 1 7 6 2 0 4 1 8 5 6 4 3 8 6 5 3 9 3 2 4 3 8 6 8 6 9 1 1 5 4 9 2 7 9 3 5 1 6 8 4 8 9 4 3 4 1 0 1 4 2 5 5 7 5 4 8 0 4 7 3 9 7 2 1 4 9 1 2 1 0 3 5 4 5 8 5 2 4 2 1 6 0 7 6 0 8 8 6 7 4 0 4 5 5 1 6 8 5 2 8 -99  2 5 1 3 2 3 3 2 5 6 0 9 2 1 4 0 3 5 6 8 2 0 2 1 6 4 3 0 3 4 3 5 2 2 2 6 6 8 6 0 5 6 8 3 4 4 6 4 8 5 7 1 1 9 1 6 7 1 7 3 3 7 0 8 1 4 2 4 7 7 9 9 3 3 8 1 3 3 2 5 5 -21 2 8 1 1 0 4 1 0 3 0 8 9 3 5 1 1 6 0 4 8 6 4 3 0 3 3 9 0 6 7 2 8 8 4 7 5 7 3 1 8 2 9 7 7 4 4 3 3 7 9 2 3 4 1 0 6 1 4 9 6 0 7 8 4 9 5 1 8 2 4 3 3 8 1 3 2 3 9 0 5 7 9 2 8 4 4 2 7 2 3 4 1 8 4 4 1 0 3 9 1 7 0 7 7 6 9 3 6 2 9 8 9 2 4 6 8 4 6 2 7 7 3 4 3 5 8 1 7 6 4 8 9 9 1 6 6 7 8 4 4 1 5 0 0 0 -111 2 4 4 1 0 1 5 5 8 9 9 9 4 7 1 3 6 8 7 3 8 5 2 7 2 4 3 3 9 2 4 8 9 2 2 6 1 6 1 4 0 0 7 4 8 6 5 5 2 6 7 5 0 6 1 2 2 5 6 0 -45 2 3 8 4 0 9 1 4 6 9 8 3 8 7 9 3 2 2 2 9 3 5 9 7 9 0 3 5 1 4 0 1 8 9 0 1 5 -33 7 8 6 0 6 4 0 6 0 5 6 0 9 3 1 0 6 3 6 8 4 7 5 0 1 8 4 1 3 8 8 1 5 0 5 4 7 0 5 3 6 6 0 7 6 9 2 4 1 8 3 6 7 2 6 8 1 9 8 0 1 9 9 6 5 2 6 1 -121 7 0 0 8 5 6 3 3 9 3 1 7 5 1 2 2 4 9 0 8 7 4 2 0 8 0 0 1 7 6 4 3 8 1 6 9 4 9 5 0 -23 4 9 2 3 2 0 0 5 5 2 7 1 2 7 2 5 0 9 7 2 5 -222);
  for(1..@a)                                                                    # Allocate random sizes
   {my $c = $a[$_-1];                                                           # Command
    if ($c > 0)                                                                 # Allocate
     {$b->alloc($c);
     }
    else                                                                        # Free
     {my @f = sort keys %{$b->usedSize};                                        # Randomized addresses to free at
      for(1..-$c)
       {next unless @f;
        $b->free(pop @f);
       }
     }
    $f += $b->fractionalFreeSpace;
    $b->checkSpace;                                                             # Basic check
   }
  $b->visualise;                                                                # Consistency check

  if (1)
   {my $B = $b->copyLargestFirst;
    $b->visualise(1111);
    $B->visualise(2222);
    for([$b, 'Before', 97], [$B, 'After', 9])
     {my $f = int(100 * $_->[0]->fractionalFreeSpace);                          # Fractional free space
      my $s = $_->[1];                                                          # System name
      my $e = $_->[2];                                                          # Expected free space
      ok $f == $e;
     }
   }

  if (1)                                                                        # Average free space
   {my $a = int(100 * $f / @a);
    say STDOUT "Average percent free space is $a%";
   }
 }

if (1)
 {my @r = qw(. . AABCAabc BBCDBbcd CCDECcde DDEFDdef EEFGEefg FFGHFfgh GGHIGghi HHIJHhij);
  for my $s(2..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 1,3,1,2,1
    $b->alloc($s-2);
    $b->alloc($s);
    $b->alloc($s-2);
    $b->alloc($s-1);
    $b->alloc($s-2);
#say STDOUT $b->visualise;
    ok $b->visualise eq $r[$s];
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(. . AabC BbcD CcdE DdeF EefG FfgH GghI HhiJ);
  for my $s(2..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 1,3
    $b->alloc($s-2);
    $b->alloc($s);
    ok $b->visualise eq $r[$s];
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(. AAB BBC CCD DDE EEF FFG GGH HHI IIJ);
  for my $s(1..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 1,2,1
    $b->alloc($s-1);
    $b->alloc($s);
    $b->alloc($s-1);
    ok $b->visualise eq $r[$s];
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(. AaB BbC CcD DdE EeF FfG GgH HhI IiJ);
  for my $s(1..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 1,2
    my @o = map {$b->alloc($_)} $s-1, $s;
    ok $b->visualise eq $r[$s];
    $b->free($_) for $s % 2 ? @o : reverse @o;
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(. BAa CBb DCc EDd FEe GFf HGg IHh JIi);
  for my $s(1..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # 2,1
    my @o = map {$b->alloc($_)} $s, $s-1;
    ok $b->visualise eq $r[$s];
    $b->free($_) for $s % 2 ? @o : reverse @o;
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(AA BB CC DD EE FF GG HH II JJ);
  for my $s(0..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # Double
    my @o = map {$b->alloc($_)} $s, $s;
    ok $b->visualise eq $r[$s];
    $b->free($_) for $s % 2 ? @o : reverse @o;
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)
 {my @r = qw(A B C D E F G H I J K);
  for my $s(0..9)
   {my $b = Data::Layout::BuddySystem::new;                                     # Single
    my $o = $b->alloc($s);
    ok $b->visualise eq $r[$s];
    $b->free($o);
    ok $b->totalSpace == 0;
    ok $b->checkSpace;                                                          # Basic check
   }
 }

if (1)                                                                          # Generate a structure with the following fields
 {my $b = Data::Layout::BuddySystem::new;                                       # Create a new buddy system

  $b->allocField(@$_) for                                                       # Allocate fields in the buddy system
   [𝝳=>6], [𝝰=>0], [𝝙=>6],[𝝱=>0],[𝞈 =>4], [𝝺=>5], [𝝲=>0], [𝝖=>3], [𝝗=>3];       # Name and log2 size of each field

  my $s = $b->generateStructureFields('Struct');                                # Generate structure definition

  ok nws($s->()) eq nws(<<'END');                                               # String representation of methods associated with generated structure
package Struct;
use utf8;
sub 𝝰    :lvalue {vec($_[1],   0,    1  )}
sub 𝝱    :lvalue {vec($_[1],   1,    1  )}
sub 𝝲    :lvalue {vec($_[1],   2,    1  )}
sub 𝝖    :lvalue {vec($_[1],   1,    8  )}
sub 𝝗    :lvalue {vec($_[1],   2,    8  )}
sub 𝞈   :lvalue {vec($_[1],   2,   16  )}
sub 𝝺    :lvalue {vec($_[1],   2,   32  )}
sub 𝝳    :lvalue {vec($_[1],   2,   64  )}
sub 𝝙    :lvalue {vec($_[1],   3,   64  )}
END

  ok $b->sizeName($$_[0]) == $$_[1] for [qw(𝝰  0)], [qw(𝝱  0)], [qw(𝝲  0)],
    [qw(𝝖 3)], [qw(𝝗 3)], [qw(𝞈 4)], [qw(𝝺 5)], [qw(𝝳 6)], [qw(𝝙   6)];

  ok  $s->𝝰(0x01);                                                              # Access fields
  ok !$s->𝝰(0x14);
  ok  $s->𝝱(0x02);
  ok !$s->𝝱(0x13);
  ok  $s->𝝲(0x04);
  ok !$s->𝝲(0x11);
  ok  $s->𝝖(" 0")  eq ord("0");
  ok  $s->𝝗(" 02") eq ord("2");

  if (1)                                                                        # Set fields
   {$s->𝝰(my $𝕄) = 1; ok $𝕄 eq "\1";
    $s->𝝱(   $𝕄) = 0; ok $𝕄 eq "\1";
    $s->𝝲(   $𝕄) = 1; ok  $𝕄 eq "\5";
    $s->𝝖(   $𝕄) = 3; ok $𝕄 eq "\x05\x03";                                      # Byte fields
    $s->𝝗(   $𝕄) = 7; ok $𝕄 eq "\x05\x03\x07";
    $s->𝞈(   $𝕄) = 9; ok $𝕄 eq "\x05\x03\x07\x00\x00\x09";                      # Word field
   }

  if (1)                                                                        # Set and get an integer field
   {$s->𝝺(my $𝕄) = 2; ok $s->𝝺($𝕄) == 2;                                        # Set field
    $s->𝝺(   $𝕄)++;   ok $s->𝝺($𝕄) == 3;                                        # Increment field
    ok $𝕄 eq "\0\0\0\0\0\0\0\0\0\0\0\3";                                        # Dump the memory organised by the buddy system
   }
 }

1;
