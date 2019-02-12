## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dict::BDB.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analysis dictionary API using Lingua::TT::DBFile

package DTA::CAB::Analyzer::Dict::BDB;
use DTA::CAB::Analyzer ':child';
use DTA::CAB::Analyzer::Dict;
use DTA::CAB::Format;
use Lingua::TT::DBFile;
use IO::File;
use Carp;
use DB_File;
use Fcntl;
use Encode qw(encode decode);

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer::Dict);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     dictFile => $filename,    ##-- DB filename (default=undef)
##
##     ##-- Analysis Output
##     label          => $lab,   ##-- analyzer label
##     analyzeCode    => $code,  ##-- pseudo-accessor to perform actual analysis for token ($_); see DTA::CAB::Analyzer::Dict for details
##
##     ##-- Analysis Options
##     encoding       => $enc,   ##-- encoding of db file (default='UTF-8'): clobbers $dba{encoding} ; uses DB filters
##     keyEncoding    => $enc,   ##-- encoding of db file (default=undef): alternative to 'encoding'
##     valEncoding    => $enc,   ##-- encoding of db file (default=undef): alternative to 'encoding'
##
##     ##-- Analysis objects
##     dbf => $dbf,              ##-- underlying Lingua::TT::DBFile object (default=undef)
##     dba => \%dba,             ##-- args for Lingua::TT::DBFile->new()
##     #={
##     #  mode  => $mode,        ##-- default: 0644
##     #  flags => $flags,       ##-- default: O_RDONLY
##     #  type    => $type,      ##-- one of 'HASH', 'BTREE', 'RECNO', 'GUESS' (default: 'GUESS')
##     #  dbinfo  => \%dbinfo,   ##-- default: "DB_File::${type}INFO"->new();
##     #  dbopts  => \%opts,     ##-- db options (e.g. cachesize,bval,...) -- defaults to none (uses DB_File defaults)
##     # }
##    )
sub new {
  my $that = shift;
  my $dic = $that->SUPER::new(
			      ##-- filenames
			      dictFile => undef,

			      ##-- analysis objects
			      dbf=>undef,
			      dba=>{
				    type    => 'GUESS',
				    mode    => 0644,
				    flags   => O_RDONLY,
				   },

			      ##-- options
			      encoding       => 'UTF-8',
			      #keyEncoding   => undef,
			      #valEncoding   => undef,

			      ##-- analysis output
			      label => 'dict',
			      analyzeCode => $DTA::CAB::Analyzer::Dict::CODE_DEFAULT,

			      ##-- user args
			      @_
			     );
  delete($dic->{ttd}); ##-- don't inherit 'ttd' (in-memory hash dict) key
  return $dic;
}

## $dic = $dic->clear()
##  + just closes db
sub clear {
  my $dic = shift;
  $dic->{dbf}->close if ($dic->{dbf} && $dic->{dbf}->opened);
  delete($dic->{dbf});
  return $dic;
}


##==============================================================================
## Methods: Embedded API
##==============================================================================

## $bool = $dic->dictOk()
##  + returns false iff dict is undefined or "empty"
sub dictOk {
  return $_[0]{dbf} && $_[0]{dbf}->opened;
}

## \%key2val = $dict->dictHash()
##   + returns a (possibly tie()d hash) representing dict contents
##   + override returns $dict->{dbf}{data} or a new empty hash
sub dictHash {
  return $_[0]{dbf} && $_[0]{dbf}->opened ? $_[0]{dbf}{data} : {};
}

## $val_or_undef = $dict->dictLookup($key)
##  + get stored value for key $key
##  + default returns $dict->{ttd}{dict}{$key} or undef
sub dictLookup {
  return undef if (!$_[0]{dbf} || !$_[0]{dbf}->opened);
#  return decode($_[0]{dbEncoding}, $_[0]{dbf}{data}{encode($_[0]{dbEncoding},$_[1])})
#    if (defined($_[0]{dbEncoding}));
  return $_[0]{dbf}{data}{$_[1]};
}


