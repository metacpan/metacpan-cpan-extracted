## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::ExpandList.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum formatter: lemma-list (closed classes) or best-lemma (open classes) for use with DDC

package DTA::CAB::Format::LemmaList;
use DTA::CAB::Format;
use DTA::CAB::Format::TT;
use DTA::CAB::Format::ExpandList;
use DTA::CAB::Datum ':all';
use IO::File;
use Encode qw(encode decode);
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::ExpandList);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, filenameRegex=>qr/\.(?i:ll|llist|lemma)/)
      foreach (qw(LemmaList llist ll lemma));

  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_, opts=>{cctagre=>''})
      foreach (qw(LemmaListAll LemmasAll llist-all ll-all lla lemmas lemmata));
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
##     keys      => \@expandKeys,      ##-- IGNORED: keys to include (default: [qw(text xlit eqpho eqrw eqlemma eqtagh gn-syn gn-isa gn-asi ot-syn ot-isa ot-asi)])
##     cctagre   => $cctagre,          ##-- regex matching closed-class tags (default='^(?:[CKP\$]|A[PR]|V[AM])', for STTS)
##
##
##     ##---- Common
##     utf8  => $bool,                 ##-- default: 1
##     defaultFieldName => $name,      ##-- default name for unnamed fields; parsed into @{$tok->{other}{$name}}; default=''
##    )
## + inherited from DTA::CAB::Format::TT
sub new {
  my $that = shift;
  my $obj  = $that->SUPER::new(
			       keys=>[],
			       cctagre=>'^(?:[CKP\$]|A[PR]|V[AM])',
			       @_);

  return $obj;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved: qw(doc outbuf)
##  + inherited from DTA::CAB::Format::TT
sub noSaveKeys {
  my $that = shift;
  return ($that->SUPER::noSaveKeys(), 'cctagre');
}

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
sub defaultExtension { return '.ll'; }

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
  my $cctagre = $fmt->{cctagre} // '';
  $cctagre = qr{$cctagre} if (!ref($cctagre));

  return $fmt if (!$tok->{moot});
  my (@lemmas);

  if ($tok->{moot}{tag} =~ $cctagre) {
    ##-- closed-class word: return all lemmata
    my $tmp='';
    @lemmas = (
	       map {$tmp eq $_ ? qw() : ($tmp=$_)}
	       sort
	       grep {defined($_) && $_ ne ''}
	       map { $_->{lemma} }
	       $tok->{moot},
	       @{$tok->{moot}{analyses}//[]}
	      );
  } else {
    ##-- lexical word: return only best lemma
    @lemmas = ($tok->{moot}{lemma});
  }

  $fmt->{fh}->print(join($sep, ($level > 0 ? sort(@lemmas) : @lemmas)), "\n");
  return $fmt;
}

## $fmt = $fmt->putSentence($sent)
##  + concatenates formatted tokens *without* any sentence-comments
##  + INHERITED fromk ExpandList


1; ##-- be happy

__END__

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::LemmaLlist - Datum I/O: lemma-list for use with DDC

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::LemmaList;
 
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

DTA::CAB::Format::LemmaList
is a L<DTA::CAB::Format|DTA::CAB::Format> subclass
intended for use in a CAB HTTP server as a CAB-class term expander for the DDC corpus query engine.
As for L<DTA::CAB::Format::ExpandList|DTA::CAB::Format::ExpandList> (from which this class inherits),
each token is represented by a single line and sentence boundaries
are represented by blank lines.  Token lines have the format:

 ORIG_TEXT   LEMMA(s)...

Where C<LEMMA(s)> is a list of TAB-separated lemma form(s) as determined
by the analysis phase.  In contrast to the "BestLemmaList" format,
the LemmaList format returns B<all possible> lemmata for input words
assigned a closed-class tag, and only the B<best> lemma for all other words.
"Closed-class" tags in this sense are tags matching the regex given
as the format object's C<cctagre> option, which is defined by default
for the STTS tagset as:

 ^(?:[CKP$]|A[PR]|V[AM])


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
 cctagre    => $cctagre,         ##-- regex matching closed-class tags (default='^(?:[CKP\$]|A[PR]|V[AM])', for STTS)
 
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

Copyright (C) 2016-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<dta-cab-analyze.perl(1)|dta-cab-analyze.perl>,
L<dta-cab-convert.perl(1)|dta-cab-convert.perl>,
L<DTA::CAB::Format::ExpandList(3pm)|DTA::CAB::Format::ExpandList>,
L<DTA::CAB::Format::TT(3pm)|DTA::CAB::Format::TT>,
L<DTA::CAB::Format(3pm)|DTA::CAB::Format>,
L<DTA::CAB(3pm)|DTA::CAB>,
L<ddc_opt(5)|ddc_opt>,
L<ddc_proto(5)|ddc_proto>,
L<perl(1)|perl>,
...

=cut
