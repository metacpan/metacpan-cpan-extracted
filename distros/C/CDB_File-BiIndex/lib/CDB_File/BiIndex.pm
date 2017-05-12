#!/usr/bin/perl -w

package CDB_File::BiIndex;
$REVISION=q$Revision: 1.14 $ ;
use vars qw($VERSION);

$VERSION = '0.030';

=head1 NAME

CDB_File::BiIndex - index two sets of values against eachother.

=head1 SYNOPSIS

	use CDB_File::BiIndex;
	#test bi-index is initiated with CDB_Generator
	$index = new CDB_File::BiIndex "test";

	$index->lookup_first("USA");
	$index->lookup_second("Lilongwe");

=head1 DESCRIPTION

A CDB_File::BiIndex stores a set of relations from one set of strings to
another.  It's rather similar to a translators dictionary with a list
of words in one language linked to words in the other language.  The
same word can occur in each language, but it's translations would often
be different.

    I    <->  je
    {bar, pub}  <->  bar
    {truck, lorry, heavy goods vehicle} <-> camion

In this implementation it's just two parallel cdb hashes, which you
have to generate in advance.

=head1 EXAMPLE


    use CDB_File::BiIndex::Generator;
    use CDB_File::BiIndex;
    $gen = new CDB_File::BiIndex::Generator "test";

    $gen->add_relation("John", "Jenny");
    $gen->add_relation("Roger", "Beth");
    $gen->add_relation("John", "Gregory");
    $gen->add_relation("Jemima", "Jenny")
    $gen->add_relation("John", "Gregory");

    $gen->finish();

    $index = new CDB_File::BiIndex::Generator "test";

    $index->lookup_first("Roger");
	["Jenny"]
    $index->lookup_second("Jenny");
	["John", "Jemima"]
    $index->lookup_second("John");
	[]
    $index->lookup_first("John");
	["Jenny", "Gregory"]


=cut

use warnings;
use strict;

use Fcntl;
use CDB_File 0.86; # there are serious bugs in previous versions
use Carp;

# delete from here ...
BEGIN {
 $CDB_File::VERSION==0.9 and die <<EOF;

Suspicious CDB_File version string found (0.9).  This was used by
CDB_File 0.83 and can cause confusion!!! Please verify that you have
CDB_File _distribution_ version equal to or better than 0.86 and then
delete this check from the CDB_File::BiIndex.  See the
CDB_File::BiIndex Manual page (BUGS section) for details.

EOF
}

# ... delete to here

$CDB_File::BiIndex::verbose=0 unless defined $CDB_File::BiIndex::verbose;
#all debugging messages
#$CDB_File::BiIndex::verbose=0xffff unless defined $CDB_File::BiIndex::verbose;

=head1 METHODS

=cut

sub DUMB () {1};
sub SEEKABLE () {2};

our ($mode);

BEGIN {
  $mode=DUMB;
}

#  =head1 _cdb_set_iterate

#  _cdb_set_iterate sets of a CDB so that it will start just after the
#  key given.

#  =cut

sub _cdb_set_iterate {
  my $cdb = shift;
  my $target = shift;
  print STDERR "cdb_set_iterate called for $target\n"
    if $CDB_File::BiIndex::verbose & 32;
 CASE: {
    $mode == DUMB and do {
      my $key=$cdb->FIRSTKEY();
      while ( defined $key and $key lt $target) {
	print "key is $key\n"
	  if $CDB_File::BiIndex::verbose & 64;
	$key=$cdb->NEXTKEY($key);
      }
      print "final key is $key\n"
	if $CDB_File::BiIndex::verbose & 64;
      return $key;
    };
    die "more efficient modes than DUMB not yet defined";
  }
  die "internal error: don't know how to _cdb_set_iterate";
}



=head2 CDB_File::BiIndex->new(<file>,[<file>])

	new (CLASS, database_filenamebase)
	new (CLASS, first_database_filename, second_database_filename)

New opens and sets up the databases.

=cut

#FIXME.  This should be generalised so it works on any pair of hashes.
#which is very easy.


sub new ($$;$) {
  my $class=shift;
  my $self=bless {}, $class;

  #work out what the arguments mean.. 
  my $first_db_name = shift;
  carp "usage new CDB_File::BiIndex (<file>, [<file>])"
    unless defined $first_db_name;
  my $second_db_name;
  if (@_) {
    $second_db_name = shift ;
  } else {
    $second_db_name = $first_db_name . ".2-1";
    $first_db_name = $first_db_name . ".1-2";
  }

  $self->{"first_cdb"} = tie my %first_hash, "CDB_File", $first_db_name
    or die "Couldn't tie $first_db_name" . $!;
  $self->{"first_hash"} = \%first_hash;
  $self->{"second_cdb"} = tie my %second_hash, "CDB_File", $second_db_name
    or die "Couldn't tie $second_db_name" . $!;
  $self->{"second_hash"} = \%second_hash;

  $self->{"first_lastkey"}=undef;
  $self->{"second_lastkey"}=undef;

  return $self;
}


