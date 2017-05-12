#-*- perl -*-
#-*- coding: us-ascii -*-

use 5.005;    # qr{} is required.

package CSS::Janus::Consts;

use strict;
#use warnings;

# To be compatible with Perl 5.5 or earlier
my @OUR_VARS;

BEGIN {
    @OUR_VARS = qw($NON_ASCII $UNICODE $ESCAPE $NMSTART $URL_SPECIAL_CHARS
	$NMCHAR $STRING1 $STRING2 $COMMENT $IDENT $NAME $NUM $STRING
	$URL_CHARS $HASH $URI
	$UNIT $QUANTITY $LOOKBEHIND_NOT_LETTER $LOOKAHEAD_NOT_OPEN_BRACE
	$VALID_AFTER_URI_CHARS $LOOKAHEAD_NOT_CLOSING_PAREN
	$LOOKAHEAD_FOR_CLOSING_PAREN $POSSIBLY_NEGATIVE_QUANTITY
	$FOUR_NOTATION_QUANTITY_RE $COLOR $FOUR_NOTATION_COLOR_RE
	$BORDER_RADIUS_RE $CURSOR_EAST_RE $CURSOR_WEST_RE
	$BG_HORIZONTAL_PERCENTAGE_RE $BG_HORIZONTAL_PERCENTAGE_X_RE
	$LENGTH_UNIT $LOOKAHEAD_END_OF_ZERO $LENGTH $ZERO_LENGTH
	$BG_HORIZONTAL_LENGTH_RE $BG_HORIZONTAL_LENGTH_X_RE
	$CHARS_WITHIN_SELECTOR $BODY_DIRECTION_LTR_RE $BODY_DIRECTION_RTL_RE
	$LEFT_RE $RIGHT_RE $LEFT_IN_URL_RE $RIGHT_IN_URL_RE
	$LTR_IN_URL_RE $RTL_IN_URL_RE
	$COMMENT_RE $NOFLIP_SINGLE_RE $NOFLIP_CLASS_RE
	$BORDER_RADIUS_TOKENIZER_RE);
}
use vars qw(@ISA @EXPORT $VERSION), @OUR_VARS;
use Exporter;
@ISA    = qw(Exporter);
@EXPORT = @OUR_VARS;
$VERSION = '0.01';

## Constants

# These are part of grammer taken from http://www.w3.org/TR/CSS21/grammar.html

# nonascii      [\240-\377]
# $NON_ASCII = '[\200-\377]';
# modified: handle characters beyond \377.
$NON_ASCII = "[^\\000-\\177]";

# unicode       \\{h}{1,6}(\r\n|[ \t\r\n\f])?
$UNICODE = "(?:(?:\\\\[0-9a-f]{1,6})(?:\\r\\n|[ \\t\\r\\n\\f])?)";

# escape        {unicode}|\\[^\r\n\f0-9a-f]
$ESCAPE = "(?:$UNICODE|\\\\[^\\r\\n\\f0-9a-f])";

# nmstart       [_a-z]|{nonascii}|{escape}
$NMSTART = "(?:[_a-z]|$NON_ASCII|$ESCAPE)";

# nmchar        [_a-z0-9-]|{nonascii}|{escape}
$NMCHAR = "(?:[_a-z0-9-]|$NON_ASCII|$ESCAPE)";

# string1       \"([^\n\r\f\\"]|\\{nl}|{escape})*\"
$STRING1 = "\"(?:[^\"\\\\]|\\.)*\"";

# string2       \'([^\n\r\f\\']|\\{nl}|{escape})*\'
$STRING2 = "\'(?:[^\'\\\\]|\\.)*\'";

# comment       \/\*[^*]*\*+([^/*][^*]*\*+)*\/
$COMMENT = '/\*[^*]*\*+([^/*][^*]*\*+)*/';

# ident         -?{nmstart}{nmchar}*
$IDENT = "-?$NMSTART$NMCHAR*";

# name          {nmchar}+
$NAME = "$NMCHAR+";

# num           [0-9]+|[0-9]*"."[0-9]+
$NUM = '(?:[0-9]*\.[0-9]+|[0-9]+)';

# string        {string1}|{string2}
$STRING = "(?:$STRING1|$STRING2)";

# url           ([!#$%&*-~]|{nonascii}|{escape})*
$URL_SPECIAL_CHARS = '[!#$%&*-~]';
$URL_CHARS         = "(?:$URL_SPECIAL_CHARS|$NON_ASCII|$ESCAPE)*";

# "#"{name}     {return HASH;}
$HASH = "#$NAME";

# "url("{w}{string}{w}")" {return URI;}
# "url("{w}{url}{w}")"    {return URI;}
$URI = "url\\(\\s*(?:$STRING|$URL_CHARS)\\s*\\)";

# These are regexps particular to this package.

$UNIT     = '(?:em|ex|px|cm|mm|in|pt|pc|deg|rad|grad|ms|s|hz|khz|%)';
$QUANTITY = "$NUM(?:\\s*$UNIT|$IDENT)?";

$LOOKBEHIND_NOT_LETTER = '(?<![a-zA-Z])';
$LOOKAHEAD_NOT_OPEN_BRACE =
    "(?!(?:$NMCHAR|~J~|\\s|#|\\:|\\.|\\,|\\+|>)*?\\{)";
$VALID_AFTER_URI_CHARS       = '[\'\"]?\s*';
$LOOKAHEAD_NOT_CLOSING_PAREN = "(?!$URL_CHARS?$VALID_AFTER_URI_CHARS\\))";
$LOOKAHEAD_FOR_CLOSING_PAREN = "(?=$URL_CHARS?$VALID_AFTER_URI_CHARS\\))";

