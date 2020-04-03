##-*- Mode: CPerl -*-
##
## File: DDC::PP::CQueryCompiler.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: pure-perl DDC query parser, top-level
##======================================================================

package DDC::PP::CQueryCompiler;
use DDC::Utils qw(:escape);
use DDC::PP::Constants;
use DDC::PP::Object;
use DDC::PP::CQuery;
use DDC::PP::CQCount;
use DDC::PP::CQFilter;
use DDC::PP::CQueryOptions;

use DDC::PP::yyqlexer;
use DDC::PP::yyqparser;

use strict;

##======================================================================
## Globals etc.
our @ISA = qw(DDC::PP::Object);


##======================================================================
## $qc = $CLASS_OR_OBJ->new(%args)
## + abstract constructor
## + object structure, %args:
##   {
##    ##-- DDC::XS::CQueryCompiler emulation
##    Query => $query,		##-- last query parsed
##
##    ##-- guts: status flags
##    error => $current_errstr, ##-- false indicates no error
##
##    ##-- guts: underlying lexer/parser pair
##    lexer  => $yylexer,   ##-- a DDC::PP::yyqlexer object
##    parser => $yyparser,  ##-- a DDC::PP::yyqparser object
##    yydebug => $mask,     ##-- yydebug value
##
##    ##-- guts: closures
##    yylex    => \&yylex,   ##-- yapp-friendly lexer sub
##    yyerror  => \&yyerror, ##-- yapp-friendly parser sub
##   }
sub new {
  my $that = shift;
  my $qc = bless({
		  ##-- DDC::XS emulation
		  Query => undef,
		  KeepLexerComments => 0,

		  ##-- guts: status flags
		  error => undef,

		  ##-- guts: underlying lexer/parser pair
		  lexer  => DDC::PP::yyqlexer->new(),
		  parser => DDC::PP::yyqparser->new(),

		  ##-- guts: runtime data
		  qopts => undef,

		  ##-- parser debugging
		  yydebug  => 0, # no debug
		  #yydebug => 0x01,  # lexer debug
		  #yydebug => 0x02,  # state info
		  #yydebug => 0x04,  # driver actions (shift/reduce/etc.)
		  #yydebug => 0x08,  # stack dump
		  #yydebug => 0x10,  # Error recovery trace
		  #yydebug => 0x01 | 0x02 | 0x04 | 0x08, # almost everything
		  #yydebug => 0xffffffff, ##-- pretty much everything

		  ##-- User args
		  @_
		 },
		 ref($that)||$that);
  $qc->getClosures();
  return $qc;
}

## undef = $qc->free()
##  + clears $qc itself, as well as $qc->{parser}{USER}
##  + makes $qc subsequently useless, but destroyable
sub free {
  my $qc = shift;
  delete($qc->{parser}{USER}) if ($qc->{parser});
  %$qc = qw();
}

## $qc = $qc->getClosures()
##  + compiles lexer & parser closures
sub getClosures {
  my $qc = shift;
  delete(@$qc{qw(yylex yyerror)});
  $qc->{yylex}   = $qc->_yylex_sub();
  $qc->{yyerror} = $qc->_yyerror_sub();
  return $qc;
}

##======================================================================
## DDC::XS emulation

__PACKAGE__->defprop('Query');
__PACKAGE__->defprop('KeepLexerComments');

## undef = $qc->CleanParser()
##  + reset all parse-relevant data structures
sub CleanParser { $_[0]->reset; }

## $CQuery = $qc->ParseQuery($qstr)
sub ParseQuery {
  my ($qc,$qstr) = @_;
  $qc->{Query} = eval { $qc->parse(string=>\$qstr); };
  die(__PACKAGE__."::ParseQuery() failed: could not parse query: $@") if ($@);
  return $qc->{Query};
}

## $s = $qc->QueryToString()
sub QueryToString { return $_[0]->getQuery->toStringFull(); }

## $s = $qc->QueryToJson()
sub QueryToJson {
  return "{\"Query\":".$_[0]->getQuery->toJson().",\"Options\":".$_[0]->getQuery->getOptions->toJson()."}";
}


