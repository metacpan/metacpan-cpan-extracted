## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::TJ.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser: one-token-per-line text

package DTA::CAB::Format::TJ;
use DTA::CAB::Format;
use DTA::CAB::Datum ':all';
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::TT);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:tj|tjson|cab\-tj|cab\-tjson)$/);
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    {
##     ##-- Input
##     doc => $doc,                    ##-- buffered input document
##
##     ##-- Output
##     #outbuf  => $stringBuffer,     ##-- buffered output
##     level   => $formatLevel,      ##-- <0:no 'text' attribute; >=0: all attributes; abs($_)>=2: canonical
##
##     ##-- Common
##     raw => $bool,                   ##-- attempt to load/save raw data
##     defaultFieldName => $name,      ##-- default name for unnamed fields; parsed into @{$tok->{other}{$name}}; default=''
##    }

sub new {
  my $that = shift;
  my $fmt = bless({
		   ##-- input
		   doc => undef,

		   ##-- output
		   #outbuf => '',
		   level => 0,

		   ##-- common
		   utf8 => 1,
		   defaultFieldName => '',

		   ##-- user args
		   @_
		  }, ref($that)||$that);
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just returns empty list
sub noSaveKeys {
  return ($_[0]->SUPER::noSaveKeys, qw(doc outbuf jxs));
}

##==============================================================================
## Methods: I/O: Generic
##==============================================================================

## $jxs = $fmt->jsonxs()
sub jsonxs {
  require JSON::XS;
  return $_[0]{jxs} if (defined($_[0]{jxs}));
  return $_[0]{jxs} = JSON::XS->new->utf8(0)->relaxed(1)->canonical(abs($_[0]{level})>=2 ? 1 : 0)->allow_blessed(1)->convert_blessed(1);
}

##==============================================================================
## Methods: I/O: Block-wise
##==============================================================================

## \%head = blockScanHead(\$buf,\%opts)
##  + gets header offset, length from (mmaped) \$buf
##  + %opts are as for blockScan()
sub blockScanHead {
  my ($fmt,$bufr,$opts) = @_;
  return [0,$+[0]] if ($$bufr =~ m(\A\n*+(?:%%\$TJ:DOC=.*\n++)?));
  return [0,0];
}


##==============================================================================
## Methods: Input
##==============================================================================

##--------------------------------------------------------------
## Methods: Input: Input selection

## $fmt = $fmt->fromFh($filename_or_handle)
##  + new override calls Format::fromFh
sub fromFh {
  #return $_[0]->fromFh_str(@_[1..$#_]);
  my $fmt = shift;
  $fmt->DTA::CAB::Format::fromFh(@_)
    or $fmt->logconfess("fromFh(): inherited Format::fromFh() failed: $!");
  return $fmt->parseTJFh($_[0]);
}

## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
##  + new override calls Format::fromString() [-> fromFh]
sub fromString {
  my $fmt = shift;
  $fmt->close();
  #return $fmt->parseTJString(ref($_[0]) ? $_[0] : \$_[0]);
  return $fmt->DTA::CAB::Format::fromString(@_);
}

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseTJFh($fh)
##  + guts for fromFh(): parse handle $fh into local document buffer.
sub parseTJFh {
  my ($fmt,$fh) = @_;
  $fmt->setLayers($fh);
  my $jxs = $fmt->jsonxs();

  ##-- ye olde loope
  my (%sa,%doca);
  my $toks = [];
  my @body = qw();
  my ($tok,$text,$json);
  while (defined($_=<$fh>)) {
    if ($_ =~ /^\%\%\$TJ\:DOC=(.+)$/) {
      ##-- tj directive: document attributes
      $json = defined($1) && $1 ? $jxs->decode($1) : {};
      @doca{keys %$json} = values %$json;
    }
    elsif ($_ =~ /^\%\%\$TJ\:SENT=(.+)$/) {
      ##-- tj directive: sentence attributes
      $json = defined($1) && $1 ? $jxs->decode($1) : {};
      @sa{keys %$json} = values %$json;
    }
    elsif ($_ =~ /^\%\% (?:xml\:)?base=(.*)$/) {
      ##-- (tt-compat) special comment: document attribute: xml:base
      $doca{'base'} = $1;
    }
    elsif ($_ =~ /^\%\% Sentence (.*)$/) {
      ##-- (tt-compat) special comment: sentence attribute: xml:id
      $sa{'id'} = $1;
    }
    elsif ($_ =~ /^\%\%(.*)$/) {
      ##-- (tt-compat) generic line: add to _cmts
      push(@{$sa{_cmts}},$1); ##-- generic doc- or sentence-level comment
    }
    elsif ($_ =~ /^$/) {
      ##-- empty line: EOS
      if (%sa || @$toks) {
	push(@body,{%sa,tokens=>$toks});
	$toks = [];
	%sa   = qw();
      }
    }
    else {
      ##-- vanilla token
      chomp;
      ($text,$json) = split(/\t/,$_,2);
      push(@$toks, $tok = (defined($json) && $json ne '' ? $jxs->decode($json) : {}));
      $tok->{text}=$text if (!defined($tok->{text}));
    }
  }
  push(@body, {%sa,tokens=>$toks}) if (%sa || @$toks); ##-- handle missing EOS at EOF

  ##-- construct & buffer output document
  #$_ = bless($_,'DTA::CAB::Sentence') foreach (@$sents);
  $fmt->{doc} = bless({%doca,body=>\@body}, 'DTA::CAB::Document');
  return $fmt;
}


##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
sub parseDocument { return $_[0]{doc}; }


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
sub defaultExtension { return '.tj'; }

##--------------------------------------------------------------
## Methods: Output: output selection
##  + inherited


##--------------------------------------------------------------
## Methods: Output: Generic API

## $fmt = $fmt->putToken($tok)
sub putToken {
  #my ($fmt,$tok) = @_;

  $_[0]{fh}->print
    (
     ($_[1]{_cmts} ? join('', map {"%%$_\n"} map {split(/\n/,$_)} @{$_[1]{_cmts}}) : ''),
     $_[1]{text},
     "\t",
     $_[0]->jsonxs->encode(($_[0]{level}||0) >= 0
			   ? $_[1]
			   : {(map {$_ eq 'text' ? qw() : ($_=>$_[1]{$_})} keys %{$_[1]})}
			  ),
     "\n",
    );

  return $_[0];
}

## $fmt = $fmt->putSentence($sent)
##  + concatenates formatted tokens, adding sentence-id comment if available
sub putSentence {
  #my ($fmt,$sent) = @_;
  my $sh = {(map {$_ eq 'tokens' ? qw() : ($_=>$_[1]{$_})} keys %{$_[1]})};
  $_[0]{fh}->print('%%$TJ:SENT=', $_[0]->jsonxs->encode($sh), "\n") if (%$sh);
  $_[0]->putToken($_) foreach (@{toSentence($_[1])->{tokens}});
  $_[0]{fh}->print("\n");
  return $_[0];
}

## $fmt = $fmt->putDocument($doc)
##  + concatenates formatted sentences, adding document 'xmlbase' comment if available
our %TJ_BAD_DOC_KEYS = (body=>1, teibufr=>1, textbufr=>1);
sub putDocument {
  #my ($fmt,$doc) = @_;
  my $dh = { (map {($_=>$_[1]{$_})} grep {!exists($TJ_BAD_DOC_KEYS{$_})} keys %{$_[1]}) };
  $_[0]{fh}->print('%%$TJ:DOC=', $_[0]->jsonxs->encode($dh), "\n") if (%$dh);
  $_[0]->putSentence($_) foreach (@{toDocument($_[1])->{body}});
  return $_[0];
}


## $fmt = $fmt->putData($data)
##  + puts raw data (json)
sub putData {
  $_[0]{fh}->print($_[0]->jsonxs->encode($_[1]));
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl, edited

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::TJ - Datum parser: one-token-per-line text; token data as JSON

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::TJ;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = DTA::CAB::Format::TJ->new(%args);
 
 ##========================================================================
 ## Methods: Input
 
 $fmt = $fmt->close();
 $fmt = $fmt->fromString($string);
 $doc = $fmt->parseDocument();
 
 ##========================================================================
 ## Methods: Output
 
 $fmt = $fmt->flush();
 $str = $fmt->toString();
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putDocument($doc);

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TJ: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::TJ
inherits from
L<DTA::CAB::Format::TT|DTA::CAB::Format::TT>.

=item Filenames

DTA::CAB::Format::TJ registers the filename regex:

 /\.(?i:tj|cab-tj)$/

with L<DTA::CAB::Format|DTA::CAB::Format>.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TJ: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

%args, %$fmt:

 ##-- Input
 doc => $doc,                    ##-- buffered input document
 ##
 ##-- Output
 outbuf    => $stringBuffer,     ##-- buffered output
 #level    => $formatLevel,      ##-- n/a
 ##
 ##-- Common
 encoding => $inputEncoding,     ##-- default: UTF-8, where applicable

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TJ: Methods: Persistence
=pod

=head2 Methods: Persistence

=over 4

=item noSaveKeys

 @keys = $class_or_obj->noSaveKeys();

Returns list of keys not to be saved.
This implementation returns C<qw(doc outbuf)>.

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TJ: Methods: Input
=pod

=head2 Methods: Input

=over 4

=item close

 $fmt = $fmt->close();

Override: close current input source, if any.

=item fromString

 $fmt = $fmt->fromString($string);

Override: select input from string $string.

=item parseTJString

 $fmt = $fmt->parseTJString($str)

Guts for fromString(): parse string $str into local document buffer
$fmt-E<gt>{doc}.

=item parseDocument

 $doc = $fmt->parseDocument();

Override: just returns local document buffer $fmt-E<gt>{doc}.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::TJ: Methods: Output
=pod

=head2 Methods: Output

=over 4

=item flush

 $fmt = $fmt->flush();

Override: flush accumulated output

=item toString

 $str = $fmt->toString();
 $str = $fmt->toString($formatLevel)

Override: flush buffered output document to byte-string.
Just encodes string in $fmt-E<gt>{outbuf}.

=item putToken

 $fmt = $fmt->putToken($tok);

Override: token output.

=item putSentence

 $fmt = $fmt->putSentence($sent);

Override: sentence output.

=item putDocument

 $fmt = $fmt->putDocument($doc);

Override: document output.

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## EXAMPLE
##========================================================================
=pod

=head1 EXAMPLE

An example file in the format accepted/generated by this module (with very long lines) is:

 %%$TJ:SENT={"lang":"de"}
 wie	{"errid":"ec","hasmorph":"1","msafe":"1","moot":{"word":"wie","tag":"PWAV","lemma":"wie"},"exlex":"wie","lang":["de"],"xlit":{"latin1Text":"wie","isLatin1":"1","isLatinExt":"1"},"text":"wie"}
 oede	{"moot":{"word":"öde","tag":"ADJD","lemma":"öde"},"text":"oede","xlit":{"latin1Text":"oede","isLatin1":"1","isLatinExt":"1"},"msafe":"0"}
 !	{"errid":"ec","exlex":"!","msafe":"1","xlit":{"isLatin1":"1","isLatinExt":"1","latin1Text":"!"},"text":"!","moot":{"word":"!","tag":"$.","lemma":"!"}}
  

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2019 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
