## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::ExpandList.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum formatter: expansion list for use with DDC

package DTA::CAB::Format::ExpandList;
use DTA::CAB::Format;
use DTA::CAB::Format::TT;
use DTA::CAB::Datum ':all';
use DTA::CAB::Utils ':data'; ##-- path_value()
use IO::File;
use Encode qw(encode decode);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::TT);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:xl|xlist|l|lst)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'xl');
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>'xlist');
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{keys=>[[qw(moot lemma)]]})
      foreach (qw(BestLemmaList BestLemma bllist bll bl bestlemma blemma lemma));
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    (
##     ##---- Input
##     doc => $doc,                    ##-- buffered input document (TT-style)
##
##     ##---- Output
##     level    => $formatLevel,      ##-- output formatting level:
##				      ##   0:TAB-separated (default); 1:sorted,NEWLINE-separated; 2:sorted,NEWLINE+TAB separated
##     #outbuf    => $stringBuffer,     ##-- buffered output
##     keys      => \@expandKeys,      ##-- keys to include (default: [qw(text xlit eqpho eqrw eqlemma eqtagh gn-syn gn-isa gn-asi ot-syn ot-isa ot-asi)])
##
##     ##---- Common
##     utf8  => $bool,                 ##-- default: 1
##     defaultFieldName => $name,      ##-- default name for unnamed fields; parsed into @{$tok->{other}{$name}}; default=''
##    )
## + inherited from DTA::CAB::Format::TT
sub new {
  my $that = shift;
  my $obj  = $that->SUPER::new(keys=>[qw(text xlit eqpho eqrw eqlemma eqtagh gn-syn gn-isa gn-asi ot-syn ot-isa ot-asi)],@_);
  $obj->{keys} = [grep {($_//'') ne ''} split(/[\s\,]+/, $obj->{keys})] if (!ref($obj->{keys}));
  return $obj;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved: qw(doc outbuf)
##  + inherited from DTA::CAB::Format::TT

##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->close()
##  + inherited from DTA::CAB::Format::TT

## $fmt = $fmt->fromFile($filename_or_handle)
##  + default calls $fmt->fromFh()

## $fmt = $fmt->fromFh($fh)
##  + default calls $fmt->fromString() on file contents

## $fmt = $fmt->fromString($string)
##  + wrapper for: $fmt->close->parseTTString($_[0])
##  + inherited from DTA::CAB::Format::TT
##  + name is aliased here to parseTextString() !

##--------------------------------------------------------------
## Methods: Input: Local
# (none)

##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##  + just returns $fmt->{doc}
##  + inherited from DTA::CAB::Format::TT


##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + default returns text/plain
sub mimeType { return 'text/plain'; }

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.xl'; }

##--------------------------------------------------------------
## Methods: Output: output selection

##--------------------------------------------------------------
## Methods: Output: Generic API

## $fmt = $fmt->putToken($tok)
##  + appends $tok to $fmt->{fh}
sub putToken {
  my ($fmt,$tok) = @_;
  my $level = $fmt->{level}||0;
  my $sep = ($level>=2 ? "\n\t"
	     : ($level>=1 ? "\n"
		: "\t"));
  my @words = (
	       grep {defined($_) && $_ ne ''}
	       map {
		 (UNIVERSAL::isa($_,'HASH')
		  ? (exists($_->{hi})
		     ? $_->{hi}
		     : (exists($_->{latin1Text}) ? $_->{latin1Text} : $_))
		  : $_)
	       }
	       map {UNIVERSAL::isa($_,'ARRAY') ? @$_ : $_}
	       map {path_value($tok,$_)}
	       @{$fmt->{keys}}
	      );

  $fmt->{fh}->print(join($sep, ($level > 0 ? sort(@words) : @words)), "\n");
  return $fmt;
}

## $fmt = $fmt->putSentence($sent)
##  + concatenates formatted tokens *without* any sentence-comments
sub putSentence {
  my ($fmt,$sent) = @_;
  $fmt->putToken($_) foreach (@{toSentence($sent)->{tokens}});
  $fmt->{fh}->print("\n");
  return $fmt;
}


1; ##-- be happy

__END__

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::ExpandList - Datum I/O: expansion list for use with DDC

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::ExpandList;
 
 ##========================================================================
 ## Methods: Constructors etc.
 
 $fmt = CLASS_OR_OBJ->new(%args)
 
 ##========================================================================
 ## Methods: Output
 
 $type = $fmt->mimeType();
 $ext = $fmt->defaultExtension();
 $fmt = $fmt->putToken($tok);
 

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::ExpandList
is a L<DTA::CAB::Format|DTA::CAB::Format> subclass
intended for use in a CAB HTTP server as a CAB-class term expander for the DDC corpus query engine.
As for L<DTA::CAB::Format::TT|DTA::CAB::Format::TT> (from which this class inherits),
each token is represented by a single line and sentence boundaries
are represented by blank lines.  Token lines have the format:

 ORIG_TEXT   EQUIVALENT(s)...

Where C<EQUIVALENT(s)> is a list of TAB-separated equivalent forms as determined
by the analysis phase.


=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CSV: Methods: Constructors etc.
=pod

=head2 Methods: Constructors etc.

=over 4

=item new

  $fmt = CLASS_OR_OBJECT->new(%args);

Recognized %args:

 ##---- Input
 doc => $doc,                    ##-- buffered input document
 
 ##---- Output
 level    => $formatLevel,       ##-- output formatting level
                                 ##   0: TAB-separated (default)
                                 ##   1: sorted, NEWLINE-separated
                                 ##   2: sorted, NEWLINE+TAB-separated
 keys      => \@expandKeys,      ##-- keys to include (default: [qw(text xlit eqpho eqrw eqlemma eqtagh gn-syn gn-isa gn-asi)])
 
 ##---- Common
 utf8  => $bool,                 ##-- default: 1

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::ExpandList: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item mimeType

 $type = $fmt->mimeType();

Default returns text/plain.

=item defaultExtension

 $ext = $fmt->defaultExtension();

Deturns default filename extension for this format.
Override returns '.xl'.

=item putToken

 $fmt = $fmt->putToken($tok);

Appends $tok to output buffer.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

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
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB::Format::TT(3pm)|DTA::CAB::Format::TT>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<ddc_opt(5)|ddc_opt>,
L<ddc_proto(5)|ddc_proto>,
L<perl(1)|perl>,
...

=cut