##======================================================================
## Local API: Input selection

## undef = $qc->reset()
##  + reset all parse-relevant data structures
sub reset {
  my $qc = shift;

  ##-- runtime data
  delete(@$qc{qw(Query qopts)});

  ##-- lexer & parser state
  $qc->{lexer}->reset();

  delete($qc->{parser}{USER}{hint});
  $qc->{parser}{USER}{qc}      = $qc;
  $qc->{parser}{USER}{lex}     = $qc->{lexer};

}

## $qc = $qc->from($which,$src, %opts)
##  + wraps $qc->{lexer}->from()
##  + $which is one of qw(fh file string)
##  + $src is the actual source (default: 'string')
##  + %opts may contain (src=>$name)
sub from {
  return $_[0]{lexer}->from(@_[1..$#_]) ? $_[0] : undef;
}

## $qc = $qc->fromFile($filename_or_handle,%opts)
##  + wraps $qc->{lexer}->fromFile()
sub fromFile {
  return $_[0]{lexer}->fromFile(@_[1..$#_]) ? $_[0] : undef;
}

## $qc = $qc->fromFh($fh,%opts)
##  + wraps $qc->{lexer}->fromFh()
sub fromFh {
  return $_[0]{lexer}->fromFh(@_[1..$#_]) ? $_[0] : undef;
}

## $qc = $qc->fromString($str,%opts)
## $qc = $qc->fromString(\$str,%opts)
##  + wraps $qc->{lexer}->fromString()
sub fromString {
  return $_[0]{lexer}->fromString(@_[1..$#_]) ? $_[0] : undef;
}


##======================================================================
## Local API: High-level Parsing

## $query_or_undef = $qc->parse(string=>$str)
## $query_or_undef = $qc->parse(string=>\$str)
## $query_or_undef = $qc->parse(file=>$filename)
## $query_or_undef = $qc->parse(fh=>$handle)
sub parse {
  my $qc = shift;
  $qc->reset();
  $qc->from(@_);
  my $result = eval { $qc->yyparse(); };
  my $err    = $@;
  delete($qc->{parser}{qc});       ##-- chop circular reference we know how to get at...
  delete($qc->{parser}{USER}{qc}); ##-- chop circular reference we know how to get at...

  ##-- adopt lexer comments
  $result->{Options}{LexerComments} = $qc->{lexer}{comments}
    if ($qc->{KeepLexerComments} && $result && $result->{Options});

  ##-- how'd it go?
  die($err) if ($err);
  return $result;
}

## $query_or_undef = $qc->yyparse()
##  + parses from currently selected input source; no reset or error catching
sub yyparse {
  my $qc = shift;
  return $qc->{parser}->YYParse(
				yylex   => $qc->{yylex},
				yyerror => $qc->{yyerror},
				yydebug => $qc->{yydebug},
			       );
}

##======================================================================
## Local API: Mid-level: Query Generation

## $q = $qc->newq($class,@args)
##  + wrapper for "DDC::PP::$class"->new(@args); called by yapp parser
sub newq {
  return "DDC::PP::$_[1]"->new(@_[2..$#_]);
}

## $qf = $qc->newf(@args)
##  + wrapper for DDC::Query::Filter->new(@args); called by yapp parser
sub newf {
  return "DDC::PP::$_[1]"->new(@_[2..$#_]);
}

## $re = $qc->newre($re,$modifiers)
sub newre {
  my ($qc,$re,$mods) = @_;
  if (($mods||'') =~ /g/) {
    $re   = "^(?:${re})\$";
    $mods =~ s/g//g;
  }
  return $re if (!$mods);
  return "(?:${mods})$re";
}

## $qo = $qc->qopts()
## $qo = $qc->qopts($opts)
##  + get/set current query options
sub qopts {
  $_[0]{qopts} = $_[1] if ($_[1]);
  $_[0]{qopts} = DDC::PP::CQueryOptions->new if (!defined($_[0]{qopts}));
  return $_[0]{qopts};
}


##======================================================================
## API: Low-LEVEL: Parse::Lex <-> Parse::Yapp interface
##
## - REQUIREMENTS on yylex() sub:
##   + Yapp-compatible lexing routine
##   + reads input and returns token values to the parser
##   + our only argument ($MyParser) is the YYParser object itself
##   + We return a list ($TOKENTYPE, $TOKENVAL) of the next tokens to the parser
##   + on end-of-input, we should return the list ('', undef)
##

## \&yylex_sub = $qc->_yylex_sub()
##   + returns a Parse::Yapp-friendly lexer subroutine
sub _yylex_sub {
  my $qc = shift;
  my ($type,$text,@expect);

  return sub {
    $qc->{yyexpect} = [$qc->{parser}->YYExpect];
    ($type,$text) = $qc->{lexer}->yylex();
    return ('',undef) if ($type eq '__EOF__');

    ##-- un-escape single-quoted symbols (this happens in the parser)
    #    if ($type =~ /^SQ_(.*)$/) {
    #      $type = $1;
    #      $text = unescapeq($text);
    #    }
    #    elsif ($type eq 'SYMBOL') {
    #      $text = unescape($text);
    #    }

    if ($qc->{yydebug} & 0x01) {
      print STDERR ": yylex(): type=($type) ; text=(".(defined($text) ? $text : '-undef-')." ; state=(".($qc->{lexer}{state}).")\n";
    }

    return ($type,$text);
  };
}


## \&yyerror_sub = $qc->_yyerror_sub()
##  + returns error subroutine for the underlying Yapp parser
sub _yyerror_sub {
  my $qc = shift;
  my (%expect,@expecting);
  return sub {
    @expect{@{$qc->{yyexpect}||[]}}=qw();
    @expect{@{$qc->{yyexpect}||[]}, $qc->{parser}->YYExpect}=qw();
    @expecting = sort map {$_ eq '' ? '$end' : $_} keys %expect;
    die("syntax error, unexpected ".$qc->{lexer}->yytype
	.", expecting ".join(' or ', @expecting)
	." at line ".$qc->{lexer}->yylineno
	.", near token \`".$qc->{lexer}->yytext."'");
    #    $qc->{error} = ("syntax error in ".$qc->{lexer}->yywhere().":\n"
    #		    #." > Expected one of (here): ".join(', ', map {$_ eq '' ? '__EOF__' : $_} $qc->{parser}->YYExpect)."\n"
    #		    #." > Expected one of (prev): ".join(', ', map {$_ eq '' ? '__EOF__' : $_} @{$qc->{yyexpect}||['???']})."\n"
    #		    ." > Expected one of: ".join(', ', sort map {$_ eq '' ? '__EOF__' : $_} keys %expect)."\n"
    #		    ." > Got: ".$qc->{lexer}->yytype.' "'.$qc->{lexer}->yytext."\"\n"
    #               );
  };
}


1; ##-- be happy

__END__

##========================================================================
## POD DOCUMENTATION, auto-generated by podextract.perl

##========================================================================
## NAME
=pod

=head1 NAME

DDC::PP::CQuery - pure-perl implementation of DDC::XS::CQueryCompiler

=cut

##========================================================================
## SYNOPSIS
=pod

=head1 SYNOPSIS

 ##========================================================================
 ## PRELIMINARIES
 
 use DDC::PP::CQueryCompiler;
 #... stuff happens ...

=cut

##========================================================================
## DESCRIPTION
=pod

=head1 DESCRIPTION

The DDC::PP::CQuery class is a pure-perl fork of the L<DDC::XS::CQueryCompiler|DDC::XS::CQueryCompiler> class,
which see for details.

=cut

##========================================================================
## END POD DOCUMENTATION, auto-generated by podextract.perl

##======================================================================
## Footer
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2011-2017, Bryan Jurish.  All rights reserved.

This package is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
DDC::PP(3perl),
DDC::XS::CQueryCompiler(3perl)

=cut
