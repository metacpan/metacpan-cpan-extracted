package CWB::CL;

use strict;
use warnings;

use Carp qw<croak confess>;

use base qw(DynaLoader);
our $VERSION = '2.2.102';

## load object library
bootstrap CWB::CL $VERSION;


#
#  ------------  initialisation code  ------------
#

## subroutine used to extract constant definitions from <cwb/cl.h> and put them into hash
sub get_constant_values {
  my @hash = ();                # build list that can be used to initialise hash
  my $symbol;

  foreach $symbol (@_) {
    my $val = constant($symbol);
    if ($! != 0) {              # indicates lookup failure
      croak "ERROR Constant '$symbol' not in <cwb/cl.h>";
    }
    push @hash, $symbol => $val;
  }
  return @hash;
}

## CL constants are packed into package hashes
# attribute types
our %AttType = get_constant_values(
                               qw(ATT_ALIGN ATT_ALL ATT_DYN ATT_NONE ATT_POS ATT_REAL ATT_STRUC)
                               );
# argument types
our %ArgType = get_constant_values(
                               qw(ATTAT_FLOAT ATTAT_INT ATTAT_NONE ATTAT_PAREF ATTAT_POS ATTAT_STRING ATTAT_VAR)
                              );

# error codes
our %ErrorCode = get_constant_values(
                                 qw(CDA_OK CDA_EALIGN CDA_EARGS CDA_EATTTYPE CDA_EBADREGEX CDA_EBUFFER),
                                 qw(CDA_EFSETINV CDA_EIDORNG CDA_EIDXORNG CDA_EINTERNAL),
                                 qw(CDA_ENODATA CDA_ENOMEM CDA_ENOSTRING CDA_ENULLATT CDA_ENYI CDA_EOTHER),
                                 qw(CDA_EPATTERN CDA_EPOSORNG CDA_EREMOTE CDA_ESTRUC),
                                );

# error symbols (indexed by <negative> error code) 
our @ErrorSymbol = sort {(-$ErrorCode{$a}) <=> (-$ErrorCode{$b})} keys %ErrorCode;

# regex flags (for cl_regex2id())
our %RegexFlags = (
               '' => 0,
               'c' => constant('IGNORE_CASE'), # ignore case
               'd' => constant('IGNORE_DIAC'), # ignore diacritics
               'cd' => constant('IGNORE_CASE') | constant('IGNORE_DIAC'),       # nice short-cut trick ...
               'dc' => constant('IGNORE_CASE') | constant('IGNORE_DIAC'),
              );

# structure boundary flags
our %Boundary = (
    'inside' => constant('STRUC_INSIDE'),
    'left' => constant('STRUC_LBOUND'),
    'right' => constant('STRUC_RBOUND'),
    'outside' => 0,  # for completeness
    'i' => constant('STRUC_INSIDE'),
    'l' => constant('STRUC_LBOUND'),
    'r' => constant('STRUC_RBOUND'),
    'o' => 0,
    'lr' => constant('STRUC_LBOUND') | constant('STRUC_RBOUND'), # these are all reasonable flag combinations
    'rl' => constant('STRUC_LBOUND') | constant('STRUC_RBOUND'),
    'leftright' => constant('STRUC_LBOUND') | constant('STRUC_RBOUND'),
    'rightleft' => constant('STRUC_LBOUND') | constant('STRUC_RBOUND'),    
  );

#
#  ------------  CWB::CL global variables  ------------
#

# registry directory
our $Registry = cl_standard_registry();

#
#  ------------  CWB::CL package functions  ------------
#

# return error message for last error encountered during last method call (or "" if last call was successful)
# -- CWB::CL::error_message(); [exported by XS code]

# access error messages for CL (and internal) error codes
# -- CWB::CL::cwb_cl_error_message($code); [exported by XS code]

# set strictness (in strict mode, every CL or argument error aborts the script with croak())
sub strict ( ; $ ) {
  my $current_mode = get_strict_mode();
  if (@_) {
    my $on_off = shift;
    set_strict_mode($on_off ? 1 : 0);
  }
  return $current_mode;
}