$POSSIBLY_NEGATIVE_QUANTITY = "((?:-?$QUANTITY)|(?:inherit|auto))";
$FOUR_NOTATION_QUANTITY_RE =
    qr<$POSSIBLY_NEGATIVE_QUANTITY\s+$POSSIBLY_NEGATIVE_QUANTITY\s+$POSSIBLY_NEGATIVE_QUANTITY\s+$POSSIBLY_NEGATIVE_QUANTITY>i;

# $COLOR = "($NAME|$HASH);
# modified: added "rgb(...)".
my $COLOR_SCHEME = '(?:rgb|rgba|hsl|hsla)';
$COLOR = "($COLOR_SCHEME\\([^\)]+\\)|$NAME|$HASH)";
$FOUR_NOTATION_COLOR_RE =
    qr<(-color\s*:\s*)$COLOR\s$COLOR\s$COLOR\s($COLOR)>i;

$BORDER_RADIUS_RE =
    qr<((?:$IDENT)?)border-radius(\s*:\s*)(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY)(?:\s*/\s*(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY\s+)?(?:$POSSIBLY_NEGATIVE_QUANTITY))?>i;

$CURSOR_EAST_RE = qr<$LOOKBEHIND_NOT_LETTER([ns]?)e-resize>;
$CURSOR_WEST_RE = qr<$LOOKBEHIND_NOT_LETTER([ns]?)w-resize>;

# Term of background property.  Gradirents may not be included because they
# will have been tokenized.
my $BG_TERM = "(?:$URI|$STRING|$COLOR_SCHEME\\([^\)]+\\)|[^\\s;\}]+)";

#$BG_HORIZONTAL_PERCENTAGE_RE =
#    qr<background(-position)?(\s*:\s*)([^%]*?)($NUM)%(\s*(?:$POSSIBLY_NEGATIVE_QUANTITY|top|center|bottom))>;
# modified: fixed cssjanus Issue #20.
$BG_HORIZONTAL_PERCENTAGE_RE =
    qr<background(-position)?(\s*:\s*)((?:$BG_TERM\s+)*?)($NUM)%(\s*(?:$POSSIBLY_NEGATIVE_QUANTITY|top|center|bottom))>;
$BG_HORIZONTAL_PERCENTAGE_X_RE = qr<background-position-x(\s*:\s*)($NUM)%>;

$LENGTH_UNIT           = '(?:em|ex|px|cm|mm|in|pt|pc)';
$LOOKAHEAD_END_OF_ZERO = '(?![0-9]|\s*%)';
$LENGTH      = "(?:-?$NUM(?:\\s*$LENGTH_UNIT)|0+$LOOKAHEAD_END_OF_ZERO)";
$ZERO_LENGTH = "(?:-?0+(?:\\s*$LENGTH_UNIT)|0+$LOOKAHEAD_END_OF_ZERO)\$";

# $BG_HORIZONTAL_LENGTH_RE =
#    qr<background(-position)?(\s*:\s*)((?:.+?\s+)??)($LENGTH)((?:\s+)(?:$POSSIBLY_NEGATIVE_QUANTITY|top|center|bottom))>;
# modified: fixed cssjanus Issue #20.
$BG_HORIZONTAL_LENGTH_RE =
    qr<background(-position)?(\s*:\s*)((?:$BG_TERM\s+)*?)($LENGTH)((?:\s+)(?:$POSSIBLY_NEGATIVE_QUANTITY|top|center|bottom))>;
$BG_HORIZONTAL_LENGTH_X_RE = qr<background-position-x(\s*:\s*)($LENGTH)>;

$CHARS_WITHIN_SELECTOR = '[^\}]*?';
$BODY_DIRECTION_LTR_RE =
    qr<(body\s*{\s*)($CHARS_WITHIN_SELECTOR)(direction\s*:\s*)(ltr)>i;
$BODY_DIRECTION_RTL_RE =
    qr<(body\s*{\s*)($CHARS_WITHIN_SELECTOR)(direction\s*:\s*)(rtl)>i;

$LEFT_RE =
    qr<$LOOKBEHIND_NOT_LETTER((?:top|bottom)?)(left)$LOOKAHEAD_NOT_CLOSING_PAREN$LOOKAHEAD_NOT_OPEN_BRACE>i;
$RIGHT_RE =
    qr<$LOOKBEHIND_NOT_LETTER((?:top|bottom)?)(right)$LOOKAHEAD_NOT_CLOSING_PAREN$LOOKAHEAD_NOT_OPEN_BRACE>i;
$LEFT_IN_URL_RE =
    qr<$LOOKBEHIND_NOT_LETTER(left)$LOOKAHEAD_FOR_CLOSING_PAREN>i;
$RIGHT_IN_URL_RE =
    qr<$LOOKBEHIND_NOT_LETTER(right)$LOOKAHEAD_FOR_CLOSING_PAREN>i;
$LTR_IN_URL_RE = qr<$LOOKBEHIND_NOT_LETTER(ltr)$LOOKAHEAD_FOR_CLOSING_PAREN>i;
$RTL_IN_URL_RE = qr<$LOOKBEHIND_NOT_LETTER(rtl)$LOOKAHEAD_FOR_CLOSING_PAREN>i;

$COMMENT_RE = qr<($COMMENT)>i;
$NOFLIP_SINGLE_RE =
    qr<(/\*\s*\@noflip\s*\*/$LOOKAHEAD_NOT_OPEN_BRACE[^;}]+;?)>i;
$NOFLIP_CLASS_RE = qr<(/\*\s*\@noflip\s*\*/$CHARS_WITHIN_SELECTOR})>i;
$BORDER_RADIUS_TOKENIZER_RE = qr<((?:$IDENT)?border-radius\s*:[^;}]+;?)>i;

1;
