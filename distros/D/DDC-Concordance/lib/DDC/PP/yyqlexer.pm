##-*- Mode: CPerl -*-

## File: DDC::::yyqlexer.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description:
##  + lexer for ddc queries (formerly DDC::Query::yylexer)
##  + last updated for ddc v2.1.15
##======================================================================

package DDC::PP::yyqlexer;
use 5.010;  ##-- we need at least v5.10.0 for /p regex modifier
use Encode qw(encode_utf8 decode_utf8);
use Carp;
use IO::File;
use IO::Handle;
use strict;

##======================================================================
## Globals etc.
our @ISA = qw();

##----------------------------------------------------------------------
## Globals: regexes for Parse::Lex lexer token regexes

## %DEF
##   + common shared regex definitions
our (%DEF);
BEGIN {
  ##-- adapted from ddc-2.1.1/src/ConcordLib/yyQLexer.l ; extra escapes needed for backslashes ('\\' -> '\\\\')

  ##-- whitespace
  $DEF{ws} = '[ \t\n\r\f\x0b]';

  ##-- integer boundary characters
  $DEF{int_boundary} = '[ \t\n\r\f\x0b\0&|!?^%,:;#*=~(){}<>\[\]\/\\\\\'\".$@_+-]';

  ##-- bareword symbols
  $DEF{symbol_cfirst}  = '[^ \t\n\r\f\x0b\0&|!?^%,:;#*=~(){}<>\[\]\\\\\/\'\".$@]';
  $DEF{symbol_crest}   = '[^ \t\n\r\f\x0b\0&|!?^%,:;#*=~(){}<>\[\]\\\\\/\'\"]';
  $DEF{symbol_cescape} = '(?:\\\\.)';
  $DEF{symbol_text}    = "(?:$DEF{symbol_cescape}|$DEF{symbol_cfirst})(?:$DEF{symbol_cescape}|$DEF{symbol_crest})*";

  ##-- subcorpus symbols (ddc >= v2.2.0; also allow '!' here)
  $DEF{corpus_cfirst} =	'[^ \t\n\r\f\v\0&|?^%,:;#=~(){}<>\[\]\\\'\"$@]';
  $DEF{corpus_crest}  =	'[^ \t\n\r\f\v\0&|?^%,:;#=~(){}<>\[\]\\\'\"]';
  $DEF{corpus_text}   =	"(?:$DEF{symbol_cescape}|$DEF{corpus_cfirst})(?:$DEF{symbol_cescape}|$DEF{corpus_crest})*";

  ##-- bareword index names (underscore and digits ok, but no '.', '-', or '+')
  $DEF{index_char} = '[^ \t\n\r\f\x0b\0&|!?^%,:;#*=~(){}<>\[\]\\\\/\'\".$@+-]';
  $DEF{index_name} = "(?:$DEF{index_char}|$DEF{symbol_cescape})+";

  ##-- single-quoted symbols
  $DEF{sq_text} = "(?:[^\']|$DEF{symbol_cescape})*";

  ##-- bareword dates (>= 4 digits of year, otherwise breaks {count(...) #by[$w=1-1]})
  $DEF{date_bare} = "[+-]?[0-9]{4,}(-[0-9]{1,2}){1,2}";

  ##-- regexes
  $DEF{regex_text}     = "(?:(?:\\\\.)|[^\\\\/])*";
  $DEF{regex_modifier} = '[dgimsx]';

  ##-- comments
  $DEF{comment_text}   = "(?:\\\\.|[^\\]])*";

  ##-- compile patterns
  foreach (keys %DEF) {
    #print STDERR __PACKAGE__, ": compiling regex macro: $_ ~ /$DEF{$_}/\n";
    $DEF{$_} = qr/$DEF{$_}/;
  }
}

