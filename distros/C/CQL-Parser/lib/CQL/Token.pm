package CQL::Token;

use strict;
use warnings;
use base qw( Exporter );

=head1 NAME

CQL::Token - class for token objects returned by CQL::Lexer

=head1 SYNOPSIS

    my $token = $lexer->nextToken();
    
    if ( $token->type() == CQL_WORD ) { 
        print "the token is a word with value=", $token->string(), "\n";
    }

=head1 DESCRIPTION

Ordinarily you won't really care about the tokens returned by the 
CQL::Lexer since the lexer is used behind the scenes by CQL::Parser.

=head1 METHODS

=head2 new()

    my $token = CQL::Token->new( '=' );

=cut

## CQL keyword types
use constant CQL_LT        => 100;    ## The "<" relation
use constant CQL_GT        => 101;    ## The ">" relation
use constant CQL_EQ        => 102;    ## The "=" relation
use constant CQL_LE        => 103;    ## The "<=" relation
use constant CQL_GE        => 104;    ## The ">=" relation
use constant CQL_NE        => 105;    ## The "<>" relation
use constant CQL_AND       => 106;    ## The "and" boolean
use constant CQL_OR        => 107;    ## The "or" boolean
use constant CQL_NOT       => 108;    ## The "not" boolean
use constant CQL_PROX      => 109;    ## The "prox" boolean
use constant CQL_ANY       => 110;    ## The "any" relation
use constant CQL_ALL       => 111;    ## The "all" relation
use constant CQL_EXACT     => 112;    ## The "exact" relation
use constant CQL_WITHIN    => 113;    ## The "within" relation
use constant CQL_ENCLOSES  => 114;    ## The "encloses" relation
use constant CQL_PARTIAL   => 115;    ## The "partial" relation
use constant CQL_PWORD     => 116;    ## The "word" proximity unit and the "word" relation modifier
use constant CQL_SENTENCE  => 117;    ## The "sentence" proximity unit
use constant CQL_PARAGRAPH => 118;    ## The "paragraph" proximity unit
use constant CQL_ELEMENT   => 119;    ## The "element" proximity unit
use constant CQL_ORDERED   => 120;    ## The "ordered" proximity ordering
use constant CQL_UNORDERED => 121;    ## The "unordered" proximity ordering
use constant CQL_RELEVANT  => 122;    ## The "relevant" relation modifier
use constant CQL_FUZZY     => 123;    ## The "fuzzy" relation modifier
use constant CQL_STEM      => 124;    ## The "stem" relation modifier
use constant CQL_SCR       => 125;    ## The server choice relation
use constant CQL_PHONETIC  => 126;    ## The "phonetic" relation modifier
use constant CQL_WORD      => 127;    ## A general word (not an operator) 
use constant CQL_LPAREN    => 128;    ## A left paren
use constant CQL_RPAREN    => 129;    ## A right paren
use constant CQL_EOF       => 130;    ## End of query
use constant CQL_MODIFIER  => 131;    ## Start of modifier '/'
use constant CQL_STRING    => 132;    ## The "string" relation modifier
use constant CQL_ISODATE   => 133;    ## The "isoDate" relation modifier
use constant CQL_NUMBER    => 134;    ## The "number" relation modifier
use constant CQL_URI       => 135;    ## The "uri" relation modifier
use constant CQL_MASKED    => 137;    ## The "masked" relation modifier
use constant CQL_UNMASKED  => 138;    ## The "unmasked" relation modifier
use constant CQL_NWSE      => 139;    ## The "nwse" relation modifier
use constant CQL_DISTANCE  => 140;    ## The "distance" proximity modifier
use constant CQL_UNIT      => 141;    ## The "unit" proximity modifier

## lookup table for easily determining token type
our %lookupTable = (
    '<'          => CQL_LT,
    '>'          => CQL_GT,
    '='          => CQL_EQ,
    '<='         => CQL_LE,
    '>='         => CQL_GE,
    '<>'         => CQL_NE,
    'and'        => CQL_AND,
    'or'         => CQL_OR,
    'not'        => CQL_NOT,
    'prox'       => CQL_PROX,
    'any'        => CQL_ANY,
    'within'     => CQL_WITHIN,
    'encloses'   => CQL_ENCLOSES,
    'partial'    => CQL_PARTIAL,
    'all'        => CQL_ALL,
    'exact'      => CQL_EXACT,
    'word'       => CQL_PWORD,
    'sentence'   => CQL_SENTENCE,
    'paragraph'  => CQL_PARAGRAPH,
    'element'    => CQL_ELEMENT,
    'ordered'    => CQL_ORDERED,
    'unordered'  => CQL_UNORDERED,
    'relevant'   => CQL_RELEVANT,
    'fuzzy'      => CQL_FUZZY,
    'stem'       => CQL_STEM,
    'phonetic'   => CQL_PHONETIC,
    '('          => CQL_LPAREN,
    ')'          => CQL_RPAREN,
    '/'          => CQL_MODIFIER,
    ''           => CQL_EOF,
    'string'     => CQL_STRING,
    'isodate'    => CQL_ISODATE,
    'number'     => CQL_NUMBER,
    'uri'        => CQL_URI,
    'masked'     => CQL_MASKED,
    'unmasked'   => CQL_UNMASKED,
    'nwse'       => CQL_NWSE,
    'distance'   => CQL_DISTANCE,
    'unit'       => CQL_UNIT,
);

## constants available for folks to use when looking at 
## token types

our @EXPORT = qw(
    CQL_LT CQL_GT CQL_EQ CQL_LE CQL_GE CQL_NE CQL_AND CQL_OR CQL_NOT 
    CQL_PROX CQL_ANY CQL_ALL CQL_EXACT CQL_PWORD CQL_SENTENCE CQL_PARAGRAPH
    CQL_ELEMENT CQL_ORDERED CQL_UNORDERED CQL_RELEVANT CQL_FUZZY
    CQL_STEM CQL_SCR CQL_PHONETIC CQL_RPAREN CQL_LPAREN
    CQL_WORD CQL_PHRASE CQL_EOF CQL_MODIFIER CQL_STRING CQL_ISODATE
    CQL_NUMBER CQL_URI CQL_MASKED CQL_UNMASKED CQL_WITHIN CQL_PARTIAL
    CQL_ENCLOSES CQL_NWSE
    CQL_DISTANCE CQL_UNIT
);

=head2 new()

=cut

sub new {
    my ($class,$string) = @_;
    my $type;

    # see if it's a reserved word, which are case insensitive
    my $normalString = lc($string);
    if ( exists($lookupTable{$normalString}) ) {
        $type = $lookupTable{$normalString};
    }
    else {
        $type = CQL_WORD;
        # remove outer quotes if present
        if ($string =~ m/^"(.*)"$/g) {
            $string = $1;
            # replace escaped double quote with double quote. 
            # Is save this way cause the string is assumed to be syntactically correct
            $string =~ s/\\"/"/g;
        }
    }
    return bless { string=>$string, type=>$type }, ref($class) || $class;
}

=head2 getType()

Returns the token type which will be available as one of the constants
that CQL::Token exports. See internals for a list of available constants.

=cut

sub getType { return shift->{type}; }

=head2 getString()

Retruns the string equivalent of the token. Particularly useful when
you only know it's a CQL_WORD.

=cut

sub getString { return shift->{string}; }

1;
