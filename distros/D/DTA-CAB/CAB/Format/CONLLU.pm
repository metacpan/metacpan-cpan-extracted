## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Format::CONLLU.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: Datum parser/formatter: CONLL-U format
##  + see https://universaldependencies.org/format.html
##
## Format fields:
##   ID: Word index, integer starting at 1 for each new sentence;
##   FORM: Word form or punctuation symbol.
##   LEMMA: Lemma or stem of word form.
##   UPOS: Universal part-of-speech tag.
##   XPOS: Language-specific part-of-speech tag; underscore if not available.
##   FEATS: List of morphological features from the universal feature inventory or underscore if not available.
##   HEAD: Head of the current word, which is either a value of ID or zero (0).
##   DEPREL: Universal dependency relation to the HEAD (root iff HEAD = 0) or a defined language-specific subtype of one.
##   DEPS: Enhanced dependency graph in the form of a list of head-deprel pairs.
##   MISC: Any other annotation, split by '|'
##
## Local format conventions for MISC ("MISC1|...|MISCn")
##   + MISC fields "MISC$i" is of the form 'ATTR=VALUE' are handled specially for the following ATTRs:
##       id=TOKID           # sets $tok->{id}
##       loc=OFFSET LENGTH  # sets $tok->{loc}
##       xlit=XTEXT         # sets $tok->{xlit}{latin1Text}; also honors CONLL-U "Translit=XTEXT"
##       norm=NORM          # sets $tok->{moot}{word}
##       details=DETAILS    # sets $tok->{moot}{details}{details}
##       json=JSON          # clobbers %$tok with JSON a la Format::TJ
##   + VALUEs of specially handled attributes containing literal '%' or '|'
##     should have these 2 characters (and only these 2 characters) URI-escaped ('%25', '%7C' respectively)

package DTA::CAB::Format::CONLLU;
use DTA::CAB::Format;
use DTA::CAB::Format::TJ;
use DTA::CAB::Datum ':all';
use IO::File;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw(DTA::CAB::Format::TJ);

BEGIN {
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, filenameRegex=>qr/\.(?i:conllu|conll[_-]u|cab[\.-]connlu|cab[\.-]conll[\.-]u)$/);
  DTA::CAB::Format->registerFormat(name=>__PACKAGE__, short=>$_)
      foreach (qw(conllu conll-u cab-conllu cab-conll-u));
}

##==============================================================================
## Constructors etc.
##==============================================================================

## $fmt = CLASS_OR_OBJ->new(%args)
##  + object structure: assumed HASH
##    {
##     ##-- Input
##     doc => $doc,                    ##-- INHERITED: buffered input document
##     cuMiscIn => $bool,              ##-- NEW: parse special MISC attrs (default=true)
##
##     ##-- Output
##     outbuf   => $stringBuffer,      ##-- INHERITED: buffered output
##     level    => $formatLevel,       ##-- OVERRIDE: <0:omit-misc ; 0:default:include-misc,exclude-json, >=1:include-json, >=2:canonical-json
##     tagset   => $tagset,            ##-- auto-convert XPOS->UPOS for $tagset (known values: 'stts' (default))
##
##     ##-- Common (INHERITED from Format::TT)
##     raw => $bool,                   ##-- INHERITED: attempt to load/save raw data
##     fh  => $fh,                     ##-- INHERITED: IO::Handle for read/write
##     utf8 => $bool,                  ##-- INHERITED: read/write utf8?
##     tloc => $attr,                  ##-- INHERITED: if non-empty, parseTokenizerString() sets $w->{$attr}="$off $len"; default=0
##     #defaultFieldName => $name,     ##-- INHERITED: default name for unnamed misc-fields; parsed into @{$tok->{other}{$name}}; default=''
##    }

sub new {
  my $that = shift;
  my $fmt = $that->SUPER::new(
			      ##-- input
			      doc => undef,
			      cuMiscIn=>1,

			      ##-- output
			      #level => 0,
			      tagset => 'stts',

			      ##-- common
			      utf8 => 1,
			      #defaultFieldName => '',
			      #tloc => undef,

			      ##-- user args
			      @_
			     );
  return $fmt;
}

##==============================================================================
## Methods: Persistence
##==============================================================================

## @keys = $class_or_obj->noSaveKeys()
##  + returns list of keys not to be saved
##  + default just returns empty list
##  + INHERITED from Format::TJ

##==============================================================================
## Methods: I/O: Generic
##==============================================================================

## $jxs = $fmt->jsonxs()
##  + INHERITED from Format::TJ

## $str = unescapeConllu($str)
##  + un-escapes CONLLU value strings using URI-escape sequences ('%7C' => '|', '%25'=>'%')
sub unescapeConllu {
  my $str = shift;
  $str =~ s/%7C/\|/gi;
  $str =~ s/%25/\%/gi;
  return $str;
}

## $str = escapeConllu($str)
##  + escapes CONLLU value strings using URI-escape sequences ('|'=>'%7C', '%'=>'%25')
sub escapeConllu {
  my $str = shift;
  $str =~ s/\%/%25/gi;
  $str =~ s/\|/%7C/gi;
  return $str;
}

##--------------------------------------------------------------
## Methods & Data: tagset conversions