##======================================================================
## $lex = $CLASS_OR_OBJ->new(%args)
## + abstract constructor
## + %$lex, %args:
##   {
##    src  => $name,    ##-- source name
##    fh   => $srcfh,   ##-- source filehandle
##    bufr => \$buf,    ##-- source buffer (string reference)
##    bufp => $pos,     ##-- current pos() in source buffer
##    buf  => $buf,     ##-- local buffer (for filehandle input)
##    state => $q,      ##-- symbolic state name (default: 'INITIAL')
##    stack => \@stack, ##-- state stack
##
##    ##-- utf-8 or byte mode?
##    utf8 => $bool,    ##-- whether to use utf8 or byte-mode (default: true (non-compatible but handy))
##
##    ##-- runtime data
##    yytext => $text,  ##-- current text
##    yytype => $type,  ##-- current token type
##    yylineno => $line, ##-- current source line (file input only)
##   }
sub new {
  my $that = shift;
  my $lex = bless({
		   src =>undef,
		   fh   =>undef,
		   bufr =>undef,
		   bufp =>undef,
		   buf  =>undef,
		   utf8 =>1,
		   state => 'INITIAL',
		   stack => [],

		   yytext=>undef,
		   yytype=>undef,
		   yylineno=>undef,

		   ##-- lexer comment retention hacks
		   comments=>[],

		   ##-- user args
		   @_
		  },
		  ref($that)||$that
		 );
  return $lex;
}

## $lex = $lex->clear()
##  + clear lexer buffer, source, etc
sub clear {
  my $lex = shift;
  delete @$lex{qw(src fh bufr bufp buf yytext yytype yylineno)};
  $lex->{state} = 'INITIAL';
  @{$lex->{stack}} = qw();
  @{$lex->{comments}} = qw();
  delete $lex->{_cmtbuf};
  return $lex;
}
BEGIN { *reset = *close = \&clear; }

##======================================================================
## I/O

## $lex = $lex->from($which,$src, %opts)
##  + $which is one of qw(fh file string)
##  + $src is the actual source (default: 'string')
sub from {
  my ($lex,$which,$src,%opts) = @_;
  return $lex->fromFh($src,%opts) if ($which eq 'fh');
  return $lex->fromFile($src,%opts) if ($which eq 'file');
  return $lex->fromString($src,%opts);
}

## $lex = $lex->fromFile($filename_or_handle,%opts)
sub fromFile {
  my ($lex,$file,%opts) = @_;
  return $lex->fromFh($file,%opts) if (ref($file));
  my $fh = IO::File->new("<$file")
    or confess("cannot open '$file' for read: $!");
  binmode($fh,':encoding(utf8)') if ($lex->{utf8});
  return $lex->fromFh($fh,src=>"file \`$file'",%opts);
}

our $FH_SLURP=0; ##-- DEBUG: slurp whole files instead of line-wise input

## $lex = $lex->fromFh($fh,%opts)
##  + uses native $fh encoding
sub fromFh {
  my ($lex,$fh,%opts) = @_;
  if ($FH_SLURP) {
    ##-- always use string mode
    local $/=undef;
    my $buf = $fh->getline;
    $fh->close();
    return $lex->fromString(\$buf,src=>"filehandle \`$fh'",%opts);
  }
  ##-- line-wise buffering
  $lex->clear();
  @$lex{keys %opts} = values(%opts);
  $lex->{fh}   = $fh;
  $lex->{buf}  = undef;
  $lex->{bufr} = \$lex->{buf};
  $lex->{bufp} = 0;
  $lex->{src} = "filehandle \`$fh'" if (!defined($lex->{src}));
  return $lex;
}

## $lex = $lex->fromString($str,%opts)
## $lex = $lex->fromString(\$str,%opts)
sub fromString {
  my ($lex,$str,%opts) = @_;
  $lex->clear();
  if (ref($str)) {
    $lex->{bufr} = $str;
    $lex->{src} = "buffer \`$str'" if (!defined($lex->{src}));
  } else {
    $lex->{bufr} = \$str;
    $lex->{src} = "string \`$str'" if (!defined($lex->{src}));
  }
  $lex->{bufp} = 0;
  $lex->{yylineno} = 0;

  ##-- utf8 checks
  if ($lex->{utf8} && !utf8::is_utf8(${$lex->{bufr}})) {
    ##-- lexer:utf8, string:bytes --> assume string is utf8-encoded
    ${$lex->{bufr}} = decode_utf8(${$lex->{bufr}}) if (!utf8::is_utf8(${$lex->{bufr}}));
  }
  elsif (!$lex->{utf8} && utf8::is_utf8(${$lex->{bufr}})) {
    ##-- lexer:bytes, string:utf8 --> encode as utf8 octets
    ${$lex->{bufr}} = encode_utf8(${$lex->{bufr}});
  }

  return $lex;
}

##======================================================================
## Utilities

## $bool = $lex->eof()
##  + true iff at end-of-file
sub eof {
  return $FH_SLURP ? $_[0]->eob() : !$_[0]->getmore();
}