# set CL debugging level (0=no, 1=some, 2=all debugging messages)
sub set_debug_level ( $ ) {
  my $lvl = shift;
  $lvl = 0 if (lc $lvl) eq "none";
  $lvl = 1 if (lc $lvl) eq "some";
  $lvl = 2 if (lc $lvl) eq "all";
  croak "Usage:  CWB::CL::set_debug_level('none' | 'some' | 'all');"
    unless $lvl =~ /^[012]$/;
  CWB::CL::cl_set_debug_level($lvl);
}

# set CL memory limit (used only by makeall so far, so no point in setting it here)
sub set_memory_limit ( $ ) {
  my $mb = shift;
  croak "Usage:  CWB::CL::set_memory_limit(\$megabytes);"
    unless $mb =~ /^[0-9]+$/;
  croak "CWB::CL: invalid memory limit ${mb} MB (must be >= 42 MB)"
    unless $mb >= 42;
  CWB::CL::cl_set_memory_limit($mb);
}

# convert '|'-delimited string into proper (sorted) feature set value
# (if 's' or 'split' is given, splits string on whitespace; returns undef if there is a syntax error)
*make_set = \&cl_make_set;  # now implemented in pure XS for better efficiency
 
# compute intersection of two feature sets (CQP's 'unify()' function)
# (returns undef if there is a syntax error)
*set_intersection = \&cl_set_intersection;

# compute cardinality of feature set (= "size", i.e. number of elements)
# (returns undef if there is a syntax error)
*set_size = \&cl_set_size;

# convert feature set value into hashref
sub set2hash ( $ ) {
  my $set = shift;
  my $is_ok = defined set_size($set); # easy & fast way of validating feature set format
  if ($is_ok) {
    my @items = split /\|/, $set; # returns empty field before leading |
    shift @items;
    return { map {$_ => 1} @items };
  }
  else {
    return undef;
  }
}


#
#  ------------  CWB::CL::PosAttrib objects  ------------
#

package CWB::CL::PosAttrib;
use Carp;

sub new {
  my $class = shift;
  my $corpus = shift;           # corpus object  (provided by CWB::CL::Corpus->attribute)
  my $name = shift;             # attribute name (provided by CWB::CL::Corpus->attribute)
  my $self = {};

  my $corpusPtr = $corpus->{'ptr'};
  my $ptr = CWB::CL::cl_new_attribute($corpusPtr, $name, $CWB::CL::AttType{'ATT_POS'});
  unless (defined $ptr) {
    my $corpusName = $corpus->{'name'};
    local($Carp::CarpLevel) = 1; # call has been delegated from attribute() method of CWB::CL::Corpus object
    croak("Can't access p-attribute $corpusName.$name (aborted)")
      if CWB::CL::strict(); # CL library doesn't set error code in cl_new_attribute() function
    return undef;
  }
  return bless($ptr, $class);   # objects are just opaque containers for (Attribute *) pointers
}

sub DESTROY {
  my $self = shift;

  # disabled because of buggy nature of CL interface!
  #  CWB::CL::cl_delete_attribute($self);
}