=head2 $bi->lookup_first(<key>) $bi->lookup_second(<key>)

returns a B<reference> to a list of values which are indexed against
key, direction of the relation depending on which function is used.

=cut


sub lookup_first ($$) {
  my ($self, $key)=@_;
  print STDERR "lookup_first has been called with key $key\n"
    if $CDB_File::BiIndex::verbose & 32;
  croak "lookup_first called with undefined key"
    unless defined $key;
  my $return=$self->{"first_cdb"}->multi_get($key);
  return undef unless defined $return;
  die "multi_get didn't return an array ref" unless
      (ref $return) =~ m/ARRAY/;
  return undef unless @$return;
  return $return;
}

sub lookup_second ($$) {
  my ($self, $key)=@_;
  print STDERR "lookup_second has been called with key $key\n"
    if $CDB_File::BiIndex::verbose & 32;
  croak "lookup_second called with undefined key"
    unless defined $key;
  my $return=$self->{"second_cdb"}->multi_get($key);
  return undef unless defined $return;
  die "multi_get didn't return an array ref" unless
      (ref $return) =~ m/ARRAY/;
  return undef unless @$return;
  return $return;
}

# =head1 validate

# Because the two indexes match eachother, they should make sense
# together.  Anything which is indexed under a key in the first index
# should be a key in the second index with a the original key part of
# its value

# =cut

# sub validate {
#   my $self=shift;
#   if ( validate_against($self->{"first_cdb"},$self->{"second_cdb"}) 
#       || validate_against($self->{"second_cdb"},$self->{"first_cdb"}) ) {
#       return 0; #the validation procedures found faults
#   } else {
#       return 1; #validated okay.
#   }
# }

# sub validate_against{
#   my $cdb_one = shift;
#   die "non cdb passed as validate_against first arg" 
#       unless ref($cdb_one);
#   my $cdb_two = shift;
#   die "non cdb passed as validate_against second arg" 
#       unless ref($cdb_two);

#   my $break_count = 0;

#   #reset the iteration
#   $cdb_one->start_iter();
#   #loop through all of the entries in the first cdb
#   my ($key,$value);
#  RELATION: while (($key,$value) = $cdb_one->iterate()) {
#     unless ($cdb_two->set_position($value)) {
#       warn "Relation $key to $value in #1, but not $value as key in #2";
#       $break_count++;
#       next RELATION;
#     }
#     my ($rkey, $rvalue);
#   CHECK: while (($rkey, $rvalue) = $cdb_two->iterate()) {
#       last CHECK unless $rkey=$value;
#       next RELATION if $rvalue=$key;
#     }
#     warn "Relation $key to $value in #1, but $key not in " 
# 	  . $value . "'s record in #2";
#     $break_count++;
#   }
#   return $break_count;
# }

=head1 ITERATORS

The iterators iterate over the different keys in the database.  They
skip repeated keys.

=over 4

=item first_set_iterate(<key>) second_set_iterate(<key>)

set the key of the next value that will be returned

=item first_next([<last key>]) second_next([<last key>])

return the next key in the hash.  If there has never been any
iteration before we will return the first key from the database.  If
there has been iteration, we will return the key imediately following
the key which was last returned.

If called with an argument, the key following that argument will be
returned in any case, but if that argument is exactly the last key
returned, we won't seek in the database (set_iterate would do that
anyway).

=cut


# we always have to make sure that FIRST is called once
# we can call nextkey all we want until we go off the end.
# when we go off the end, we should call FIRST again

# strictly internal functions to overcome some of CDB_Files
# wierdnesses and to allow us to iterate at the same time as doing
# other lookups.

#  =item xx_first()

#  return the first key

#  =item xx_next()

#  return the next key in the hash after a first

#  =item xx_reset()

#  iteration will start from the first key again.  Don't normally need to call this.

#  =cut

sub first_reset ($) {
  print STDERR "first_reset called\n"
    if $CDB_File::BiIndex::verbose & 32;
  my $self=shift;
  my $a=scalar keys %{$self->{"first_hash"}};
  $self->{"first_lastkey"}=undef;
}

sub first_first ($) {
  print STDERR "first_first called\n"
    if $CDB_File::BiIndex::verbose & 32;
  my $self=shift;
  $self->first_reset(); #overcomes CDB wierdness if I remember??
  my $key =  $self->{"first_cdb"}->FIRSTKEY();
  $self->{"first_lastkey"}=$key;
  return $key;
}