## $bool = $lex->eob()
##  + true at end-of-buffer
sub eob {
  return (!$_[0]{bufr} || !${$_[0]{bufr}} || ($_[0]{bufp}||0) >= length(${$_[0]{bufr}}));
}

## $bufr_or_undef = $lex->getmore()
##   + returns true iff there is still data in the buffer
sub getmore {
  return $_[0]{bufr} if (!$_[0]->eob());
  if (defined($_[0]{fh})) {
    $_[0]{bufp}     = 0;
    $_[0]{buf}      = $_[0]{fh}->getline;
    $_[0]{bufr}     = \$_[0]{buf};
    $_[0]{yylineno} = $_[0]{fh}->input_line_number;
    return defined($_[0]{buf}) ? $_[0]{bufr} : undef;
  }
  return undef;
}

##======================================================================
## Runtime lexer accessors

## $yytext = $lex->yytext
##  + always defined; otherwise using $lex->{yytext} is faster
sub yytext { return defined($_[0]{yytext}) ? $_[0]{yytext} : ''; }

## $yytype = $lex->yytype
##  + always defined; otherwise using $lex->{yytype} is faster
sub yytype { return defined($_[0]{yytype}) ? $_[0]{yytype} : '__EOF__'; }

## $line = $lex->yylineno()
##  + returns current line number
sub yylineno {
  return $_[0]{yylineno};
}

## $pos = $lex->yycolumn()
##  + return column at which current token starts (if any)
sub yycolumn {
  return ($_[0]{bufp}||0) - (defined($_[0]{yytext}) ? length($_[0]{yytext}) : 0);
}

## $pos = $lex->yypos()
##  + return byte position in current line (or input string)
sub yypos {
  return ($_[0]{bufp}||0);
}

## $string = $lex->yyerror(@msg)
##  + create a helpful error message
sub yyerror {
  my $lex = shift;
  confess(ref($lex).": error in ".$lex->yywhere().join('',@_));
}

## $string = $lex->yywhere()
##  + location string used by yyerror()
sub yywhere {
  my $lex = shift;
  return ("$lex->{src} at "
	  .(defined($lex->{fh}) ? ("line $lex->{yylineno}, ") : '')
	  ."column ".$lex->yycolumn
	  .", near ".(defined($lex->{yytext}) ? "\`$lex->{yytext}\'" : '__EOF__')
	 );
}

## $q = $lex->yypushq($new_state)
sub yypushq {
  my ($lex,$qnew) = @_;
  push(@{$lex->{stack}},$lex->{state});
  return $lex->{state} = $qnew;
}

## $q = $lex->yypopq()
sub yypopq {
  my $lex = shift;
  return $lex->{state} = pop(@{$lex->{stack}}) || 'INITIAL';
}

##======================================================================
## Runtime lexer routines

