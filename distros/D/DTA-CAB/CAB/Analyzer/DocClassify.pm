## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::DocClassify.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: DocClassify::Mapper wrapper

package DTA::CAB::Analyzer::DocClassify;
use DTA::CAB::Analyzer;
use DTA::CAB::Datum ':all';
use DocClassify;

use Encode qw(encode decode);
use IO::File;
use Carp;

use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Analyzer);

##==============================================================================
## Constructors etc.
##==============================================================================

## $obj = CLASS_OR_OBJ->new(%args)
##  + object structure:
##    (
##     ##-- Filename Options
##     mapFile => $filename,     ##-- binary source file for 'map' (default: none) : REQUIRED
##
##     ##-- Analysis Options
##     label            => $label, ##-- document destination key (default='classified')
##     analyzeClearBody => $bool,  ##-- if true, document analysis routine will wipe $doc->{body} (default=false)
##
##     ##-- Analysis Objects
##     map            => $map,   ##-- a DocClassify::Mapper object
##    )
sub new {
  my $that = shift;
  my $dc = $that->SUPER::new(
			      ##-- filenames
			      mapFile => undef,

			      ##-- options
			      label => 'classified',
			      analyzeClearBody => 0,

			      ##-- analysis objects
			      #map => undef,

			      ##-- user args
			      @_
	     );
  return $dc;
}

## $dc = $dc->clear()
sub clear {
  my $dc = shift;

  ##-- analysis sub(s)
  $dc->dropClosures();

  ##-- analysis objects
  delete($dc->{map});

  return $dc;
}

##==============================================================================
## Methods: Generic
##==============================================================================

## $bool = $dc->mapOk()
##  + should return false iff map is undefined or "empty"
##  + default version checks for non-empty 'map'
sub mapOk {
  return defined($_[0]{map});
}

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $dc->ensureLoaded()
##  + ensures model data is loaded from default files (if available)
sub ensureLoaded {
  my $dc = shift;
  ##-- ensure: map
  if ( defined($dc->{mapFile}) && !$dc->mapOk ) {
    return $dc->loadMap($dc->{mapFile});
  }
  return 1; ##-- allow empty models
}

##--------------------------------------------------------------
## Methods: I/O: Input: Map

## $dc = $dc->loadMap($map_file)
sub loadMap {
  my ($dc,$mapfile) = @_;
  $dc->info("loading map file '$mapfile'");
  $dc->{map} = 'DocClassify::Mapper' if (!defined($dc->{map}));
  $dc->{map} = $dc->{map}->loadFile($mapfile)
    or $dc->logconfess("loadFile(): load failed for '$mapfile': $!");
  $dc->dropClosures();
  return $dc;
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
  return ($that->SUPER::noSaveKeys, qw(map));
}

## $saveRef = $obj->savePerlRef()
##  + inherited from DTA::CAB::Persistent

## $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref)
##  + implicitly calls $obj->clear()
sub loadPerlRef {
  my ($that,$ref) = @_;
  my $obj = $that->SUPER::loadPerlRef($ref);
  $obj->clear();
  return $obj;
}

##==============================================================================
## Methods: Analysis
##==============================================================================

##------------------------------------------------------------------------
## Methods: Analysis: Generic

