## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Analyzer::Dyn.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic analyzer API: dynamic code generation

package DTA::CAB::Analyzer::Dyn;
use DTA::CAB::Analyzer;
use DTA::CAB::Utils;
use DTA::CAB::Datum ':all';
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
##  + object structure, new
##    (
##     ##-- code generation options
##     analyze${Which}Code => $str,  ##-- code for analyze${Which} method
##
##     ##-- generated code
##     analyze${Which}Sub => \&sub,  ##-- compiled code for analyze${Which} method
##    )
sub new {
  my $that = shift;
  return $that->SUPER::new(@_);
}

## undef = $anl->dropClosures();
##  + drops 'analyze${which}' closures
##  + currently does nothing
sub dropClosures {
  my $anl = shift;
  my ($which);
  foreach $which (qw(Document Types Tokens Sentences Local Clean)) {
    delete($anl->{"analyze${which}"});
  }
  return $anl->SUPER::dropClosures(@_);
}

##==============================================================================
## Methods: I/O
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Input: all

## $bool = $anl->prepare()
## $bool = $anl->prepare(\%opts)
##  + inherited: wrapper for ensureLoaded(), autoEnable(), initInfo()
##  + override appends ensureDynSubs() call
sub prepare {
  my $anl = shift;
  $anl->SUPER::prepare() || return 0;
  $anl->ensureDynSubs() || return 0;
  $anl->analyzeDyn('Prepare',$anl,@_);
  return 1;
}

##==============================================================================
## Methods: Dynamic Closures

## $bool = $anl->ensureDynSubs()
##  + ensures subs are defined for all analyze${Which} methods
sub ensureDynSubs {
  my $anl = shift;
  my ($which,$sub);
  foreach $which (qw(Prepare Document Types Tokens Sentences Local Clean)) {
    $anl->{"analyze${which}"} = $anl->compileDynSub($which) if (!UNIVERSAL::isa($anl->{"analyze${which}"},'CODE'));
    if (!UNIVERSAL::isa($anl->{"analyze${which}"},'CODE')) {
      $anl->logcluck("ensureDynSubs(): no analysis sub for '$which'");
    }
  }
  return 1;
}

## \&sub = $anl->compileDynSub($which)
##  + returns compiled analyze${Which} sub
sub compileDynSub {
  my ($anl,$which) = @_;
  my ($code);
  if (defined($code=$anl->dynSubCode($which))) {
    my $sub = eval $code;
    $anl->logcluck("compileDynSub($which): could not compile analysis sub {$code}: $@") if (!$sub);
    return $sub;
  }
  return DTA::CAB::Analyzer->can("analyze${which}"); ##-- default: just wrap superclass method
}

## $code = $anl->dynSubCode($which)
##  + returns code for analyze${Which} sub
sub dynSubCode {
  my ($anl,$which) = @_;
  return $anl->{"analyze${which}Code"} if (defined($anl->{"analyze${which}Code"}));
  return undef;
}

## undef = dumpPackage(%opts)
##  + %opts:
##     file => $file_or_handle,
##     package => $pkgname,
sub dumpPackage {
  my ($anl,%opts) = @_;
  $opts{file} = '-' if (!defined($opts{file}));
  my $fh = ref($opts{file}) ? $opts{file} : IO::File->new(">$opts{file}");
  $anl->logdie("open failed for '$opts{file}': $!") if (!defined($fh));

  $fh->print("package ".($opts{package} || (ref($anl) ."::dump")).";\n",
	     "use ", ref($anl), ";\n",
	     "our \@ISA = (", ref($anl), ");\n",
	    );
  my ($code,$which);
  foreach $which (qw(Document Types Tokens Sentences Local Clean)) {
    if (defined($code=$anl->dynSubCode($which))) {
      $code =~ s/^\s*sub/sub analyze${which}/;
      $fh->print($code,"\n");
    }
  }
  $fh->print("1; ##-- be happy\n");
  $fh->close() if (!ref($opts{file}));
}

##==============================================================================
## Methods: Analysis: v1.x

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API: Dyn