## %XPOS2UPOS => ($tagset => $CODE_OR_HASHREF, ...)
our %XPOS2UPOS =
  (
   ##-- xpos2upos:stts: see http://universaldependencies.org/tagset-conversion/de-stts-uposf.html
   stts => {
	    '$(' => 'PUNCT',
	    '$,' => 'PUNCT',
	    '$.' => 'PUNCT',
	    'ADJA' => 'ADJ',
	    'ADJD' => 'ADJ',
	    'ADV' => 'ADV',
	    'APPO' => 'ADP',
	    'APPR' => 'ADP',
	    'APPRART' => 'ADP',
	    'APZR' => 'ADP',
	    'ART' => 'DET',
	    'CARD' => 'NUM',
	    'FM' => 'X',
	    'ITJ' => 'INTJ',
	    'KOKOM' => 'CCONJ',
	    'KON' => 'CCONJ',
	    'KOUI' => 'SCONJ',
	    'KOUS' => 'SCONJ',
	    'NE' => 'PROPN',
	    'NN' => 'NOUN',
	    'PAV' => 'ADV',
	    'PDAT' => 'DET',
	    'PDS' => 'PRON',
	    'PIAT' => 'DET',
	    'PIDAT' => 'DET',
	    'PIS' => 'PRON',
	    'PPER' => 'PRON',
	    'PPOSAT' => 'DET',
	    'PPOSS' => 'PRON',
	    'PRELAT' => 'DET',
	    'PRELS' => 'PRON',
	    'PRF' => 'PRON',
	    'PTKA' => 'PART',
	    'PTKANT' => 'PART',
	    'PTKNEG' => 'PART',
	    'PTKVZ' => 'ADP',
	    'PTKZU' => 'PART',
	    'PWAT' => 'DET',
	    'PWAV' => 'ADV',
	    'PWS' => 'PRON',
	    'TRUNC' => 'X',
	    'VAFIN' => 'AUX',
	    'VAIMP' => 'AUX',
	    'VAINF' => 'AUX',
	    'VAPP' => 'AUX',
	    'VMFIN' => 'VERB',
	    'VMINF' => 'VERB',
	    'VMPP' => 'VERB',
	    'VVFIN' => 'VERB',
	    'VVIMP' => 'VERB',
	    'VVINF' => 'VERB',
	    'VVIZU' => 'VERB',
	    'VVPP' => 'VERB',
	    'XY' => 'X',
	   },
  );

##==============================================================================
## Methods: I/O: Block-wise
##  + mostly INHERITED from Format::TT
##==============================================================================

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Generic

## %blockOpts = $CLASS_OR_OBJECT->blockDefaults()
##  + returns default block options as for blockOptions()
##  + INHERITED default just returns as for $CLASS_OR_OBJECT->blockOptions('128k@w')

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Input

