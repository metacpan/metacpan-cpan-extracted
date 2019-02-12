## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::LangId.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Lingua::LangId::Map wrapper

package DTA::CAB::Analyzer::LangId;
use DTA::CAB::Analyzer;
use DTA::CAB::Datum ':all';
use Lingua::LangId::Map;

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
##     mapFile => $filename,     ##-- default: none (REQUIRED)
##
##     ##-- Analysis Options
##     analyzeWhich     => $which, ##-- one of 'token', 'sentence', 'document'; default='document'
##     vlabel           => $label, ##-- verbose destination key (default='langid')
##     label            => $label, ##-- simple destination key (default='lang')
##
##
##     ##-- Analysis Objects
##     map            => $map,   ##-- a Lingua::LangId::Map object
##    )
sub new {
  my $that = shift;
  my $lid = $that->SUPER::new(
			       ##-- filenames
			       mapFile => undef,

			       ##-- options
			       analyzeWhich => 'document',
			       vlabel       => 'langid',
			       label        => 'lang',

			       ##-- analysis objects
			       #map => undef,

			       ##-- user args
			       @_
			      );
  return $lid;
}

## $lid = $lid->clear()
sub clear {
  my $lid = shift;

  ##-- analysis sub(s)
  $lid->dropClosures();

  ##-- analysis objects
  delete($lid->{map});

  return $lid;
}

##==============================================================================
## Methods: Generic
##==============================================================================

## $bool = $lid->mapOk()
##  + should return false iff map is undefined or "empty"
##  + default version checks for non-empty 'map' and 'sigs'
sub mapOk {
  return defined($_[0]{map}) && %{$_[0]{map}{sigs}};
}

## @keys = $anl->typeKeys(\%opts)
##  + returns list of type-wise keys to be expanded for this analyzer by expandTypes()
##  + default returns @{$anl->{typeKeys}} if defined, otherwise ($anl->{label})
sub typeKeys {
  return ($_[0]{typeKeys} ? @{$_[0]{typeKeys}} : qw());
}

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $lid->ensureLoaded()
##  + ensures model data is loaded from default files (if available)
sub ensureLoaded {
  my $lid = shift;
  ##-- ensure: map
  if ( defined($lid->{mapFile}) && !$lid->mapOk ) {
    return $lid->loadMap($lid->{mapFile});
  }
  return 1; ##-- allow empty models
}

##--------------------------------------------------------------
## Methods: I/O: Input: Map

## $lid = $lid->loadMap($map_file)
sub loadMap {
  my ($lid,$mapfile) = @_;
  $lid->info("loading map file '$mapfile'");
  if (!defined($lid->{map})) {
    $lid->{map} = Lingua::LangId::Map->new()
      or $lid->logconfess("could not create map object: $!");
  }
  $lid->{map}->loadBinFile($mapfile)
    or $lid->logconfess("loadMap(): load failed for '$mapfile': $!");
  $lid->dropClosures();
  return $lid;
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
## Methods: Analysis: Generic

## $thingy = $lid->analyzeThingy($thingy, \$str, \%opts)
sub analyzeThingy {
  my ($lid,$thingy,$ref,$opts) = @_;
  my $details = $lid->{map}->applyString($ref);
  $thingy->{$lid->{vlabel}} = $details if (defined($lid->{vlabel}));
  if (defined($lid->{label})) {
    my $best = (sort {$details->{$a}{kldp} <=> $details->{$b}{kldp}} grep {$details->{$_}{match}} keys %$details)[0];
    $thingy->{$lid->{label}} = $best if (defined($best));
  }
  return $thingy;
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
sub analyzeLocal {
  my ($anl,$doc,$opts) = @_;
  return undef if (!$anl->ensureLoaded()); ##-- uh-oh...
  return $doc if (!$anl->canAnalyze);      ##-- ok...

  my $xlit = sub { $_[0]{xlit} ? $_[0]{xlit}{latin1Text} : $_[0]{text} };
  my ($str,$x);
  if ($anl->{analyzeWhich} eq 'document') {
    $str = join(' ', map {$xlit->($_)} map {@{$_->{tokens}}} @{$doc->{body}});
    $anl->analyzeThingy($doc,\$str,$opts);
  }
  elsif ($anl->{analyzeWhich} eq 'sentence') {
    foreach $x (@{$doc->{body}}) {
      $str = join(' ', map {$xlit->($_)} @{$x->{tokens}});
      $anl->analyzeThingy($x,\$str,$opts);
    }
  }
  elsif ($anl->{analyzeWhich} eq 'token' || $anl->{analyzeWhich} eq 'type') {
    foreach $x (map {@{$_->{tokens}}} @{$doc->{body}}) {
      $str = $xlit->($x);
      $anl->analyzeThingy($x,\$str,$opts);
    }
  }
  else {
    $anl->logconfess("analyzeDocument(): unknown {analyzeWhich}='$anl->{analyzeWhich}'");
  }
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

DTA::CAB::Analyzer::LangId - Lingua::LangId::Map wrapper

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DTA::CAB::Analyzer::LangId;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 $lid = $lid->clear();
 
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $lid->mapOk();
 $bool = $lid->ensureLoaded();
 $lid = $lid->loadMap($map_file);
 
 ##========================================================================
 ## Methods: Persistence: Perl
 
 @keys = $class_or_obj->noSaveKeys();
 $loadedObj = $CLASS_OR_OBJ->loadPerlRef($ref);
 
 ##========================================================================
 ## Methods: Analysis
 
 $bool = $anl->canAnalyze();
 $thingy = $lid->analyzeThingy($thingy, \$str, \%opts);
 $doc = $anl->analyzeDocument($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Analyzer::LangId provides a
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>
interface to the L<Lingua::LangId|Lingua::LangId>
language-guessing library.
Its current implementation only has proof-of-concept status.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Analyzer::LangId
inherits from L<DTA::CAB::Analyzer|DTA::CAB::Analyzer>
and implements the L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> API.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

object structure:

    (
     ##-- Filename Options
     mapFile => $filename,     ##-- default: none (REQUIRED)
     ##-- Analysis Options
     analyzeWhich     => $which, ##-- one of 'token', 'sentence', 'document'; default='document'
     vlabel           => $label, ##-- verbose destination key (default='langid')
     label            => $label, ##-- simple destination key (default='lang')
     ##-- Analysis Objects
     map            => $map,   ##-- a Lingua::LangId::Map object
    )

=item clear

 $lid = $lid->clear();

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: Generic
=pod

=head2 Methods: Generic

=over 4

=item mapOk

 $bool = $lid->mapOk();


=over 4


=item *

should return false iff map is undefined or "empty"

=item *

default version checks for non-empty 'map' and 'sigs'

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: I/O: Input: all
=pod

=head2 Methods: I/O: Input: all

=over 4

=item ensureLoaded

 $bool = $lid->ensureLoaded();

ensures model data is loaded from default files (if available)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: I/O: Input: Map
=pod

=head2 Methods: I/O: Input: Map

=over 4

=item loadMap

 $lid = $lid->loadMap($map_file);

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: Persistence: Perl
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
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: Analysis: Generic
=pod

=head2 Methods: Analysis: Generic

=over 4

=item canAnalyze

 $bool = $anl->canAnalyze();

returns true if analyzer can perform its function (e.g. data is loaded & non-empty)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: Analysis: Generic
=pod

=head2 Methods: Analysis: Generic

=over 4

=item analyzeThingy

 $thingy = $lid->analyzeThingy($thingy, \$str, \%opts);

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::LangId: Methods: Analysis: v1.x: API
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