## $rc = $anl->analyzeDyn($which,@args)
##  + wrapper for $anl->{"analyze${which}"}->(@args)
sub analyzeDyn {
  return $_[0]->{"analyze$_[1]"}->(@_[2..$#_]) if (UNIVERSAL::isa($_[0]->{"analyze$_[1]"},'CODE'));
  return undef;
}

##------------------------------------------------------------------------
## Methods: Analysis: v1.x: API

## $doc = $anl->analyzeDocument($doc,\%opts)
##  + analyze a DTA::CAB::Document $doc
##  + top-level API routine
sub analyzeDocument { return $_[0]->analyzeDyn('Document',@_); }

## $doc = $anl->analyzeTypes($doc,\%types,\%opts)
##  + perform type-wise analysis of all (text) types in $doc->{types}
sub analyzeTypes { return $_[0]->analyzeDyn('Types',@_); }

## $doc = $anl->analyzeTokens($doc,\%opts)
##  + perform token-wise analysis of all tokens $doc->{body}[$si]{tokens}[$wi]
sub analyzeTokens { return $_[0]->analyzeDyn('Tokens',@_); }

## $doc = $anl->analyzeSentences($doc,\%opts)
##  + perform sentence-wise analysis of all sentences $doc->{body}[$si]
sub analyzeSentences { return $_[0]->analyzeDyn('Sentences',@_); }

## $doc = $anl->analyzeLocal($doc,\%opts)
##  + perform analyzer-local document-level analysis of $doc
sub analyzeLocal { return $_[0]->analyzeDyn('Local',@_); }

## $doc = $anl->analyzeClean($doc,\%opts)
##  + cleanup any temporary data associated with $doc
sub analyzeClean { return $_[0]->analyzeDyn('Clean',@_); }


1; ##-- be happy

__END__
##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl
=pod

=cut

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Analyzer::Dyn - generic analyzer API: dynamic code generation

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Analyzer::Dyn;
 
 ##========================================================================
 ## Constructors etc.
 
 $obj = CLASS_OR_OBJ->new(%args);
 undef = $anl->dropClosures();
 
 ##========================================================================
 ## Methods: I/O
 
 $bool = $anl->prepare();
 
 ##========================================================================
 ## Methods: Dynamic Closures
 
 $bool = $anl->ensureDynSubs();
 \&sub = $anl->compileDynSub($which);
 $code = $anl->dynSubCode($which);
 undef = dumpPackage(%opts);
 
 ##========================================================================
 ## Methods: Analysis: API: Dyn
 
 $rc = $anl->analyzeDyn($which,@args);
 
 ##========================================================================
 ## Methods: Analysis: API
 
 $doc = $anl->analyzeDocument($doc,\%opts);
 $doc = $anl->analyzeTypes($doc,\%types,\%opts);
 $doc = $anl->analyzeTokens($doc,\%opts);
 $doc = $anl->analyzeSentences($doc,\%opts);
 $doc = $anl->analyzeLocal($doc,\%opts);
 $doc = $anl->analyzeClean($doc,\%opts);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

B<UNMAINTAINED>

This module provides a
L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> subclass
using dynamically generated closures to implement
the L<DTA::CAB::Analyzer|DTA::CAB::Analyzer> analysis API.
In theory, this should be faster than on-the-fly compilation
of accessor strings, etc, but is a serious pain in the posterior
to debug.

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

(undocumented)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $obj = CLASS_OR_OBJ->new(%args);

object structure, new

    (
     ##-- code generation options
     analyze${Which}Code => $str,  ##-- code for analyze${Which} method
     ##-- generated code
     analyze${Which}Sub => \&sub,  ##-- compiled code for analyze${Which} method
    )

=item dropClosures

 undef = $anl->dropClosures();


=over 4


=item *

drops 'analyze${which}' closures

=item *

currently does nothing

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Methods: I/O: Input: all
=pod

=head2 Methods: I/O: Input: all

=over 4

=item prepare

 $bool = $anl->prepare();
 $bool = $anl->prepare(\%opts)

=over 4


=item *

inherited: wrapper for ensureLoaded(), autoEnable(), initInfo()

=item *

override appends ensureDynSubs() call

=back

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Methods: Dynamic Closures
=pod

=head2 Methods: Dynamic Closures

=over 4

=item ensureDynSubs

 $bool = $anl->ensureDynSubs();

ensures subs are defined for all analyze${Which} methods

=item compileDynSub

 \&sub = $anl->compileDynSub($which);

returns compiled analyze${Which} sub

=item dynSubCode

 $code = $anl->dynSubCode($which);

returns code for analyze${Which} sub

=item dumpPackage

 undef = dumpPackage(%opts);

%opts:

 file => $file_or_handle,
 package => $pkgname,

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Methods: Analysis: API: Dyn
=pod

=head2 Methods: Analysis: API: Dyn

=over 4

=item analyzeDyn

 $rc = $anl->analyzeDyn($which,@args);

wrapper for $anl-E<gt>{"analyze${which}"}-E<gt>(@args)

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Analyzer::Dyn: Methods: Analysis: API
=pod

=head2 Methods: Analysis: API

=over 4

=item analyzeDocument

 $doc = $anl->analyzeDocument($doc,\%opts);

analyze a DTA::CAB::Document $doc

=item analyzeTypes

 $doc = $anl->analyzeTypes($doc,\%types,\%opts);

perform type-wise analysis of all (text) types in $doc-E<gt>{types}

=item analyzeTokens

 $doc = $anl->analyzeTokens($doc,\%opts);

perform token-wise analysis of all tokens $doc-E<gt>{body}[$si]{tokens}[$wi]

=item analyzeSentences

 $doc = $anl->analyzeSentences($doc,\%opts);

perform sentence-wise analysis of all sentences $doc-E<gt>{body}[$si]

=item analyzeLocal

 $doc = $anl->analyzeLocal($doc,\%opts);

perform analyzer-local document-level analysis of $doc

=item analyzeClean

 $doc = $anl->analyzeClean($doc,\%opts);

cleanup any temporary data associated with $doc

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