sub first_next ($;$) {
  my $self=shift;
  my $key=shift;

  my $lastkey=$self->{"first_lastkey"};

  $CDB_File::BiIndex::verbose & 32 && do {
    print STDERR "first_next called ";
    if (defined $lastkey ) {
      print STDERR " stored key $lastkey";
    } else {
      print STDERR " no stored key";
    }
    if (defined $key ) {
      print STDERR " key $key\n";
    } else {
      print STDERR " no key\n";
    }
  };

 CASE: {

    defined $lastkey or defined $key or do {
      #this is the start of iteration
      print STDERR "never iterated; start with first_first\n"
	if $CDB_File::BiIndex::verbose & 32;
      return $self->first_first();
    };

    defined $key and not (defined $lastkey and $key eq $lastkey) and do {
      $self->first_set_iterate($key);
      $lastkey=$key;
    };

  }

  $key=$lastkey;

 KEY: while (1) {
    $key=$self->{"first_cdb"}->NEXTKEY($key);
    defined $key or last KEY;
    $key eq $lastkey or last KEY;
    print STDERR "repeat of last key $key. skipping.\n"
      if $CDB_File::BiIndex::verbose & 128;
  }

  ( $CDB_File::BiIndex::verbose & 64 ) && do {
    print STDERR "returning key $key\n" if defined $key ;
    print STDERR "reached the end returning undefined key \n" 
      unless defined $key;
  };

  #if we run off the end then we should start at the beginning next time
  $self->{"first_lastkey"}=$key;
  return $key;
}

sub first_set_iterate ($$) {
  my $self=shift;
  my $key=shift;
  print STDERR "first_set_iterate has been called with key $key\n"
    if $CDB_File::BiIndex::verbose & 32;
  $key=_cdb_set_iterate($self->{"first_cdb"}, $key);
  $self->{"first_lastkey"}=$key;
  return $key;
}

sub second_reset ($) {
  print STDERR "second_reset called\n"
    if $CDB_File::BiIndex::verbose & 32;
  my $self=shift;
  my $a=scalar keys %{$self->{"second_hash"}};
  delete $self->{"second_lastkey"};
}

sub second_first ($) {
  print STDERR "second_first called\n"
    if $CDB_File::BiIndex::verbose & 32;
  my $self=shift;
#  $self->second_reset(); #overcomes CDB wierdness if I remember??
  my $key =  $self->{"second_cdb"}->FIRSTKEY();
  $self->{"second_lastkey"}=$key;
  return $key;
}

sub second_next ($;$) {
  my $self=shift;
  my $key=shift;

  my $lastkey=$self->{"second_lastkey"};

  $CDB_File::BiIndex::verbose & 32 && do {
    print STDERR "second_next called ";
    if (defined $lastkey ) {
      print STDERR " stored key $lastkey";
    } else {
      print STDERR " no stored key";
    }
    if (defined $key ) {
      print STDERR " key $key\n";
    } else {
      print STDERR " no key\n";
    }
  };

 CASE: {

    defined $lastkey or defined $key or do {
      #this is the start of iteration
      print STDERR "never iterated; start with second_first\n"
	if $CDB_File::BiIndex::verbose & 32;
      return $self->second_first();
    };

    defined $key and not (defined $lastkey and $key eq $lastkey) and do {
      $self->second_set_iterate($key);
      $lastkey=$key;
    };

  }

  $key=$lastkey;

 KEY: while (1) {
    $key=$self->{"second_cdb"}->NEXTKEY($key);
    defined $key or last KEY;
    $key eq $lastkey or last KEY;
    print STDERR "repeat of last key $key. skipping.\n"
      if $CDB_File::BiIndex::verbose & 128;
  }

  ( $CDB_File::BiIndex::verbose & 64 ) && do {
    print STDERR "returning key $key\n" if defined $key ;
    print STDERR "reached the end returning undefined key \n" 
      unless defined $key;
  };

  #if we run off the end then we should start at the beginning next time
  $self->{"second_lastkey"}=$key;
  return $key;
}

sub second_set_iterate ($$) {
  my $self=shift;
  my $key=shift;
  print STDERR "second_set_iterate has been called with key $key\n"
    if $CDB_File::BiIndex::verbose & 32;
  $key=_cdb_set_iterate($self->{"second_cdb"}, $key);
  $self->{"second_lastkey"}=$key;
  return $key;
}


=head1 BUGS

This module requires the version of the CDB_File perl module to be
better than 0.86.  Unfortunately, version 0.83 was given the version
string "0.9" (and version 0.86 has the string '0.86').  This means
that normal perl version checking will not give the correct warnings.
There is a hardwired check that the version is not 0.9.  I assume that
future CDB_File modules won't use that version number, but if they do,
then please edit inside the CDB_File::BiIndex perl module file its
self and delete the section between the lines

  # delete from here ...

and

  # ... delete to here

the module will then hopefully work properly.

N.B. please only do that B<if you have verified that you have a newer
version> of the distribution than 0.86.

=head1 COPYING

This module may be distributed under the same terms as perl.

=cut


1; #what does it prove...