## $bool = $anl->canAnalyze()
##  + returns true if analyzer can perform its function (e.g. data is loaded & non-empty)
sub canAnalyze {
  return $_[0]->mapOk();
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
sub analyzeDocument {
  my ($anl,$doc,$opts) = @_;
  return undef if (!$anl->ensureLoaded()); ##-- uh-oh...
  return $doc if (!$anl->canAnalyze);      ##-- ok...
  $doc = toDocument($doc);

  ##-- vars
  my $dc     = $anl; ##-- hack
  my $lab    = $dc->{label};

  my $map = $dc->{map};
  my $dcdoc = $dc->{_dcdoc} = DocClassify::Document->new(string=>"<doc type=\"dummy\" src=\"$dc\"/>\n",label=>(ref($dc)." dummy document"));
  my $dcsig  = DocClassify::Signature->new();
  my $sig_tf = $dcsig->{tf};
  my $sig_Nr = \$dcsig->{N};

  ##-- populate signature from non-refs in tokens
  %$sig_tf = qw();
  $$sig_Nr = 0;
  my ($s,$w,$wkey);
  foreach $s (@{$doc->{body}}) {
    foreach $w (@{$s->{tokens}}) {
      $wkey = join("\t", map {"$_=$w->{$_}"} grep {!ref($w->{$_})} sort keys(%$w));
      $sig_tf->{$wkey}++;
      $$sig_Nr++;
    }
  }

  ##-- map & annotate
  $dcdoc->{sig} = $dcsig;
  $map->mapDocument($dcdoc);
  $doc->{$dc->{label}} = [ $dcdoc->cats() ];
  @{$doc->{body}} = qw() if ($dc->{analyzeClearBody});

  ##-- cleanup
  @{$dcdoc->{cats}} = qw();
  $dcdoc->clearCache();
  $dcsig->clear();

  ##-- return
  return $doc;
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::DocClassify - DocClassify::Mapper wrapper

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::DocClassify;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 $dc = $dc->clear();
 
 ##========================================================================
 ## Methods: Generic
 
 $bool = $dc->mapOk();
 
 ##========================================================================
 ## Methods: I/O: Input: all
 
 $bool = $dc->ensureLoaded();
 
 ##========================================================================
 ## Methods: I/O: Input: Map
 
 $dc = $dc->loadMap($map_file);
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 
 ##========================================================================
 ## Methods: Analysis: Generic
 
 $bool = $anl->canAnalyze();
 
 ##========================================================================
 ## Methods: Analysis: v1.x: API
 
 $doc = $anl->analyzeDocument($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

object structure:

    (
     ##-- Filename Options
     mapFile => $filename,     ##-- binary source file for 'map' (default: none) : REQUIRED
     ##-- Analysis Options
     label            => $label, ##-- document destination key (default='classified')
     analyzeClearBody => $bool,  ##-- if true, document analysis routine will wipe $doc->{body} (default=false)
     ##-- Analysis Objects
     map            => $map,   ##-- a DocClassify::Mapper object
    )

=item clear

 $dc = $dc->clear();

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: Generic
=pod

=head2 Methods: Generic

=over 4

=item mapOk

 $bool = $dc->mapOk();


=over 4


=item *

should return false iff map is undefined or "empty"

=item *

default version checks for non-empty 'map'

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: I/O: Input: all
=pod

=head2 Methods: I/O: Input: all

=over 4

=item ensureLoaded

 $bool = $dc->ensureLoaded();

ensures model data is loaded from default files (if available)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: I/O: Input: Map
=pod

=head2 Methods: I/O: Input: Map

=over 4

=item loadMap

 $dc = $dc->loadMap($map_file);

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: Persistence: Perl
=pod

=head2 Methods: Persistence: Perl

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

returns list of keys not to be saved

=item loadPerlRef

 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);

implicitly calls $obj-E<gt>clear()

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: Analysis: Generic
=pod

=head2 Methods: Analysis: Generic

=over 4

=item canAnalyze

 $bool = $anl->canAnalyze();

returns true if analyzer can perform its function (e.g. data is loaded & non-empty)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::DocClassify: Methods: Analysis: v1.x: API
=pod

=head2 Methods: Analysis: v1.x: API

=over 4

=item analyzeDocument

 $doc = $anl->analyzeDocument($doc,\%opts);


=over 4


=item *

analyze a DTA::CAB::Document $doc

=item *

top-level API routine

=back

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
L<DTA::CAB::Analyzer(3pm)|DTA::CAB::Analyzer>,
L<DTA::CAB::Chain(3pm)|DTA::CAB::Chain>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<perl(1)|perl>,
...



=cut