## \%head = blockScanHead(\$buf,$io,\%opts)
##  + gets header offset, length from (mmaped) \$buf
##  + %opts are as for blockScan()
##  + OVERRIDE scans for CONLL-U "# newdoc" comment
sub blockScanHead {
  my ($fmt,$bufr,$io,$opts) = @_;
  return [0,$+[0]] if ($$bufr =~ m(\A\n*+(?:#\s*newdoc\b.*\n++)?));
  return [0,0];
}

## \%head = blockScanFoot(\$buf,$io,\%opts)
##  + gets footer offset, length from (mmaped) \$buf
##  + %opts are as for blockScan()
##  + override INHERITED from Format::TT returns empty

## \@blocks = $fmt->blockScanBody(\$buf,\%opts)
##  + scans $filename for block boundaries according to \%opts
##  + INHERITED from Format::TT

##--------------------------------------------------------------
## Methods: I/O: Block-wise: Output

## $blk = $fmt->blockStore(\$odata,$blk,$bopt)
##  + store output buffer \$buf in $blk->{odata}
##  + additionally store keys qw(ofmt ohead odata ofoot) relative to $blk->{odata}
##  + override truncates trailing newlines according to $blk->{eos} before calling inherited method
##  + INHERITED from Format::TT

## $fmt_or_undef = $fmt->blockAppend($block,$filename)
##  + append a block $block to a file $filename
##  + $block is a HASH-ref as returned by blockScan()
##  + INHERITED from DTA::CAB::Format


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
  return $fmt->parseConlluFh($_[0]);
}

## $fmt = $fmt->fromString(\$string)
##  + select input from string $string
##  + INHERITED from Format::TJ

##--------------------------------------------------------------
## Methods: Input: Local

## $fmt = $fmt->parseConlluFH($fh)
##  + guts for fromFh(): parse handle $fh into local document buffer.
sub parseConlluFh {
  my ($fmt,$fh) = @_;
  $fmt->setLayers($fh);
  my $jxs = $fmt->jsonxs();

  ##-- ye olde loope
  my (%sa,%doca);
  my $toks = [];
  my @body = qw();
  my ($tok,%cu,@misc,$json);
  while (defined($_=<$fh>)) {
    if (/^\#\s*newdoc\s+id\s*=\s*(.*)$/) {
      ##-- conllu comment: document attribute: doc id (-> "id", "base")
      $doca{'id'} = $doca{'base'} = $1;
    }
    elsif ($_ =~ /^#\s*sent_id\s*=\s*(.*)$/) {
      ##-- connlu comment: sentence attribute: xml:id (-> "sent_id", "id")
      $sa{sent_id} = $sa{'id'} = $1;
    }
    elsif ($_ =~ /^#\s*text\s*=\s*(.*)$/) {
      ##-- connl-u comment: sentence attribute: raw text (-> "stxt", "text")
      $sa{'stxt'} = $sa{'text'} = $1;
    }
    elsif ($_ =~ /^#\s*\$TJ:DOC=(.+)$/) {
      ##-- tj directive: document attributes
      $json = defined($1) && $1 ? $jxs->decode($1) : {};
      @doca{keys %$json} = values %$json;
    }
    elsif ($_ =~ /^#\s*\$TJ:SENT=(.+)$/) {
      ##-- tj directive: setence attributes
      $json = defined($1) && $1 ? $jxs->decode($1) : {};
      @sa{keys %$json} = values %$json;
    }
    elsif ($_ =~ /^# (?:xml\:)?base=(.*)$/) {
      ##-- (tt-compat) special comment: document attribute: xml:base
      $doca{'base'} = $1;
    }
    elsif ($_ =~ /^# Sentence (.*)$/) {
      ##-- (tt-compat) special comment: sentence attribute: xml:id
      $sa{'id'} = $1;
    }
    elsif ($_ =~ /^\#(.*)$/) {
      ##-- generic conllu- comment line: add to '_cmts' attribute of current sentence
      push(@{$sa{_cmts}},$1);
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
      @cu{qw(id form lemma upos xpos feats head deprel deps misc)}
	= map { ($_//'_') eq '_' ? undef : $_ } split(/\t/,$_,10);
      $tok = { text=>$cu{form} };

      ##-- parse: feats
      ## + example: 'Case=Acc,Dat|Number=Sing' --> {'Case'=>'Acc,Dat', 'Number'=>'Sing'}
      $cu{feats} = { map {split('=',$_,2)} split('|',$cu{feats}) }
	if ($cu{feats});

      ##-- parse: deps (extended dependency graph)
      ## + example: '0:root|2:conj|4:conj' --> [[0,'root'],[2,'conj'],[4,'conj']]
      $cu{deps} = [ map {[split(':',$_,2)]} split('|',$cu{deps}) ]
	if ($cu{deps});

      ##-- parse: misc
      if ($cu{misc} && ($fmt->{cuMiscIn}//1)) {
	@misc = qw();
	foreach (split(/\|/,$cu{misc})) {
	  if (m/^loc=(?:off=)?([0-9]+) (?:len=)?([0-9]+)$/) {
	    ##-- misc: loc=OFFSET LENGTH  (sets $tok->{loc})
	    $tok->{loc} = { off=>$1, len=>$2 };
	  }
	  elsif (m/(?:xml\:?)?id=(.*)$/) {
	    ##-- misc: id=TOKID # sets $tok->{id}
	    $tok->{id} = unescapeConllu($1);
	  }
	  elsif (s/^(?:xlit|[Ll]?[Tt]ranslit)=//) {
	    ##-- misc: xlit=XTEXT (sets $tok->{xlit}{latin1Text}; also honors CONLL-U "Translit=XTEXT")
	    if (m/^(?:isLatin1|l1)=([01]) (?:isLatinExt|lx)=([01]) (?:latin1Text|l1s)=(.*)$/) {
	      $tok->{xlit} = { isLatin1=>($1||0), isLatinExt=>($2||0), latin1Text=>unescapeConllu($3) };
	    } else {
	      $tok->{xlit} = { isLatin1=>'', isLatinExt=>'', latin1Text=>unescapeConllu($_) };
	    }
	  }
	  elsif (m/^norm=(.*)$/) {
	    ## misc: norm=NORM (sets $tok->{moot}{word})
	    $tok->{moot}{word} = unescapeConllu($1);
	  }
	  elsif (m/^details=(\S*)?(?:\s\@\s(\S+))?\s(?:\~\s)?(.*?)(?: <([0-9\.\+\-eE]+)>)?$/) {
	    ## misc: details=DETAILS (sets $tok->{moot}{details}
	    $tok->{moot}{details} = {
				     (($1//'') ne '' ? (tag=>unescapeConllu($1)) : qw()),
				     (($2//'') ne '' ? (lemma=>unescapeConllu($2)) : qw()),
				     details=>unescapeConllu($3),
				     prob=>$4,
				    };
	  }
	  elsif (m/^json=(.+)$/) {
	    ## misc: json=JSON (clobbers %$tok with JSON a la Format::TJ)
	    $json = $jxs->decode(unescapeConllu($1));
	    @$tok{keys %$json} = values %$json;
	  }
	  else {
	    ## misc: extra attribute, add to $cu{misc}
	    push(@misc, $_);
	  }
	}
	$cu{misc} = [@misc];
      }
      elsif ($cu{misc}) {
	##-- MISC: don't parse special attributes, just split
	$cu{misc} = [split(/\|/,$cu{misc})];
      }

      ##-- store token
      $tok->{conllu} = {%cu};
      $tok->{moot}{tag}   //= ($cu{xpos} // $cu{upos});
      $tok->{moot}{lemma} //= $cu{lemma};
      push(@$toks, $tok)
    }
  }
  push(@body, {%sa,tokens=>$toks}) if (%sa || @$toks); ##-- handle missing EOS at EOF

  ##-- construct & buffer output document
  $fmt->{doc} = bless({%doca,body=>\@body}, 'DTA::CAB::Document');
  return $fmt;
}


##--------------------------------------------------------------
## Methods: Input: Generic API

## $doc = $fmt->parseDocument()
##  + INHERITED from Format::TJ

##==============================================================================
## Methods: Output
##==============================================================================

##--------------------------------------------------------------
## Methods: Output: Generic

## $type = $fmt->mimeType()
##  + INHERITED default returns text/plain

## $ext = $fmt->defaultExtension()
##  + returns default filename extension for this format
sub defaultExtension { return '.conllu'; }

##--------------------------------------------------------------
## Methods: Output: Generic API

## $fmt = $fmt->putToken($tok)
## $fmt = $fmt->putToken($tok,$conllu_id)
##   + honors $fmt->{level} : <0:omit-misc ; 0:default:include-misc,exclude-json, >=1:include-json, >=2:canonical-json
sub putToken {
  my ($fmt,$tok,$id) = @_;

  ##-- conllu fields ($id,$text,$lemma,$upos,$xpos,$feats,$head,$deprel,$deps) ... everything but MISC
  my %cu = %{$tok->{conllu} // {}};
  $cu{id}    //= $id // '_';
  $cu{form}  //= $tok->{text};
  $cu{xpos}  //= $tok->{pos}   // ($tok->{moot} ? $tok->{moot}{tag} : undef);
  $cu{lemma} //= $tok->{lemma} // ($tok->{moot} ? $tok->{moot}{lemma} : undef);

  ##-- implicit xpos->upos conversion
  if (!$cu{upos} && $fmt->{tagset} && defined(my $x2u=$XPOS2UPOS{$fmt->{tagset}})) {
    if (UNIVERSAL::isa($x2u,'HASH')) {
      $cu{upos} = $x2u->{$cu{xpos}//''} // 'X';
    }
    elsif (UNIVERSAL::isa($x2u,'CODE')) {
      $cu{upos} = $x2u->($cu{xpos}) // 'X';
    }
    else {
      confess(__PACKAGE__, "::putToken(): PoS-translation table must be a HASH- or CODE-ref");
    }
  }

  ##-- special MISC ATTRS
  my @misc = qw();
  if (($fmt->{level}//0) >= 0) {
    ##-- include special misc ATTRS
    push(@misc, "id=$tok->{id}") if ($tok->{id});
    push(@misc, "loc=$tok->{loc}{off} $tok->{loc}{len}") if ($tok->{loc});
    push(@misc, "Translit=$tok->{xlit}{latin1Text}") if ($tok->{xlit});
    if ($tok->{moot}) {
      push(@misc, "norm=$tok->{moot}{word}")
	if (defined($tok->{moot}{word}));
      push(@misc, "details=$tok->{moot}{details}{details} <".($tok->{moot}{details}{prob}||$tok->{moot}{details}{cost}||0).">")
	if (defined($tok->{moot}{details}{details}));
    }

    if (($fmt->{level}//0) >= 1) {
      ##-- include misc/json
      push(@misc, "json=".$fmt->jsonxs->encode($tok));
    }

    $_ = escapeConllu($_) foreach (@misc)
  }

  $fmt->{fh}->print
    (
     ##-- comments
     ($tok->{_cmts} ? join('', map {"#$_\n"} map {split(/\n/,$_)} @{$tok->{_cmts}}) : ''),
     ##
     join("\t",
	  ##-- conllu fixed fields ($id,$text,$lemma,$upos,$xpos,$feats,$head,$deprel,$deps) ... everything but MISC
	  map { ($_//'') eq '' ? '_' : $_ }
	  @cu{qw(id form lemma upos xpos)},
	  (UNIVERSAL::isa($cu{feats},'HASH')
	   ? join('|',map {"$_:$cu{feats}{$_}"} sort keys %{$cu{feats}})
	   : $cu{feats}),
	  @cu{qw(head deprel)},
	  (UNIVERSAL::isa($cu{deps},'ARRAY')
	   ? join('|',map {"$_->[0]:$_->[1]"} @{$cu{deps}})
	   : $cu{deps}),
	  ##-- conllu MISC (may be empty, depending on $fmt->{level})
	  join('|', @{$cu{misc}//[]}, @misc),
	 ),
     "\n",
    );

  return $fmt;
}


## $fmt = $fmt->putSentence($sent)
##  + concatenates formatted tokens, adding sentence-id comment if available
sub putSentence {
  #my ($fmt,$sent) = @_;
  my $sh = {(map {$_ eq 'tokens' ? qw() : ($_=>$_[1]{$_})} keys %{$_[1]})};
  $_[0]{fh}->print(join('', map {"#$_\n"} map {split(/\n/,$_)} @{$_[1]{_cmts}})) if ($_[1]{_cmts});
  $_[0]{fh}->print("# sent_id = ", ($_[1]{id}//''), "\n");
  $_[0]{fh}->print("# text = $_[1]{stxt}\n") if (defined($_[1]{stxt}));
  $_[0]{fh}->print('# $TJ:SENT=', $_[0]->jsonxs->encode($sh), "\n") if (%$sh && ($_[0]{level}//0) >= 1);
  my $i = 0;
  $_[0]->putToken($_,++$i) foreach (@{toSentence($_[1])->{tokens}});
  $_[0]{fh}->print("\n");
  return $_[0];
}

## $fmt = $fmt->putDocument($doc)
##  + concatenates formatted sentences, adding document 'xmlbase' comment if available
our %TJ_BAD_DOC_KEYS = %DTA::CAB::Format::TJ::TJ_BAD_DOC_KEYS;
sub putDocument {
  #my ($fmt,$doc) = @_;
  my $dh = { (map {($_=>$_[1]{$_})} grep {!exists($TJ_BAD_DOC_KEYS{$_})} keys %{$_[1]}) };
  $_[0]{fh}->print('# $TJ:DOC=', $_[0]->jsonxs->encode($dh), "\n") if (%$dh && ($_[0]{level}//0) >= 1);
  $_[0]->putSentence($_) foreach (@{toDocument($_[1])->{body}});
  return $_[0];
}

## $fmt = $fmt->putData($data)
##  + puts raw data (uses forceDocument())
##  + OVERRIDE uses Format::TT implementation
sub putData {
  return $_[0]->DTA::CAB::Format::TT->putData($_[1]);
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DTA::CAB::Format::CONLLU - Datum parser: CONLL-U format

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 use DTA::CAB::Format::CONLLU;
 
 ##========================================================================
 ## Constructors etc.
 
 $fmt = DTA::CAB::Format::CONLLU->new(%args);
 
 ##========================================================================
 ## Methods: I/O: Input
 
 \%head = blockScanHead(\$buf,$io,\%opts);
 $fmt = $fmt->fromFh($filename_or_handle);
 
 ##========================================================================
 ## Methods: Output
 
 $ext = $fmt->defaultExtension();
 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putSentence($sent);
 $fmt = $fmt->putData($data);
 
 ##========================================================================
 ## Methods: Low-Level
 
 $str = unescapeConllu($str);
 $str = escapeConllu($str);


=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

DTA::CAB::Format::CONLLU is a CAB datum parser+formatter conforming to the
CONLL-U format conventions; see L<https://universaldependencies.org/format.html> for details.

=head2 Format fields

 ID: Word index, integer starting at 1 for each new sentence;
 FORM: Word form or punctuation symbol.
 LEMMA: Lemma or stem of word form.
 UPOS: Universal part-of-speech tag.
 XPOS: Language-specific part-of-speech tag; underscore if not available.
 FEATS: List of morphological features from the universal feature inventory or underscore if not available.
 HEAD: Head of the current word, which is either a value of ID or zero (0).
 DEPREL: Universal dependency relation to the HEAD (root iff HEAD = 0) or a defined language-specific subtype of one.
 DEPS: Enhanced dependency graph in the form of a list of head-deprel pairs.
 MISC: Any other annotation, split by '|'

=head2 Local format conventions for C<MISC> field

By the CONLL-U conventions, the final token field C<MISC> is separated
by vertical bars (C<MISC ::= "MISC1|...|MISCn">).  This module treats
C<MISC$i> elements of the form C<ATTR=VALUE> specially for the following
C<ATTR>s:

 id=TOKID           # sets $tok->{id}
 loc=OFFSET LENGTH  # sets $tok->{loc}
 xlit=XTEXT         # sets $tok->{xlit}{latin1Text}; also honors CONLL-U "Translit=XTEXT"
 norm=NORM          # sets $tok->{moot}{word}
 details=DETAILS    # sets $tok->{moot}{details}{details}
 json=JSON          # clobbers %$tok with JSON a la Format::TJ

C<VALUE>s of specially handled attributes containing literal C<%> or C<|>
should have these 2 characters (and only these 2 characters) URI-escaped (to C<%25>, and C<%7C> respectively).

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CONLLU: Globals
=pod

=head2 Globals

=over 4

=item Variable: @ISA

DTA::CAB::Format::CONLLU
inherits from
L<DTA::CAB::Format::TJ|DTA::CAB::Format::TJ>.

=item Variable: %XPOS2UPOS

Global tag translation table from language-specific PoS-tagset to UD PoS-tagset
(C<XPOS E<gt> UPOS>) used for output.  Keys are language-specific tagsets, values are HASH-
or CODE-refs for tagset translation.

 %XPOS2UPOS => ($tagset =E<gt> $CODE_OR_HASHREF, ...)
 
 $upos = $XPOS2UPOS{$tagset}->{$xpos};   ##-- HASH-ref
 $upos = $XPOS2UPOS{$tagset}->($xpos);   ##-- CODE-ref

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CONLLU: Constructors etc.
=pod

=head2 Constructors etc.

=over 4

=item new

 $fmt = CLASS_OR_OBJ->new(%args);

object structure: assumed HASH

    {
     ##-- Input
     doc => $doc,                    ##-- INHERITED: buffered input document
     cuMiscIn => $bool,              ##-- NEW: parse special MISC attrs (default=true)
     ##-- Output
     outbuf   => $stringBuffer,      ##-- INHERITED: buffered output
     level    => $formatLevel,       ##-- OVERRIDE: <0:omit-misc ; 0:default:include-misc,exclude-json, >=1:include-json, >=2:canonical-json
     tagset   => $tagset,            ##-- auto-convert XPOS->UPOS for $tagset (known values: 'stts' (default))
     ##-- Common (INHERITED from Format::TT)
     raw => $bool,                   ##-- INHERITED: attempt to load/save raw data
     fh  => $fh,                     ##-- INHERITED: IO::Handle for read/write
     utf8 => $bool,                  ##-- INHERITED: read/write utf8?
     tloc => $attr,                  ##-- INHERITED: if non-empty, parseTokenizerString() sets $w->{$attr}="$off $len"; default=0
     #defaultFieldName => $name,     ##-- INHERITED: default name for unnamed misc-fields; parsed into @{$tok->{other}{$name}}; default=''
    }

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CONLLU: Methods: I/O: Block-wise: Input
=pod

=head2 Methods: Input

=over 4

=item blockScanHead

 \%head = blockScanHead(\$buf,$io,\%opts);

gets header offset, length from (mmaped) \$buf.
%opts are as for blockScan().
OVERRIDE scans for CONLL-U C<"# newdoc"> comment.


=item fromFh

 $fmt = $fmt->fromFh($filename_or_handle);

new override calls L<DTA::CAB::Format::fromFh()|DTA::CAB::Format/fromFh>.


=item parseConlluFh

guts for L<fromFh()|/fromFh> method: parse handle $fh into local document buffer.

=back

=cut

##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CONLLU: Methods: Output: Generic
=pod

=head2 Methods: Output

=over 4

=item defaultExtension

 $ext = $fmt->defaultExtension();

returns default filename extension for this format (C<.conllu>).

=item putToken

 $fmt = $fmt->putToken($tok);
 $fmt = $fmt->putToken($tok,$conllu_id);

honors $fmt-E<gt>{level} : E<lt>0:omit-misc ; 0:default:include-misc,exclude-json, E<gt>=1:include-json, E<gt>=2:canonical-json

=item putSentence

 $fmt = $fmt->putSentence($sent);

concatenates formatted tokens, adding sentence-id comment if available

=item putDocument

concatenates formatted sentences, adding document C<# $TJ:DOC> comment comment if appropriate.

=item putData

 $fmt = $fmt->putData($data);

puts raw data (uses forceDocument());
OVERRIDE uses L<DTA::CAB::Format::TT|DTA::CAB::Format::TT> implementation.

=back

=cut


##----------------------------------------------------------------
## DESCRIPTION: DTA::CAB::Format::CONLLU: Methods: I/O: Generic
=pod

=head2 Methods: Low-Level

=over 4

=item unescapeConllu

 $str = unescapeConllu($str);

un-escapes CONLLU value strings using URI-escape sequences (C<'%7C' =E<gt> '|'>, C<'%25'=E<gt>'%'>)

=item escapeConllu

 $str = escapeConllu($str);

escapes CONLLU value strings using URI-escape sequences (C<'|'=E<gt>'%7C'>, C<'%'=E<gt>'%25'>)

=back

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## EXAMPLE
##========================================================================
=pod

=head1 EXAMPLES

=head2 Basic Example

An example file in the format accepted/generated by this module with the default options
(C<level =E<gt> 0, tagset =E<gt> 'stts'>) is:

 # sent_id = s1
 1	EJn	eine	DET	ART	_	_	_	_	Translit=Ejn|norm=Ein|details=eine[_ARTINDEF][sg][acc][neut] <2.5>
 2	zamer	zahm	ADJ	ADJA	_	_	_	_	Translit=zamer|norm=zahmer|details=zahm[_ADJA][none][pos][pl][gen]\*[strong] <0>
 3	Elephant	Elefant	NOUN	NN	_	_	_	_	Translit=Elephant|norm=Elefant|details=Elefant[_NN][k_l_t][masc][sg][nom] <0>
 4	gillt	gelten	VERB	VVFIN	_	_	_	_	Translit=gillt|norm=gilt|details=gelt~en[_VVFIN][third][sg][pres][ind] <0>
 5	ohngefähr	ohngefähr	ADV	ADV	_	_	_	_	Translit=ohngefähr|norm=ohngefähr|details=ohngefähr[_ADV] <0>
 6	zweyhundert	zweihundert	NUM	CARD	_	_	_	_	Translit=zweyhundert|norm=zweihundert|details=zwei/Z#hundert[_CARD][num ] <0>
 7	Thaler	Taler	NOUN	NN	_	_	_	_	Translit=Thaler|norm=Taler|details=Taler[_NN][k_g_artef][masc][pl][nom_acc_gen] <0>
 8	.	.	PUNCT	$.	_	_	_	_	Translit=.|norm=.|details=$. <0>
 
 # sent_id = s2
 1	Ceterum	ceterum	X	FM.la	_	_	_	_	Translit=Ceterum|norm=Ceterum|details=* <0>
 2	censeo	censeo	X	FM.la	_	_	_	_	Translit=censeo|norm=censeo|details=* <0>
 3	Carthaginem	carthaginem	X	FM.la	_	_	_	_	Translit=Carthaginem|norm=Carthaginem|details=* <0>
 4	esse	esse	X	FM.la	_	_	_	_	Translit=esse|norm=esse|details=* <0>
 5	delendam	delendam	X	FM.la	_	_	_	_	Translit=delendam|norm=delendam|details=* <0>
 6	.	.	PUNCT	$.	_	_	_	_	Translit=.|norm=.|details=$. <0>

=head2 Terse Example

An example file in the terse format generated by this module with the options (C<level =E<gt> -1, tagset =E<gt> 'none'>) is:

 # sent_id = s1
 1	EJn	eine	_	ART	_	_	_	_	_
 2	zamer	zahm	_	ADJA	_	_	_	_	_
 3	Elephant	Elefant	_	NN	_	_	_	_	_
 4	gillt	gelten	_	VVFIN	_	_	_	_	_
 5	ohngefähr	ohngefähr	_	ADV	_	_	_	_	_
 6	zweyhundert	zweihundert	_	CARD	_	_	_	_	_
 7	Thaler	Taler	_	NN	_	_	_	_	_
 8	.	.	_	$.	_	_	_	_	_
 
 # sent_id = s2
 1	Ceterum	ceterum	_	FM.la	_	_	_	_	_
 2	censeo	censeo	_	FM.la	_	_	_	_	_
 3	Carthaginem	carthaginem	_	FM.la	_	_	_	_	_
 4	esse	esse	_	FM.la	_	_	_	_	_
 5	delendam	delendam	_	FM.la	_	_	_	_	_
 6	.	.	_	$.	_	_	_	_	_

=head2 Verbose Example

An example file in the verbose format generated by this module with the options (C<level =E<gt> 2, tagset =E<gt> 'stts'>) including
a full C<TJ>-style dump in the C<json> attribute of the C<MISC> field is:

 # sent_id = s1
 # $TJ:SENT={"lang":"de"}
 1	EJn	eine	DET	ART	_	_	_	_	Translit=Ejn|norm=Ein|details=eine[_ARTINDEF][sg][acc][neut] <2.5>|json={"dmoot":{"analyses":[{"details":"Ein","prob":0,"tag":"Ein"}],"morph":[{"hi":"ein~en[_VVIMP][sg]","w":2},{"hi":"eine[_ARTINDEF][sg][nom][masc]","w":2.5},{"hi":"eine[_ARTINDEF][sg][nom][neut]","w":2.5},{"hi":"eine[_ARTINDEF][sg][acc][neut]","w":2.5},{"hi":"ein[_ADV]","w":2.5},{"hi":"ein[_CARD][num]","w":2.5},{"hi":"ein[_PTKVZ]","w":2.5}],"tag":"Ein"},"errid":"72751","exlex":"Ein","f":407,"lts":[{"hi":"\\?ejn","w":0}],"moot":{"analyses":[{"details":"ein[_ADV]","lemma":"ein","prob":2.5,"tag":"ADV"},{"details":"ein[_CARD][num]","lemma":"ein","prob":2.5,"tag":"CARD"},{"details":"ein[_PTKVZ]","lemma":"ein","prob":2.5,"tag":"PTKVZ"},{"details":"eine[_ARTINDEF][sg][acc][neut]","lemma":"eine","prob":2.5,"tag":"ART"},{"details":"eine[_ARTINDEF][sg][nom][masc]","lemma":"eine","prob":2.5,"tag":"ART"},{"details":"eine[_ARTINDEF][sg][nom][neut]","lemma":"eine","prob":2.5,"tag":"ART"},{"details":"ein~en[_VVIMP][sg]","lemma":"einen","prob":2,"tag":"VVIMP"}],"details":{"details":"eine[_ARTINDEF][sg][acc][neut]","lemma":"eine","prob":2.5,"tag":"ART"},"lemma":"eine","tag":"ART","word":"Ein"},"msafe":0,"rw":[],"text":"EJn","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"Ejn"}}
 2	zamer	zahm	ADJ	ADJA	_	_	_	_	Translit=zamer|norm=zahmer|details=zahm[_ADJA][none][pos][pl][gen]\*[strong] <0>|json={"dmoot":{"analyses":[{"details":"zahmer","prob":0.129596281051636,"tag":"zahmer"},{"details":"zamer","prob":1.248,"tag":"zamer"}],"morph":[{"hi":"zahm[_ADJA][none][pos][sg][nom][masc][strong_mixed]","w":0},{"hi":"zahm[_ADJA][none][pos][sg][dat_gen][fem][strong]","w":0},{"hi":"zahm[_ADJA][none][pos][pl][gen]\\*[strong]","w":0},{"hi":"zahm[_ADJC][none][comp]","w":0}],"tag":"zahmer"},"eqphox":[{"hi":"zahmer","w":0.237610012292862}],"f":1,"lts":[{"hi":"tsame6","w":0}],"moot":{"analyses":[{"details":"zahm[_ADJA][none][pos][pl][gen]\\*[strong]","lemma":"zahm","prob":0,"tag":"ADJA"},{"details":"zahm[_ADJA][none][pos][sg][dat_gen][fem][strong]","lemma":"zahm","prob":0,"tag":"ADJA"},{"details":"zahm[_ADJA][none][pos][sg][nom][masc][strong_mixed]","lemma":"zahm","prob":0,"tag":"ADJA"},{"details":"zahm[_ADJC][none][comp]","lemma":"zahm","prob":0,"tag":"ADJD"}],"details":{"details":"zahm[_ADJA][none][pos][pl][gen]\\*[strong]","lemma":"zahm","prob":0,"tag":"ADJA"},"lemma":"zahm","tag":"ADJA","word":"zahmer"},"msafe":0,"rw":[{"hi":"zahmer","w":15.7981405258179}],"text":"zamer","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"zamer"}}
 3	Elephant	Elefant	NOUN	NN	_	_	_	_	Translit=Elephant|norm=Elefant|details=Elefant[_NN][k_l_t][masc][sg][nom] <0>|json={"dmoot":{"analyses":[{"details":"Elefant","prob":0,"tag":"Elefant"}],"morph":[{"hi":"Elefant[_NN][k_l_t][masc][sg][nom]","w":0}],"tag":"Elefant"},"errid":"84974","exlex":"Elefant","f":303,"lang":["de"],"lts":[{"hi":"\\?elefant","w":0}],"moot":{"analyses":[{"details":"Elefant[_NN][k_l_t][masc][sg][nom]","lemma":"Elefant","prob":0,"tag":"NN"}],"details":{"details":"Elefant[_NN][k_l_t][masc][sg][nom]","lemma":"Elefant","prob":0,"tag":"NN"},"lemma":"Elefant","tag":"NN","word":"Elefant"},"morph":[{"hi":"Elephant[_NN][k_l_t][masc][sg][nom]","w":0},{"hi":"elephant[_FM][en]","w":2.5}],"msafe":1,"rw":[],"text":"Elephant","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"Elephant"}}
 4	gillt	gelten	VERB	VVFIN	_	_	_	_	Translit=gillt|norm=gilt|details=gelt~en[_VVFIN][third][sg][pres][ind] <0>|json={"dmoot":{"analyses":[{"details":"gilt","prob":0.135864566802979,"tag":"gilt"},{"details":"gillt","prob":1.248,"tag":"gillt"},{"details":"Gild","prob":1.35002433472872,"tag":"Gild"}],"morph":[{"hi":"gelt~en[_VVFIN][third][sg][pres][ind]","w":0},{"hi":"gelt~en[_VVIMP][sg]","w":0}],"tag":"gilt"},"eqphox":[{"hi":"gilt","w":0.0521488003432751},{"hi":"Gild","w":0.298937886953354}],"f":5,"lts":[{"hi":"gilt","w":0}],"moot":{"analyses":[{"details":"gelt~en[_VVFIN][third][sg][pres][ind]","lemma":"gelten","prob":0,"tag":"VVFIN"},{"details":"gelt~en[_VVIMP][sg]","lemma":"gelten","prob":0,"tag":"VVIMP"}],"details":{"details":"gelt~en[_VVFIN][third][sg][pres][ind]","lemma":"gelten","prob":0,"tag":"VVFIN"},"lemma":"gelten","tag":"VVFIN","word":"gilt"},"msafe":0,"rw":[{"hi":"gilt","w":18.9322834014893}],"text":"gillt","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"gillt"}}
 5	ohngefähr	ohngefähr	ADV	ADV	_	_	_	_	Translit=ohngefähr|norm=ohngefähr|details=ohngefähr[_ADV] <0>|json={"dmoot":{"analyses":[{"details":"ohngefähr","prob":0,"tag":"ohngefähr"}],"morph":[{"hi":"ohngefähr[_ADV]","w":0}],"tag":"ohngefähr"},"lang":["de"],"lts":[{"hi":"\\?oNefe6","w":0}],"moot":{"analyses":[{"details":"ohngefähr[_ADV]","lemma":"ohngefähr","prob":0,"tag":"ADV"}],"details":{"details":"ohngefähr[_ADV]","lemma":"ohngefähr","prob":0,"tag":"ADV"},"lemma":"ohngefähr","tag":"ADV","word":"ohngefähr"},"morph":[{"hi":"ohngefähr[_ADV]","w":0}],"msafe":1,"text":"ohngefähr","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"ohngefähr"}}
 6	zweyhundert	zweihundert	NUM	CARD	_	_	_	_	Translit=zweyhundert|norm=zweihundert|details=zwei/Z#hundert[_CARD][num] <0>|json={"dmoot":{"analyses":[{"details":"zweihundert","prob":0,"tag":"zweihundert"}],"morph":[{"hi":"zwei/Z#hundert[_CARD][num]","w":0}],"tag":"zweihundert"},"errid":"ec","exlex":"zweihundert","f":397,"lts":[{"hi":"tsvaihunde6t","w":0}],"moot":{"analyses":[{"details":"zwei/Z#hundert[_CARD][num]","lemma":"zweihundert","prob":0,"tag":"CARD"}],"details":{"details":"zwei/Z#hundert[_CARD][num]","lemma":"zweihundert","prob":0,"tag":"CARD"},"lemma":"zweihundert","tag":"CARD","word":"zweihundert"},"msafe":0,"rw":[],"text":"zweyhundert","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"zweyhundert"}}
 7	Thaler	Taler	NOUN	NN	_	_	_	_	Translit=Thaler|norm=Taler|details=Taler[_NN][k_g_artef][masc][pl][nom_acc_gen] <0>|json={"dmoot":{"analyses":[{"details":"Taler","prob":0,"tag":"Taler"}],"morph":[{"hi":"Taler[_NN][k_g_artef][masc][sg][nom_acc_dat]","w":0},{"hi":"Taler[_NN][k_g_artef][masc][pl][nom_acc_gen]","w":0}],"tag":"Taler"},"errid":"57836","exlex":"Taler","f":4078,"lts":[{"hi":"tale6","w":0}],"moot":{"analyses":[{"details":"Taler[_NN][k_g_artef][masc][pl][nom_acc_gen]","lemma":"Taler","prob":0,"tag":"NN"},{"details":"Taler[_NN][k_g_artef][masc][sg][nom_acc_dat]","lemma":"taler","prob":0,"tag":"NN"}],"details":{"details":"Taler[_NN][k_g_artef][masc][pl][nom_acc_gen]","lemma":"Taler","prob":0,"tag":"NN"},"lemma":"Taler","tag":"NN","word":"Taler"},"morph":[{"hi":"Thaler[_NE][lastname][none][k_l_h_m_namti_fam][sg][nom_acc_dat]","w":0},{"hi":"Thale/GN~er[_NN][k_l_h_m_eig_sozk_bev_geo][masc][sg][nom_acc_dat]","w":5},{"hi":"Thale/GN~er[_NN][k_l_h_m_eig_sozk_bev_geo][masc][pl][nom_acc_gen]","w":5},{"hi":"Thal/GN~er[_NN][k_l_h_m_eig_sozk_bev_geo][masc][sg][nom_acc_dat]","w":5},{"hi":"Thal/GN~er[_NN][k_l_h_m_eig_sozk_bev_geo][masc][pl][nom_acc_gen]","w":5}],"msafe":0,"rw":[],"text":"Thaler","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"Thaler"}}
 8	.	.	PUNCT	$.	_	_	_	_	Translit=.|norm=.|details=$. <0>|json={"dmoot":{"analyses":[{"details":".","prob":0,"tag":"."}],"morph":[{"hi":"$.","w":0}],"tag":"."},"errid":"ec","exlex":".","f":5318438,"lts":[{"hi":"","w":0}],"moot":{"analyses":[{"details":"$.","lemma":".","prob":0,"tag":"$."}],"details":{"details":"$.","lemma":".","prob":0,"tag":"$."},"lemma":".","tag":"$.","word":"."},"msafe":1,"text":".","toka":["$."],"tokpp":["$."],"xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"."}}
 
 # sent_id = s2
 # $TJ:SENT={"lang":"la"}
 1	Ceterum	ceterum	X	FM.la	_	_	_	_	Translit=Ceterum|norm=Ceterum|details=* <0>|json={"dmoot":{"analyses":[{"details":"Ceterum","prob":0,"tag":"Ceterum"}],"morph":[{"hi":"[_FM][lat]","w":0}],"tag":"Ceterum"},"f":11,"lang":["la"],"lts":[{"hi":"kete6um","w":0}],"mlatin":[{"hi":"[_FM][lat]","w":0}],"moot":{"analyses":[{"details":"[_FM][lat]","lemma":"ceterum","prob":0,"tag":"FM"}],"details":{"details":"*","lemma":"ceterum","prob":0,"tag":"FM.la"},"lemma":"ceterum","tag":"FM.la","word":"Ceterum"},"msafe":1,"text":"Ceterum","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"Ceterum"}}
 2	censeo	censeo	X	FM.la	_	_	_	_	Translit=censeo|norm=censeo|details=* <0>|json={"dmoot":{"analyses":[{"details":"censeo","prob":0,"tag":"censeo"}],"morph":[{"hi":"[_FM][lat]","w":0}],"tag":"censeo"},"f":9,"lang":["la"],"lts":[{"hi":"kenzeo","w":0}],"mlatin":[{"hi":"[_FM][lat]","w":0}],"moot":{"analyses":[{"details":"[_FM][lat]","lemma":"censeo","prob":0,"tag":"FM"}],"details":{"details":"*","lemma":"censeo","prob":0,"tag":"FM.la"},"lemma":"censeo","tag":"FM.la","word":"censeo"},"msafe":1,"text":"censeo","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"censeo"}}
 3	Carthaginem	carthaginem	X	FM.la	_	_	_	_	Translit=Carthaginem|norm=Carthaginem|details=* <0>|json={"dmoot":{"analyses":[{"details":"Carthaginem","prob":0,"tag":"Carthaginem"}],"morph":[{"hi":"[_FM][lat]","w":0}],"tag":"Carthaginem"},"f":6,"lang":["la"],"lts":[{"hi":"ka6taginem","w":0}],"mlatin":[{"hi":"[_FM][lat]","w":0}],"moot":{"analyses":[{"details":"[_FM][lat]","lemma":"carthaginem","prob":0,"tag":"FM"}],"details":{"details":"*","lemma":"carthaginem","prob":0,"tag":"FM.la"},"lemma":"carthaginem","tag":"FM.la","word":"Carthaginem"},"msafe":1,"text":"Carthaginem","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"Carthaginem"}}
 4	esse	esse	X	FM.la	_	_	_	_	Translit=esse|norm=esse|details=* <0>|json={"dmoot":{"analyses":[{"details":"esse","prob":0,"tag":"esse"}],"morph":[{"hi":"ess~en[_VVFIN][first][sg][pres][ind]","w":0},{"hi":"ess~en[_VVFIN][first][sg][pres][subjI]","w":0},{"hi":"ess~en[_VVFIN][third][sg][pres][subjI]","w":0},{"hi":"[_FM][lat]","w":0}],"tag":"esse"},"errid":"71075","exlex":"esse","f":1046,"lang":["de","la"],"lts":[{"hi":"\\?ese","w":0}],"mlatin":[{"hi":"[_FM][lat]","w":0}],"moot":{"analyses":[{"details":"[_FM][lat]","lemma":"esse","prob":0,"tag":"FM"},{"details":"ess~en[_VVFIN][first][sg][pres][ind]","lemma":"essen","prob":0,"tag":"VVFIN"},{"details":"ess~en[_VVFIN][first][sg][pres][subjI]","lemma":"essen","prob":0,"tag":"VVFIN"},{"details":"ess~en[_VVFIN][third][sg][pres][subjI]","lemma":"essen","prob":0,"tag":"VVFIN"}],"details":{"details":"*","lemma":"esse","prob":0,"tag":"FM.la"},"lemma":"esse","tag":"FM.la","word":"esse"},"morph":[{"hi":"ess~en[_VVFIN][first][sg][pres][ind]","w":0},{"hi":"ess~en[_VVFIN][first][sg][pres][subjI]","w":0},{"hi":"ess~en[_VVFIN][third][sg][pres][subjI]","w":0}],"msafe":1,"text":"esse","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"esse"}}
 5	delendam	delendam	X	FM.la	_	_	_	_	Translit=delendam|norm=delendam|details=* <0>|json={"dmoot":{"analyses":[{"details":"delendam","prob":0,"tag":"delendam"}],"morph":[{"hi":"[_FM][lat]","w":0}],"tag":"delendam"},"f":2,"lang":["la"],"lts":[{"hi":"delendam","w":0}],"mlatin":[{"hi":"[_FM][lat]","w":0}],"moot":{"analyses":[{"details":"[_FM][lat]","lemma":"delendam","prob":0,"tag":"FM"}],"details":{"details":"*","lemma":"delendam","prob":0,"tag":"FM.la"},"lemma":"delendam","tag":"FM.la","word":"delendam"},"msafe":1,"text":"delendam","xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"delendam"}}
 6	.	.	PUNCT	$.	_	_	_	_	Translit=.|norm=.|details=$. <0>|json={"dmoot":{"analyses":[{"details":".","prob":0,"tag":"."}],"morph":[{"hi":"$.","w":0}],"tag":"."},"errid":"ec","exlex":".","f":5318438,"lts":[{"hi":"","w":0}],"moot":{"analyses":[{"details":"$.","lemma":".","prob":0,"tag":"$."}],"details":{"details":"$.","lemma":".","prob":0,"tag":"$."},"lemma":".","tag":"$.","word":"."},"msafe":1,"text":".","toka":["$."],"tokpp":["$."],"xlit":{"isLatin1":1,"isLatinExt":1,"latin1Text":"."}}


=cut

##======================================================================
## Footer
##======================================================================
=pod

=head1 AUTHOR

Bryan Jurish E<lt>jurish@bbaw.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
