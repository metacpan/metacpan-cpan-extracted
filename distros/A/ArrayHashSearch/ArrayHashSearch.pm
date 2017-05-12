package ArrayHashSearch;

=head1 NAME

ArrayHashSearch - Search utility for arrays and hashes in Perl.

=cut

use warnings;
use strict;
use vars qw($VERSION @EXPORT @EXPORT_OK @ISA);
require Exporter;

@ISA = qw(Exporter);
$VERSION = '0.04';
@EXPORT = qw(array_contain array_deeply_contain hash_contain hash_deeply_contain deeply_contain);

=head1 Features

=head2 array_contain

  this routine searches the given array for the given scalar value and stops at the first value match found
  parameters: <array reference> <scalar>
  returns 1 if an element with the given scalar value was found else 0

=cut

sub array_contain
{
   my $sourcearrayref = shift @_;
   my $targetscalar = shift @_;
   die "\nBad arguments for subroutine 'array_contains': firstly an array reference and secondly a scalar are required!\n" 
   unless ((ref $sourcearrayref eq "ARRAY") and (defined ($targetscalar) and not ref($targetscalar)));
   my $found = 0;
   #search for the given scalar in first dimension only
   foreach (sort @$sourcearrayref) #sort routine moves scalar elements to the beginning of array
   {
      if ($_ eq $targetscalar)
      {
         $found = 1;
         last;
      }
   }
   return $found;
}

=head2 array_deeply_contain

  this routine searches the given array and any hierarchy of referenced arrays for the given scalar value and stops at the first value match found
  parameters: <array reference> <scalar>
  returns 1 if an element with the given scalar value was found else 0

=cut
 
sub array_deeply_contain
{
   my $sourcearrayref = shift @_;
   my $targetscalar = shift @_;
   die "\nBad arguments for subroutine 'array_contains_recursive': firstly an array reference and secondly a scalar are required!\n" 
   unless ((ref $sourcearrayref eq "ARRAY") and (defined ($targetscalar) and not ref($targetscalar)));
   my $found = 0;
   #search for the given scalar in first dimension
   foreach (sort @$sourcearrayref) #sort routine moves scalar elements to the beginning of array
   {
      if (not ref($_) and ($_ eq $targetscalar))
      {
         return 1;
      }
   }
   #if not found yet, search for other dimensions (pointed to by references)
   foreach (reverse sort @$sourcearrayref) #sort and reverse move references to the beginning of array
   {
      if (ref $_)
      {
         die "\nArrays with references to non arrays are not supported only 'pure' multi-dimensional arrays!\n"
         unless (ref $_ eq "ARRAY");
         $found = array_deeply_contain($_,$targetscalar);
         return 1 if ($found);
      }      
   }
   return $found;
}

=head2 hash_contain

  this routine searches the given hash for the given scalar value and stops at the first value match found
  parameters: <hash reference> <scalar>
  returns 1 if an element with the given scalar value was found else 0

=cut

sub hash_contain
{
   my $sourcehashref = shift @_;
   my $targetscalar = shift @_;
   die "\nBad arguments for subroutine 'hash_contains': firstly a hash reference and secondly a scalar are required!\n" 
   unless ((ref $sourcehashref eq "HASH") and (defined ($targetscalar) and not ref($targetscalar)));
   my $found = 0;
   #search for the given scalar in first dimension only
   foreach (sort values %$sourcehashref) #sort routine moves scalar elements to the beginning of hash
   {
      if ($_ eq $targetscalar)
      {
         $found = 1;
         last;
      }
   }
   return $found;
}

=head2 hash_deeply_contain

  this routine searches the given hash and any hierarchy of referenced hashes for the given scalar value and stops at the first value match found
  parameters: <hash reference> <scalar>
  returns 1 if an element with the given scalar value was found else 0

=cut

sub hash_deeply_contain
{
   my $sourcehashref = shift @_;
   my $targetscalar = shift @_;
   die "\nBad arguments for subroutine 'hash_contains_recursive': firstly a hash reference and secondly a scalar are required!\n" 
   unless ((ref $sourcehashref eq "HASH") and (defined ($targetscalar) and not ref($targetscalar)));
   my $found = 0;
   #search for the given scalar in first dimension
   foreach (sort values %$sourcehashref) #sort routine moves scalar elements to the beginning of hash
   {
      if (not ref($_) and ($_ eq $targetscalar))
      {
         return 1;
      }
   }
   #if not found yet, search for other dimensions (pointed to by references)
   foreach (reverse sort values %$sourcehashref) #sort and reverse move references to the beginning of hash
   {
      if (ref $_)
      {
         die "\nHashes with references to non hashes are not supported only 'pure' multi-dimensional hashes!\n"
         unless (ref $_ eq "HASH");
         $found = hash_deeply_contain($_,$targetscalar);
         return 1 if ($found);
      }      
   }
   return $found;
}

