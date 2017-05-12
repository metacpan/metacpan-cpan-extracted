package CSS::Parse::PRDGrammar;

$VERSION = 1.01;

use strict;
use warnings;

$CSS::Parse::PRDGrammar::GRAMMAR = q!

  ##
  ## RULES
  ##
  stylesheet:		(
				WS 									{2;}
				| statement								{3;}
			)(s)										{$return = $all_rulesets;}
  stylesheet:		<rulevar: local $all_rulesets>
  statement:		ruleset 									{4;}
			| atrule									{5;}
  atrule:		ATKEYWORD WS(s?) any(s?) ( block | ';' WS(s?) )					{print "at-rule\\n"}
  block:		'{' WS(s?) ( any | block | ATKEYWORD WS(s?) | ';' )(s?) '}' WS(s?)		{print "block\\n"}
  ruleset:		selector(?) '{' WS(s?) declaration(?) ( 
				';' WS(s?) declaration(?) 						{6;}
			)(s?) '}' WS(s?)					{push @{$all_rulesets}, $ruleset; 1;}
  ruleset:		<rulevar: local $ruleset = new CSS::Style();>
  selector:		any(s)
					{
						$ruleset->add_selector(new CSS::Selector({'name' => $_})) 
						for(map{s/^\s*(.*?)\s*$/$1/;$_}split /\\s*,\\s*/, join('',@{$item[1]}));
						1;
					}
  declaration:		property ':' WS(s?) value
					{
						$ruleset->add_property(new CSS::Property({
							'property' => $item[1],
							'value' => $item[4],
						}));
						1;
					}
  declaration:		<rulevar: local $value>
  property:		IDENT OWS				{$return = $item[1]}
  value:		( 
				any 				{$return = $item[1]}
				| block 			{$return = $item[1]}
				| ATKEYWORD OWS 		{$return = $item[1].$item[2]}
			)(s)					{$return = join('',@{$item[1]})}
  any:			any_item OWS				{$return = $item[1].$item[2]}
  any_item:		URI					{$return = $item[1];}
			| IDENT 				{$return = $item[1];}
			| NUMBER 				{$return = $item[1];}
			| PERCENTAGE 				{$return = $item[1];}
			| DIMENSION 				{$return = $item[1];}
			| STRING				{$return = $item[1];}
			| HASH 					{$return = $item[1];}
			| UNICODERANGE 				{$return = $item[1];}
			| INCLUDES				{$return = $item[1];}
			| FUNCTION 				{$return = $item[1];}
			| DASHMATCH 				{$return = $item[1];}
			| '(' any(s?) ')' 			{$return = '('.join('',@{$item[2]}).')';}
			| '[' any(s?) ']' 			{$return = '['.join('',@{$item[2]}).']';}
			| DELIM 				{$return = $item[1];}

  ##
  ## TOKENS
  ##
  IDENT:		macro_ident					{$return = $item[1]}
  ATKEYWORD:		'@' macro_ident					{$return = '@'.$item[2]}
  STRING:		macro_string					{$return = $item[1]}
  HASH:			'#' macro_name					{$return = '#'.$item[2]}
  NUMBER:		macro_num					{$return = $item[1]}
  PERCENTAGE:		macro_num '%'					{$return = $item[1].'&'}
  DIMENSION:		macro_num macro_ident				{$return = $item[1].$item[2]}
  URI:			'url(' macro_w macro_string macro_w ')'		{$return = "url(".$item[3].")"}
			| 'url(' macro_w ( 
				/[\!#$%&*-~]/ 				{$return = $item[1]}
				| macro_nonascii 			{$return = $item[1]}
				| macro_escape				{$return = $item[1]}
			)(s?) macro_w ')'				{$return = "url(".join('',@{$item[3]}).")"}
  UNICODERANGE:		/U\\+[0-9A-F?]{1,6}(-[0-9A-F]{1,6})?/		{$return = $item[1]}
  WS:			/[ \\t\\r\\n\\f]+/				{$return = ' ';}
  OWS:			WS(s?)						{$return = ''; if (scalar(@{$item[1]}) > 0){$return = ' ';} 1;}
  FUNCTION:		macro_ident '('					{$return = $item[1].'('}
  INCLUDES:		'~='						{$return = $item[1]}
  DASHMATCH:		'|='						{$return = $item[1]}
  DELIM:		/[^0-9a-zA-Z\\{\\}\\(\\)\\[\\];]/		{$return = $item[1]}

  ##
  ## MACROS
  ##
  macro_ident:		macro_nmstart macro_nmchar(s?)		{$return = $item[1]; if (scalar(@{$item[2]}) > 0){$return .= join('',@{$item[2]});} 1;}
  macro_name:		macro_nmchar(s)				{$return = join('',@{$item[1]})}
  macro_nmstart:	/[a-zA-Z]/				{$return = $item[1]}
			| macro_nonascii			{$return = $item[1]}
			| macro_escape				{$return = $item[1]}
  macro_nonascii:	/[^\\0-\\177]/				{$return = $item[1]}
  macro_unicode:	/\\[0-9a-f]{1,6}[ \\n\\r\\t\\f]?/	{$return = $item[1]}
  macro_escape:		macro_unicode				{$return = $item[1]}
			| /\\\\[ -~\\200-\\4177777]/		{$return = $item[1]}
  macro_nmchar:		/[a-z0-9-]/				{$return = $item[1]}
			| macro_nonascii			{$return = $item[1]}
			| macro_escape				{$return = $item[1]}
  macro_num:		/[0-9]+|[0-9]*\\.[0-9]+/		{$return = $item[1]}
  macro_string:		macro_string1 				{$return = $item[1]}
			| macro_string2				{$return = $item[1]}
  macro_string1:	'"' ( 
				/[\\t \!#$%&(-~]/ 		{$return = $item[1]}
				| '\\\\' macro_nl 		{$return = ''}
				| "'" 				{$return = $item[1]}
				| macro_nonascii 		{$return = $item[1]}
				| macro_escape 			{$return = $item[1]}
			)(s?) '"'				{$return = '"'.join('', @{$item[2]}).'"'}
  macro_string2:	"'" ( 
				/[\\t \!#$%&(-~]/ 		{$return = $item[1]}
				| '\\\\' macro_nl 		{$return = ''}
				| '"' 				{$return = $item[1]}
				| macro_nonascii 		{$return = $item[1]}
				| macro_escape 			{$return = $item[1]}
			)(s?) "'"				{return "'".join('', @{$item[2]})."'"}
  macro_nl:		/\\n|\\r\\n|\\r|\\f/			{$return = $item[1]}
  macro_w:		/[ \\t\\r\\n\\f]*/			{$return = $item[1]}

!;

1;
__END__

=head1 NAME

CSS::Parse::PRDGrammar - A CSS grammar for Parse::RecDescent

=head1 SYNOPSIS

  use CSS;

=head1 DESCRIPTION

This module is used by CSS::Parse::Heavy and used to build CSS::Parse::Compiled

=head1 AUTHOR

Copyright (C) 2003-2004, Cal Henderson <cal@iamcal.com>

=head1 SEE ALSO

L<CSS>, L<CSS::Parse::Heavy>, L<CSS::Parse::Compiled>, http://www.w3.org/TR/REC-CSS1

=cut