sub max_cpos ( $ ) {
  my $self = shift;

  my $size = CWB::CL::cl_max_cpos($self);
  if ($size < 0) {
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $size;
}

sub max_id ( $ ) {
  my $self = shift;

  my $size = CWB::CL::cl_max_id($self);
  if ($size < 0) {
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $size;
}

*id2str = \&CWB::CL::cl_id2str;

*str2id = \&CWB::CL::cl_str2id;

*id2strlen = \&CWB::CL::cl_id2strlen;

*id2freq = \&CWB::CL::cl_id2freq;

*cpos2id = \&CWB::CL::cl_cpos2id;

*cpos2str = \&CWB::CL::cl_cpos2str;

sub regex2id ( $$;$ ) {
  my $self = shift;
  my $regex = shift;
  my $flags = (@_) ? shift : '';

  croak "Usage:  \$att->regex2id(\$regex [, 'c' | 'd' | 'cd' ]);"
    unless defined $regex and $flags =~ /^(c?d?|dc)$/;

  return CWB::CL::cl_regex2id($self, $regex, $CWB::CL::RegexFlags{$flags});
}

*idlist2freq = \&CWB::CL::cl_idlist2freq;

*idlist2cpos = \&CWB::CL::cl_idlist2cpos;

*id2cpos = \&CWB::CL::cl_idlist2cpos;  # simpler alias (may becomd standard name in future CL releases)


#
#  ------------  CWB::CL::StrucAttrib objects  ------------
#

package CWB::CL::StrucAttrib;
use Carp;

sub new {
  my $class = shift;
  my $corpus = shift;           # corpus object  (provided by CWB::CL::Corpus->attribute)
  my $name = shift;             # attribute name (provided by CWB::CL::Corpus->attribute)

  my $corpusPtr = $corpus->{'ptr'};
  my $ptr = CWB::CL::cl_new_attribute($corpusPtr, $name, $CWB::CL::AttType{'ATT_STRUC'});
  unless (defined $ptr) {
    my $corpusName = $corpus->{'name'};
    local($Carp::CarpLevel) = 1; # call has been delegated from attribute() method of CWB::CL::Corpus object
    croak("Can't access s-attribute $corpusName.$name (aborted)")
      if CWB::CL::strict(); # CL library doesn't set error code in cl_new_attribute() function
    return undef;
  }
  return bless($ptr, $class);
}

sub DESTROY {
  my $self = shift;

  # disabled because of buggy nature of CL interface!
  #  CWB::CL::cl_delete_attribute($self);
}


sub max_struc ( $ ) {
  my $self = shift;

  my $size = CWB::CL::cl_max_struc($self);
  if ($size < 0) {
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $size;
}

sub struc_values ( $ ) {
  my $self = shift;

  my $yesno = CWB::CL::cl_struc_values($self);
  if ($yesno < 0) {
    # so far, CL library generates no errors in this function (just FALSE)
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $yesno;
}

*cpos2struc = \&CWB::CL::cl_cpos2struc;

*cpos2struc2str = \&CWB::CL::cl_cpos2struc2str;
*cpos2str = \&cpos2struc2str; # alias in anticipation of the new object-oriented CL interface specification,

*struc2str = \&CWB::CL::cl_struc2str;

*struc2cpos = \&CWB::CL::cl_struc2cpos;

*cpos2struc2cpos = \&CWB::CL::cl_cpos2struc2cpos;

*cpos2boundary = \&CWB::CL::cl_cpos2boundary;

sub cpos2is_boundary ( $$;@ ){
  my $self = shift;
  my $test = lc(shift);
  my $test_flags = $CWB::CL::Boundary{$test};
  
  croak "Usage:  \$att->cpos2is_boundary({'i'|'o'|'l'|'r'|'lr'}, \$cpos, ...);"
    unless defined $test_flags;
  return CWB::CL::cl_cpos2is_boundary($self, $test_flags, @_);
}

#
#  ------------  CWB::CL::AlignAttrib objects  ------------
#

package CWB::CL::AlignAttrib;
use Carp;

sub new {
  my $class = shift;
  my $corpus = shift;           # corpus object  (provided by CWB::CL::Corpus->attribute)
  my $name = shift;             # attribute name (provided by CWB::CL::Corpus->attribute)
  my $self = {};

  my $corpusPtr = $corpus->{'ptr'};
  my $ptr = CWB::CL::cl_new_attribute($corpusPtr, $name, $CWB::CL::AttType{'ATT_ALIGN'});
  unless (defined $ptr) {
    my $corpusName = $corpus->{'name'};
    local($Carp::CarpLevel) = 1; # call has been delegated from attribute() method of CWB::CL::Corpus object
    croak("Can't access a-attribute $corpusName.$name (aborted)")
      if CWB::CL::strict(); # CL library doesn't set error code in cl_new_attribute() function
    return undef;
  }
  return bless($ptr, $class);
}

sub DESTROY {
  my $self = shift;

  # disabled because of buggy nature of CL interface
  #  CWB::CL::cl_delete_attribute($self->{'ptr'});
}


sub max_alg ( $ ) {
  my $self = shift;
  my $size = CWB::CL::cl_max_alg($self);
  if ($size < 0) {
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $size;
}

sub has_extended_alignment ( $ ) {
  my $self = shift;
  my $yesno = CWB::CL::cl_has_extended_alignment($self);
  if ($yesno < 0) {
    croak CWB::CL::error_message()." (aborted)"
      if CWB::CL::strict();
    return undef;
  }
  return $yesno;
}

*cpos2alg = \&CWB::CL::cl_cpos2alg;

*alg2cpos = \&CWB::CL::cl_alg2cpos;

*cpos2alg2cpos = \&CWB::CL::cl_cpos2alg2cpos; # convenience function combines cpos2alg() and alg2cpos()


#
#  ------------  CWB::CL::Corpus objects  ------------
#

# $corpus = new CWB::CL::Corpus "name";
# $lemma = $corpus->attribute("lemma", 'p');     # returns CWB::CL::Attribute object (positional attribute)
# $article = $corpus->attribute("article", 's'); # returns CWB::CL::AttStruc object  (structural attribute)
# $french = $corpus->attribute("name-french", 'a');  # returns CWB::CL::AttAlign     (alignment attribute)
# undef $corpus;                                 # delete corpus from memory

package CWB::CL::Corpus;
use Carp;

sub new {
  my $class = shift;
  my $corpusname = shift;
  my $self = {};

  # try to open corpus (corpus name needs to be all lowercase)
  $corpusname = uc($corpusname); # 'official' notation is all uppercase ...
  my $ptr = CWB::CL::cl_new_corpus(
      (defined $CWB::CL::Registry) ? $CWB::CL::Registry : CWB::CL::cl_standard_registry(),
      lc($corpusname)  # ... but CL API requires corpus name in lowercase
    );
  unless (defined $ptr) {
    croak("Can't access corpus $corpusname (aborted)")
      if CWB::CL::strict(); # CL library doesn't set error code in cl_new_corpus() function
    return undef;
  }
  $self->{'ptr'} = $ptr;
  $self->{'name'} = $corpusname;
  return bless($self, $class);
}

sub DESTROY {
  my $self = shift;

  # disabled because of buggy nature of CL interface
  #   CWB::CL::cl_delete_corpus($self->{'ptr'});
}

sub attribute {
  my $self = shift;
  my $name = shift;
  my $type = shift;

  if ($type eq 'p') {
    return (new CWB::CL::PosAttrib $self, $name);
  }
  elsif ($type eq 's') {
    return (new CWB::CL::StrucAttrib $self, $name);
  }
  elsif ($type eq 'a') {
    return (new CWB::CL::AlignAttrib $self, $name);
  }
  else {
    croak "USAGE: \$corpus->attribute(\$name, 'p' | 's' | 'a')";
  }
}




package CWB::CL;                        # back to main package for autosplitter's sake
1;
__END__


=head1 NAME

CWB::CL - Perl interface to the low-level Corpus Library of the IMS Open CWB

=head1 SYNOPSIS

  use CWB::CL;

  print "Registry path = ", $CWB::CL::Registry, "\n";
  $CWB::CL::Registry .= ":/home/my_registry";    # add your own registry directory

  # "strict" mode aborts if any error occurs (convenient in one-off scripts)
  CWB::CL::strict(1);                            # or simply load CWB::CL::Strict module
  CWB::CL::set_debug_level('some');              # 'some', 'all' or 'none' (default)

  # CWB::CL::Corpus objects
  $corpus = new CWB::CL::Corpus "HANSARD-EN";    # name of corpus can be upper or lower case
  die "Error: can't access corpus HANSARD-EN"    # all error conditions return undef
    unless defined $corpus;                      #   (checks are not needed in "strict" mode)
  undef $corpus;                                 # currently, mapped memory cannot be freed


  # CWB::CL::Attribute objects (positional attributes)
  $lemma = $corpus->attribute("lemma", 'p');     # returns CWB::CL::Attribute object
  $corpus_length = $lemma->max_cpos;             # valid cpos values are 0 .. $corpus_length-1
  $lexicon_size = $lemma->max_id;                # valid id values are 0 .. $lexicon_size-1

  $id  = $lemma->str2id($string); 
  @idlist = $lemma->str2id(@strlist);            # all scalar functions map to lists in list context
  $str = $lemma->id2str($id);
  $len = $lemma->id2strlen($id);
  $f   = $lemma->id2freq($id);
  $id  = $lemma->cpos2id($cpos);
  $str = $lemma->cpos2str($cpos);

  @idlist = $lemma->regex2id($re);               # regular expression matching
  @cpos = $lemma->idlist2cpos(@idlist);          # accessing the index (occurrences of given IDs)
  $total_freq = $lemma->idlist2freq(@idlist);    # better check the list size first on large corpora


  # CWB::CL::AttStruc objects (structural attributes)
  $chapter = $corpus->attribute("chapter", 's'); # returns CWB::CL::AttStruc object
  $number_of_regions = $chapter->max_struc;      # valid region numbers are 0 .. $number_of_regions-1
  $has_values = $chapter->struc_values;          # are regions annotated with strings?

  $struc = $chapter->cpos2struc($cpos);          # returns undef if not $cpos is not in <chapter> region
  ($start, $end) = $chapter->struc2cpos($struc); # returns empty list on error -> $start is undefined
  ($start, $end) = $chapter->cpos2struc2cpos($struc);  # returns empty list if not in <chapter> region
      # returns 2 * <n> values (= <n> start/end pairs) if called with <n> arguments
  $str  = $chapter->struc2str($struc);           # always returns undef if not $chapter->struc_values
  $str  = $chapter->cpos2str($cpos);             # combines cpos2struc() and struc2str() 

  # check whether corpus position is at boundary (l, r, lr) or inside/outside (i/o) of region
  if ($chapter->cpos2boundary($cpos) & $CWB::CL::Boundary{'l'}) { ... }
  if ($chapter->cpos2is_boundary('l', $cpos)) { ... }


  # CWB::CL::AttAlign objects (alignment attributes)
  $french = $corpus->attribute("hansard-fr", 'a'); # returns CWB::CL::AttAlign object
  $nr_of_alignments = $french->max_alg;          # alignment block numbers are 0 .. $nr_of_alignments-1
  $extended = $french->has_extended_alignment;   # extended alignment allows gaps & crossing alignments
  
  $alg = $french->cpos2alg($cpos);               # returns undef if no alignment was found
  ($src_start, $src_end, $target_start, $target_end) 
      = $french->alg2cpos($alg);                 # returns empty list on error
      # or use convenience function $french->cpos2alg2cpos($cpos);


  # Feature sets (used as values of CWB::CL::Attribute and CWB::CL::AttStruc)
  $np_f = $corpus->attribute("np_feat", 's');    # p- and s-attributes can store feature sets
  $fs_string = $np_f->cpos2str($cpos);           # feature sets are encoded as strings
  $fs = CL::set2hash($fs_string);                # expand feature set into hash (reference)
  if (exists $fs->{"paren"}) { ... {}
  $fs1 = CWB::CL::make_set("|proper|nogen|");    # validate feature set or construct from string
  $fs2 = CWB::CL::make_set("paren nogen proper", 'split');
  $fs  = CWB::CL::set_intersection($fs1, $fs2);  # intersection of feature set values
  $n   = CWB::CL::set_size($fs);                 # size of feature set


=head1 DESCRIPTION

Sorry, there is no full description for this module yet, since the 
B<CWB Corpus Library>, on which B<CWB::CL> is based, does not have 
complete documentation. 

All of the corpus access function provided by the B<CWB::CL> module are subject
to change in version 4.0 of the CWB.  If you want to use B<CWB::CL> anyway,
have a look at the test scripts in subdirectory F<t/> of the distribution.


=head1 COPYRIGHT

Copyright (C) 1999-2010 by Stefan Evert [http::/purl.org/stefan.evert]

This software is provided AS IS and the author makes no warranty as to
its use and performance. You may use the software, redistribute and
modify it under the same terms as Perl itself.

=cut