=head2 deeply_contain

  this routine searches the given hash/array and any hierarchy of referenced hashes/arrays for the given scalar value and stops at the first value match found
  this routine should be used for mixed data structures of arrays and hashes.
  parameters: <reference to an array or a hash> <scalar>
  returns 1 if an element with the given scalar value was found else 0

=cut

sub deeply_contain
{
   my $sourcestructureref = shift @_;
   my $targetscalar = shift @_;
   die "\nBad arguments for subroutine 'structure_contains_recursive': firstly a hash or array reference and secondly a scalar are required!\n" 
   unless (((ref $sourcestructureref eq "HASH") or (ref $sourcestructureref eq "ARRAY")) and (defined ($targetscalar) and not ref($targetscalar)));
   my $found = 0;
   if (ref $sourcestructureref eq "HASH") #case of a hash
   {
      #search for the given scalar in first dimension
      foreach (sort values %$sourcestructureref) #sort routine moves scalar elements to the beginning of hash
      {
         if (not ref($_) and ($_ eq $targetscalar))
         {
            return 1;
         }
      }
      #if not found yet, search for other dimensions (pointed to by references)
      foreach (reverse sort values %$sourcestructureref) #sort and reverse move references to the beginning of hash
      {
         if (ref $_)
         {
            die "\nReferences to something else than hashes or arrays are invalid!\n"
            unless ((ref $_ eq "HASH") or (ref $_ eq "ARRAY"));
            $found = deeply_contain($_,$targetscalar);
            return 1 if ($found);
         }         
      }
   }
   elsif (ref $sourcestructureref eq "ARRAY") #case of an array
   {
      #search for the given scalar in first dimension
      foreach (sort @$sourcestructureref) #sort routine moves scalar elements to the beginning of array
      {
         if (not ref($_) and ($_ eq $targetscalar))
         {
            return 1;
         }
      }
   #if not found yet, search for other dimensions (pointed to by references)
      foreach (reverse sort @$sourcestructureref) #sort and reverse move references to the beginning of array
      {
         if (ref $_)
         {
            die "\nReferences to something else than hashes or arrays are invalid!\n"
            unless ((ref $_ eq "HASH") or (ref $_ eq "ARRAY"));
            $found = deeply_contain($_,$targetscalar);
            return 1 if ($found);
         }
         
      }
   }
   return $found;
}

1;
__END__

=head1 Synopsis

  use ArrayHashSearch;
  my $dummyarrayref = [1,3,7,11,13,17,19,23];
  my $dummyarrayref2 = ['a','c','z',$dummyarrayref];
    
  if (array_contain($dummyarrayref,7))
  {
    print "Value 7 exists in the array!";
  }  
  if (array_deeply_contain($dummyarrayref2,7))
  {
    print "Value 7 exists in the array!";
  }
  
  
  A more complex example:  
  
  use strict;
  use warnings;
  use ArrayHashSearch;
  
  my $dummyarray1 = [1,2,3];
  my $dummyarray2 = [4,5,$dummyarray1];
  my $dummyarray3 = [7,$dummyarray2,9];
  my $dummyhash1 = {1=>'a',2=>'b',3=>'c'};
  my $dummyhash2 = {1=>$dummyhash1,2=>'d',3=>'e'};
  my $dummyhash3 = {1=>'f',2=>'g',3=>$dummyhash2};
  my $dummystructure1 = [1=>$dummyhash3,2=>$dummyarray3,3=>10];
  my $dummystructure2 = {1=>'h',2=>$dummystructure1,3=>'i'};
  
  print "ARRAY BINGO!\n" if array_deeply_contain($dummyarray3,5);
  print "HASH BINGO!\n" if hash_deeply_contain($dummyhash3,'a');
  print "ARRAY/HASH BINGO!\n" if deeply_contain($dummystructure1,5);
  print "HASH/ARRAY BINGO!\n" if deeply_contain($dummystructure2,'a');

=head1 Description

  This module provides routines to search content of n-dimensional arrays and/or hashes for given values.
  These routines are useful for people who often test existence of specific values in complex data structures returned by other routines.
  Since there are currently no such built-in functions to search arrays/hashes, one can save time by using this module.

=head1 Bugs and Caveats

  There no known bugs at this time, but this doesn't mean there are aren't any. Use it at your own risk.
  Note that there may be other bugs or limitations that the author is not aware of.

=head1 Author

  Serge Tsafak <tsafserge2001@yahoo.fr>

=head1 Copyright

  This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 History

 Version 0.0.4: first release; December 2007

=cut