## ($typ,$text) = $lex->yylex()
##  + get next token from input stream
sub yylex {
  my $lex = shift;
  my ($bufr,$type,$text,$match,@part);
  #use re 'eval'; ##-- dangerous!
 LEXBUF:
  while (!$lex->eof()) {
    $bufr       = $lex->{bufr};
    pos($$bufr) = $lex->{bufp};

  LEXSKIP:
    ##------------------------------------
    ## LEXSKIP: main lexer loop
    while (1) {
      $type = $text = $match = undef;
      @part = qw();

      ##------------------------
      if ($lex->{state} eq 'INITIAL' || $lex->{state} eq 'Q_MATCHID') {

	##-- end-of-file (should be first pattern)
	if    ($$bufr =~ m/\G\z/)	{ $type = '__EOF__'; }

	##-- comments
	elsif ($$bufr =~ m/\G\#:[^\n]*/sp)	{ $type='__SKIP__'; push(@{$lex->{comments}},${^MATCH}."\n"); }
	elsif ($$bufr =~ m/\G\#\[/p)		{ $type='__SKIP__'; $lex->{_cmtbuf}=${^MATCH}; $lex->yypushq('Q_COMMENT'); }

	##-- operators
	elsif ($$bufr =~ m/\G\&\&/p)	{ $type = 'OP_BOOL_AND'; }
	elsif ($$bufr =~ m/\G\|\|/p)	{ $type = 'OP_BOOL_OR'; }
	elsif ($$bufr =~ m/\Gnear/pi)	{ $type = 'NEAR'; }
	elsif ($$bufr =~ m/\G(?:\!=|\&\!=|\&=\s*\!|\!with|with(?:out|\s*\!))/pi)	{ $type = 'WITHOUT'; }
	elsif ($$bufr =~ m/\G(?:\|=|withor|orwith|wor)/pi) 				{ $type = 'WITHOR'; }
	elsif ($$bufr =~ m/\G(?:\&=|with)/pi)						{ $type = 'WITH'; }
	elsif ($$bufr =~ m/\Gcount/pi)	{ $type = 'COUNT'; }
	elsif ($$bufr =~ m/\Gkeys/pi)	{ $type = 'KEYS'; }

	##-- count-by keywords
	elsif ($$bufr =~ m/\G(?:file|doc)_?id/pi) { $type = 'KW_FILEID'; }
	elsif ($$bufr =~ m/\G(?:file|doc)_?(?:name)?/pi) { $type = 'KW_FILENAME'; }
	elsif ($$bufr =~ m/\Gdate/pi) { $type = 'KW_DATE'; $lex->{state}='Q_DATE' }

	##-- query operators
	elsif ($$bufr =~ m/\G\#(?:comment|cmt)/pi)			{ $type = 'KW_COMMENT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:co?n?te?xt?|n))/pi)		{ $type = 'CNTXT'; }
	elsif ($$bufr =~ m/\G\#(?:with)?in/pi)				{ $type = 'WITHIN'; }
	elsif ($$bufr =~ m/\G\#(?:sep(?:arate)?|nojoin)(?:_hits)?/pi)	{ $type = 'SEPARATE_HITS'; }
	elsif ($$bufr =~ m/\G\#(?:nosep(?:arate)?|join)(?:_hits)?/pi)	{ $type = 'NOSEPARATE_HITS'; }
	elsif ($$bufr =~ m/\G\#(?:is_|has_)?date/pi)			{ $type = 'IS_DATE'; }
	elsif ($$bufr =~ m/\G\#has(?:_field)?/pi)			{ $type = 'HAS_FIELD'; }
	elsif ($$bufr =~ m/\G\#file(?:_?)names/pi)			{ $type = 'FILENAMES_ONLY'; }
	elsif ($$bufr =~ m/\G\#debug_rank/pi)				{ $type = 'DEBUG_RANK'; }
	elsif ($$bufr =~ m/\G\#(?:greater|de?sc)(?:_by)?_rank/pi)	{ $type = 'GREATER_BY_RANK'; }
	elsif ($$bufr =~ m/\G\#(?:less|asc)(?:_by)?_rank/pi)		{ $type = 'LESS_BY_RANK'; }
	elsif ($$bufr =~ m/\G\#(?:greater|de?sc)(?:_by)?_date/pi)	{ $type = 'GREATER_BY_DATE'; }
	elsif ($$bufr =~ m/\G\#(?:less|asc)(?:_by)?_date/pi)		{ $type = 'LESS_BY_DATE'; }
	elsif ($$bufr =~ m/\G\#(?:greater|de?sc)(?:_by)?_size/pi)	{ $type = 'GREATER_BY_SIZE'; }
	elsif ($$bufr =~ m/\G\#(?:less|asc)(?:_by)?_size/pi)		{ $type = 'LESS_BY_SIZE'; }
	elsif ($$bufr =~ m/\G\#(?:is_|has_)?size/pi)			{ $type = 'IS_SIZE'; }
	elsif ($$bufr =~ m/\G\#(?:(?:less|asc)_(?:by_)?)?left/pi)	{ $type = 'LESS_BY_LEFT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:greater|de?sc)_(?:by_)?)left/pi)	{ $type = 'GREATER_BY_LEFT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:less|asc)_(?:by_)?)?right/pi)	{ $type = 'LESS_BY_RIGHT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:greater|de?sc)_(?:by_)?)right/pi)	{ $type = 'GREATER_BY_RIGHT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:less|asc)_(?:by_)?)?mid(?:dle)?/pi)	{ $type = 'LESS_BY_MIDDLE'; }
	elsif ($$bufr =~ m/\G\#(?:(?:greater|de?sc)_(?:by_)?)mid(?:dle)?/pi)	{ $type = 'GREATER_BY_MIDDLE'; }
	elsif ($$bufr =~ m/\G\#(?:(?:less|asc)(?:_by)?_key)/pi)		{ $type = 'LESS_BY_KEY'; }
	elsif ($$bufr =~ m/\G\#(?:(?:greater|de?sc)(?:_by)?_key)/pi)	{ $type = 'GREATER_BY_KEY'; }
	elsif ($$bufr =~ m/\G\#(?:(?:less|asc)(?:_by)?_(?:count|val(?:ue)?))/pi)	{ $type = 'LESS_BY_COUNT'; }
	elsif ($$bufr =~ m/\G\#(?:(?:greater|de?sc)(?:_by)?_(?:count|val(?:ue)?))/pi) { $type = 'GREATER_BY_COUNT'; }
	elsif ($$bufr =~ m/\G\#(?:less|asc)(?:_by)?/pi)			{ $type = 'LESS_BY'; }
	elsif ($$bufr =~ m/\G\#(?:greater|de?sc)(?:_by)?/pi)		{ $type = 'GREATER_BY'; }
	elsif ($$bufr =~ m/\G\#rand(?:om)?/pi)				{ $type = 'RANDOM'; }
	elsif ($$bufr =~ m/\G\#by/pi)					{ $type = 'BY'; }
	elsif ($$bufr =~ m/\G\#samp(?:le)?/pi)				{ $type = 'SAMPLE'; }
	elsif ($$bufr =~ m/\G\#clim(?:it)?/pi)				{ $type = 'CLIMIT'; }

	##-- regexes
	elsif ($$bufr =~ m/\G\!\/($DEF{regex_text})\/(?=$DEF{regex_modifier})/po)	{ $type='NEG_REGEX'; $text=$1; $lex->{state}='Q_REGOPT'; }
	elsif ($$bufr =~ m/\G\!\/($DEF{regex_text})\//po)				{ $type='NEG_REGEX'; $text=$1; }
	elsif ($$bufr =~ m/\G\/($DEF{regex_text})\/(?=$DEF{regex_modifier})/po)		{ $type='REGEX';     $text=$1; $lex->{state}='Q_REGOPT'; }
	elsif ($$bufr =~ m/\G\/($DEF{regex_text})\//po)					{ $type='REGEX';     $text=$1; }
	elsif ($$bufr =~ m/\Gs\/($DEF{regex_text})\//po)				{ $type='REGEX_SEARCH'; $text=$1; $lex->{state}='Q_REGREP'; }

	##-- punctutation & special characters
	elsif ($$bufr =~ m/\G#=/p)				{ $type = 'HASH_EQUAL'; }	##-- hash+equal: exact distance
	elsif ($$bufr =~ m/\G#</p)				{ $type = 'HASH_LESS'; }	##-- hash+less: max distance
	elsif ($$bufr =~ m/\G#>/p)				{ $type = 'HASH_GREATER'; }	##-- hash+greater: min distance
	elsif ($$bufr =~ m/\G\$\./p)				{ $type = 'DOLLAR_DOT'; }	##-- positional anchor pseudo-index
	elsif ($$bufr =~ m/\G\:\{/p)				{ $type = 'COLON_LBRACE'; }	##-- theusaurus-query operator
	elsif ($$bufr =~ m/\G\@\{/p)				{ $type = 'AT_LBRACE'; }	##-- literal-set operator
	elsif ($$bufr =~ m/\G\*\{/p)				{ $type = 'STAR_LBRACE'; }	##-- prefix-set opener
	elsif ($$bufr =~ m/\G\}\*/p)				{ $type = 'RBRACE_STAR'; }	##-- suffix-set closer
	elsif ($$bufr =~ m/\G[!.,;=@%^#~\/]/p)			{ $type = ${^MATCH}; } ##-- single-char punctuation operators
	elsif ($$bufr =~ m/\G[\[\]{}()<>]/p)			{ $type = ${^MATCH}; } ##-- parentheses
	elsif ($$bufr =~ m/\G\"/p)				{ $type = ${^MATCH}; } ##-- double-quotes

	##-- subcorpus path-lists
	elsif ($$bufr =~ m/\G\:/p)				{ $type = ${^MATCH}; $lex->{state}='Q_CORPORA'; }

	##-- truncated symbols
	elsif ($$bufr =~ m/\G\*\'($DEF{sq_text})\'\*/po) { $type='INFIX';  $text=$1; }	##-- dual-truncated quoted string (infix symbol)
	elsif ($$bufr =~ m/\G\'($DEF{sq_text})\'\*/po)	 { $type='PREFIX'; $text=$1; }	##-- right-truncated quoted string (prefix symbol)
	elsif ($$bufr =~ m/\G\*\'($DEF{sq_text})\'/po)	 { $type='SUFFIX'; $text=$1; }	##-- left-truncated quoted string (suffix symbol)

	elsif ($$bufr =~ m/\G\*($DEF{symbol_text})\*/po) { $type='INFIX';  $text=$1; }	##-- dual-truncated bareword (infix symbol)
	elsif ($$bufr =~ m/\G($DEF{symbol_text})\*/po)	 { $type='PREFIX'; $text=$1; }	##-- right-truncated bareword (prefix symbol)
	elsif ($$bufr =~ m/\G\*($DEF{symbol_text})/po)	 { $type='SUFFIX'; $text=$1; }	##-- left-truncated bareword (suffix symbol)

	##-- index names (special handling to allow count(foo) #by[$w-1]
	elsif ($$bufr =~ m/\G\$($DEF{index_name})/po)	{ $type='INDEX'; $text=$1; }
	elsif ($$bufr =~ m/\G\$'($DEF{index_name})'/po)	{ $type='INDEX'; $text=$1; }
	elsif ($$bufr =~ /m\G\$/p)			{ $type='$'; }

	##-- numeric tokens (handled below with symbols for perl lexer w/o longest-match)

	##-- single-term wildcard
	elsif ($$bufr =~ m/\G\*/p)     			{ $type = '*'; }

	##-- term expander pipelines
	elsif ($$bufr =~ m/\G\|/p) 			{ $lex->{state}='Q_XPIPE'; $type='__SKIP__'; }

	##-- symbols: quoted
	elsif ($$bufr =~ m/\G\'($DEF{sq_text})\'/po) {
	  $text = $1;
	  if    ($text =~ m/^[\+\-]?[0-9]+\z/)			{ $type='INTEGER'; }
	  elsif ($text =~ m/^[0-9-]+\z/)			{ $type='DATE'; }
	  else							{ $type='SYMBOL'; }
	}
	##-- symbols: barewords
	elsif ($lex->{state} eq 'INITIAL' && $$bufr =~ m/\G$DEF{symbol_text}/po) {
	  $text  = ${^MATCH};
	  $match = ${^MATCH};
	  if    ($text =~ m/^[\+\-]?[0-9]+\z/)			{ $type='INTEGER'; }
	  elsif ($text =~ m/^[0-9-]+\z/)			{ $type='DATE'; }
	  else							{ $type='SYMBOL'; }
	}
	##-- barewords: integers and dates (Q_MATCHID)
	elsif ($lex->{state} ne 'INITIAL' && $$bufr =~ m/\G[\+\-]?[0-9]+(?=$DEF{int_boundary})/po)	{ $type='INTEGER'; }
	elsif ($lex->{state} ne 'INITIAL' && $$bufr =~ m/\G[\+\-]?[0-9]+\z/p)				{ $type='INTEGER'; }

	elsif ($lex->{state} ne 'INITIAL' && $$bufr =~ m/\G$DEF{date_bare}(?=$DEF{int_boundary})/po)	{ $type='DATE'; }
	elsif ($lex->{state} ne 'INITIAL' && $$bufr =~ m/\G$DEF{date_bare}\z/po)			{ $type='DATE'; }

	##-- misc
	elsif ($$bufr =~ m/\G\s+/p)	{ $type = '__SKIP__'; }
	#elsif ($$bufr =~ m/\G./p)	{ $type = 'SYMBOL'; }
	elsif ($$bufr =~ m/\G./p)	{ $type = '__ERROR__'; }

	$match = ${^MATCH} if (!defined($match));
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_CORPORA') {
	if    ($$bufr =~ m/\G$DEF{corpus_text}/p)	{ $type='SYMBOL'; }
	elsif ($$bufr =~ m/\G\'($DEF{sq_text})\'/po)	{ $type='SYMBOL'; $text=$1; }
	elsif ($$bufr =~ m/\G\,/p)			{ $type=${^MATCH}; }
	elsif ($$bufr =~ m/\G\s+/p)			{ $type='__SKIP__'; }
	else						{ $type='__SKIP__'; $lex->yypopq(); }

	$match = ${^MATCH};
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_COMMENT') {
	if    ($$bufr =~ m/\G\]/p)		    {
	  $type='__SKIP__';
	  $lex->{_cmtbuf} .= ${^MATCH};
	  push(@{$lex->{comments}}, $lex->{_cmtbuf});
	  delete $lex->{_cmtbuf};
	  $lex->yypopq();
	}
	elsif ($$bufr =~ m/\G$DEF{comment_text}/sp) { $type='__SKIP__'; $lex->{_cmtbuf} .= ${^MATCH}; }
	else                                        { $type='__ERROR__'; }

	$match = ${^MATCH};
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_DATE') {
	if    ($$bufr =~ m/^\s+/) { $type = '__SKIP__'; }
	elsif ($$bufr =~ m/^\//)  { $type = '/'; $lex->{state}='INITIAL'; }
	else                      { $lex->{state}='INITIAL'; $type='__SKIP__'; }

	$match = ${^MATCH};
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_REGREP') {
      	if    ($$bufr =~ m/\G($DEF{regex_text})\/(?=$DEF{regex_modifier})/po)	{ $type='REGEX_REPLACE'; $text=$1; $lex->{state}='Q_REGOPT'; }
	elsif ($$bufr =~ m/\G($DEF{regex_text})\//po)				{ $type='REGEX_REPLACE'; $text=$1; $lex->{state}='INITIAL';  }

	$match = ${^MATCH};
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_REGOPT') {
	if ($$bufr =~ m/\G$DEF{regex_modifier}+/po)	{ $type='REGOPT'; }
	else						{ $type='__SKIP__'; }
	$lex->{state} = 'INITIAL';

	$match = ${^MATCH};
      }
      ##------------------------
      elsif ($lex->{state} eq 'Q_XPIPE') {
	if ($$bufr =~ m/\G\s+/p)		 { $type = '__SKIP__'; }	##-- whitespace: skip
	elsif ($$bufr =~ m/\G\-/p)		 { $lex->{state}='INITIAL'; $type='EXPANDER'; }
	elsif ($$bufr =~ m/\G\'($DEF{sq_text})\'/po) { $lex->{state}='INITIAL'; $type='EXPANDER'; $text=$1; }
	elsif ($$bufr =~ m/\G$DEF{symbol_text}/po) { $lex->{state}='INITIAL'; $type='EXPANDER'; }
	#elsif ($$bufr =~ m/\G\z/p)		 { $lex->{state}='INITIAL'; $type='EXPANDER'; }
	else					 { $lex->{state}='INITIAL'; $type='EXPANDER'; $text=''; }

	$match = ${^MATCH};
      }
      ##------------------------
      ## END perl-ification of flex sources

      ##-- guts
      $text = $match if (!defined($text));
      $lex->{bufp} += length($match) if (defined($match));

      pos($$bufr) = $lex->{bufp};
      return if (!defined($type));

      next LEXSKIP if ($type eq '__SKIP__');
      next LEXBUF  if ($type eq '__EOF__');
      #elsif ($type eq '__ERROR__') {
      #  return $lex->yyerror();
      #}
      return @$lex{qw(yytype yytext)} = ($type,$text);
    }
  }
  return @$lex{qw(yytype yytext)} = ('__EOF__',undef);
}

##======================================================================
## Testing: dummy lexing

## undef = $lex->dummylex(@from_whatever)
sub dummylex {
  my $lex = shift;
  $lex->reset();
  $lex->from(@_);
  my ($type,$text);
 TOKEN:
  while(1) {
    ($type,$text) = $lex->yylex();
    print("-" x 64, "\n",
	  ">>  Line: ",  $lex->yylineno, ", Pos: ", $lex->yypos, "\n",
	  ">>  State: ",  (defined($lex->{state}) ? $lex->{state} : '(undef)'), "\n",
	  ">>  Type: ",  (defined($type) ? $type : '(undef)'), "\n",
	  ">>  Text: ", (defined($text) ? $text : '(undef)'), "\n",
	 );
    if (!defined($type)) {
      warn(":: undef type!");
      return;
    }
    if ($type eq '__ERROR__') {
      print(":: ERROR DETECTED\n");
      $lex->yyerror();
    }
    last if ($type eq '__EOF__');
  }
}


1; ##-- be happy

__END__

##========================================================================
## NAME
=pod

=head1 NAME

DDC::PP::yyqlexer - query lexer (low-level)

=cut


##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011-2020 by Bryan Jurish

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::PP::CQueryCompiler(3perl).

=cut