##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $dic->ensureLoaded()
##  + ensures analyzer data is loaded from default files
sub ensureLoaded {
  my $dic = shift;
  my $rc  = 1;
  if ( defined($dic->{dictFile}) && !$dic->dictOk ) {
    $dic->info("opening DB file '$dic->{dictFile}'");
    $dic->{dbf} = Lingua::TT::DBFile->new(%{$dic->{dba}||{}});
    $rc &&= $dic->{dbf}->open($dic->{dictFile}, encoding=>$dic->{encoding});

    ##-- setup filters
    if ($rc && (!$dic->{encoding} || $dic->{encoding} eq 'raw')) {
      my $dbf  = $dic->{dbf};
      my $tied = $dic->{dbf}{tied};
      if ($dic->{keyEncoding} && $dic->{keyEncoding} ne 'raw') {
	$tied->filter_fetch_key($dbf->encFilterFetch($dic->{keyEncoding}));
	$tied->filter_store_key($dbf->encFilterStore($dic->{keyEncoding}));
      }
      if ($dic->{valEncoding} && $dic->{valEncoding} ne 'raw') {
	$tied->filter_fetch_value($dbf->encFilterFetch($dic->{valEncoding}));
	$tied->filter_store_value($dbf->encFilterStore($dic->{valEncoding}));
      }
    }
  }
  $dic->logwarn("error opening file '$dic->{dictFile}': $!") if (!$rc);
  return $rc;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

##======================================================================
## Methods: Persistence: Perl

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
sub noSaveKeys {
  my $that = shift;
  return ($that->SUPER::noSaveKeys, qw(dbf));
}

## @keys = $class_or_obj->noSaveBinKeys()
##  + returns list of keys not to be saved
sub noSaveBinKeys {
  my $that = shift;
  return ($that->SUPER::noSaveBinKeys, qw(dbf));
}

## $saveRef = $obj->savePerlRef()
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + implicitly calls $obj->clear()
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  return $obj;
}

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $anl->canAnalyze()
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
##  + INHERITED from dict: calls dictOk()

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
##  + INHERITED from Dict


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Dict::BDB - generic analysis dictionary API using Lingua::TT::DBFile

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::Dict::BDB;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 $dic = $dic->clear();
 
 ##========================================================================
 ## Methods: Embedded API
 
 $bool = $dic->dictOk();
 \%key2val = $dict->dictHash();
 $val_or_undef = $dict->dictLookup($key);
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $dic->ensureLoaded();
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict::BDB: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::Dict::BDB
inherits from L<DTA::CAB::Analyzer::Dict|DTA::CAB::Analyzer::Dict>
and supports the L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> API.
This module uses Lingua::TT::DBFile to implement a static
finite dictionary stored in a Berkeley DB file.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict::BDB: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

%$obj, %args:

 ##-- Filename Options
 dictFile => $filename,    ##-- DB filename (default=undef)
 ##
 ##-- Analysis Output
 label          => $lab,   ##-- analyzer label
 analyzeCode    => $code,  ##-- pseudo-accessor code for analyzeing token $_
 ##
 ##-- Analysis Options
 encoding       => $enc,   ##-- encoding of db file (default='UTF-8'): clobbers $dba{encoding}
 ##
 ##-- Analysis objects
 dbf => $dbf,              ##-- underlying Lingua::TT::DBFile object (default=undef)
 dba => \%dba,             ##-- args for Lingua::TT::DBFile->new()
 #={
 #  mode    => $mode,      ##-- default: 0644
 #  flags   => $flags,     ##-- default: O_RDONLY
 #  type    => $type,      ##-- one of 'HASH', 'BTREE', 'RECNO', 'GUESS' (default: 'GUESS')
 #  dbinfo  => \%dbinfo,   ##-- default: "DB_File::${type}INFO"->new();
 #  dbopts  => \%opts,     ##-- db options (e.g. cachesize,bval,...) -- defaults to none (uses DB_File defaults)
 # }


=item clear

 $dic = $dic->clear();

Overriude just closes db.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict::BDB: Methods: Embedded API
=pod

=head2 Methods: Embedded API

=over 4

=item dictOk

 $bool = $dic->dictOk();

Should returns false iff dict is undefined or "empty".
Override just checks whether the underlying DB file has been
successfully opened.

=item dictHash

 \%key2val = $dict->dictHash();

Returns a (possibly tie()d hash) representing dict contents.
Override returns $dict-E<gt>{dbf}{data} or a new empty hash.

=item dictLookup

 $val_or_undef = $dict->dictLookup($key);

Get stored value for key $key, if any.
Default returns $dict-E<gt>{ttd}{dict}{$key} or undef.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict::BDB: Methods: I/O: Input: all
=pod

=head2 Methods: I/O

=over 4

=item ensureLoaded

 $bool = $dic->ensureLoaded();

Ensures analyzer data is loaded from default files.
Override instantiates $dic-E<gt>{dbf} as a new Lingua::TT::DBFile object.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dict::BDB: Methods: Persistence: Perl
=pod

=head2 Methods: Persistence: Perl

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved.
Default adds qw(dbf) to superclass list.

=item loadPerlRef

 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);

Load object data from a perl reference.
Probably a dangerous thing to do on an open DB.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl
=pod



=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<DTA::CAB::Analyzer::Dict(3pm)|DTA::CAB::Analyzer::Dict>,
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
