package Baal::Parser;
use 5.008001;
use utf8;
use Mouse;
use Parse::RecDescent;

our $VERSION = "0.01";

our $grammer = <<'GRAMMER';
Document: Namespace(s?) END_OF_FILE
    {
        $return => {
            Document => $item{"Namespace(s?)"},
        }
    }

Namespace:
    KEYWORD_NAMESPACE
        QualifiedName
        ImportClause(s?)
    KEYWORD_BEGIN
        Declaration(s?)
    KEYWORD_END
    {
        $return = {
            Name => $item{QualifiedName},
            Imports => $item{"ImportClause(s?)"},
            Declarations => $item{"Declaration(s?)"},
        };
    }

ImportClause:
    (KEYWORD_IMPORT | KEYWORD_APPEND) QualifiedNameWithWildcard

Declaration:
    EntityDeclaration | ServiceDeclaration

EntityDeclaration:
    DOCUMENT_COMMENT(?)
    KEYWORD_ABSTRACT(?)
    KEYWORD_ENTITY
        IDENTIFIER
        IncludeClause(s?)
    KEYWORD_BEGIN
        FieldDefinition(s?)
    KEYWORD_END
    {
        my $comment = $item{"DOCUMENT_COMMENT(?)"};
        $return = {
            Entity => {
                Name => $item{IDENTIFIER},
                IsAbstract => scalar(@{$item{"KEYWORD_ABSTRACT(?)"}})!= 0,
                DocumentComment => $comment ? $comment->[0] : undef,
                Includes => $item{"IncludeClause(s?)"},
                Fields => $item{"FieldDefinition(s?)"},
            },
        };
    }

IncludeClause:
    (KEYWORD_INCLUDES | KEYWORD_APPEND) ReferenceType

FieldDefinition:
    DOCUMENT_COMMENT(?)
        IDENTIFIER
    KEYWORD_AS
        ModifieredType
    KEYWORD_CLOSE
    {
        my $comment = $item{"DOCUMENT_COMMENT(?)"};
        $return = {
            Name => $item{IDENTIFIER},
            DocumentComment => $comment ? $comment->[0] : undef,
            %{$item{ModifieredType}},
        };
    } | <error>

ServiceDeclaration:
    DOCUMENT_COMMENT(?)
    KEYWORD_SERVICE
        IDENTIFIER
    KEYWORD_BEGIN
        MethodDefinition(s?)
    KEYWORD_END
    {
        my $comment = $item{"DOCUMENT_COMMENT(?)"};
        $return = {
            Service => {
                Name => $item{IDENTIFIER},
                DocumentComment => $comment ? $comment->[0] : undef,
                Methods => $item{"MethodDefinition(s?)"},
            },
        };
    }

MethodDefinition:
    DOCUMENT_COMMENT(?)
        IDENTIFIER
    KEYWORD_AS
        (KEYWORD_ACCEPTS ModifieredType)(?)
        (KEYWORD_RETURNS ModifieredType)(?)
    KEYWORD_CLOSE
    {
        my $comment = $item{"DOCUMENT_COMMENT(?)"};
        $return = {
            Name => $item{IDENTIFIER},
            DocumentComment => $comment ? $comment->[0] : undef,
            Accepts => $item[4]->[0],
            Returns => $item[5]->[0],
        };
    } | <error>

ModifieredType: Occurrence Iteration(s?) Type
    {
        $return = {
            Occurrence => $item{Occurrence},
            Iteration  => $item{'Iteration(s?)'}->[0],
            Type       => $item{Type},
        };
    }

# OCCURRENCES

Occurrence: Required | Nullable
Required: KEYWORD_REQUIRED
    { $return = $item[0] }
Nullable: KEYWORD_NULLABLE
    { $return = $item[0] }

# ITERATIONS

Iteration: ListOf | DictionaryOf
ListOf: KEYWORD_LIST_OF
    { $return = $item[0] }
DictionaryOf: KEYWORD_DICTIONARY_OF
    { $return = $item[0] }

# TYPES

Type: PrimitiveType | PseudoType | ReferenceType | <error>
ReferenceType:
    EntityDeclaration { $return = {EntityDeclaration => $item[1]} } |
    QualifiedName { $return = {QualifiedName => $item[1]} }
PseudoType: QUOTED_STRING
    { $return = { PseudoType => $item[1] } }


# NAMES

QualifiedNameWithWildcard: (IDENTIFIER '.' {$return = $item[1]} )(s?) (IDENTIFIER | '*')
    { [ @{$item[1]} , $item[2] ] }
QualifiedName: (IDENTIFIER '.' {$return = $item[1]} )(s?) IDENTIFIER
    { [ @{$item[1]} , $item[2] ] }

# PRIMITIVE TYPES

PrimitiveType:
    TypeBoolean |
    TypeInteger8 | TypeInteger16 | TypeInteger32 | TypeInteger64 |
    TypeFloatBinary32 | TypeFloatBinary64 |
    TypeFloatDecimal32 | TypeFloatDecimal64 |
    TypeTimestamp | TypeDate | TypeTime |
    TypeString | TypeBinary

TypeBoolean: TYPE_BOOLEAN
    { $return = { PrimitiveType => $item[0] } }
TYPE_BOOLEAN: 'boolean' | 'bool'

TypeInteger8: TYPE_INTEGER_8
    { $return = { PrimitiveType => $item[0] } }
TYPE_INTEGER_8:
    'integer(' WHITE_SPACE(s?) '8' WHITE_SPACE(s?) ')' |
    'int8' | 'sbyte' | 'byte'

TypeInteger16: TYPE_INTEGER_16
    { $return = { PrimitiveType => $item[0] } }
TYPE_INTEGER_16: 'integer(' WHITE_SPACE(s?) '16' WHITE_SPACE(s?) ')' |
    'int16' | 'short'

TypeInteger32: TYPE_INTEGER_32
    { $return = { PrimitiveType => $item[0] } }
TYPE_INTEGER_32:
    'integer(' WHITE_SPACE(s?) '32' WHITE_SPACE(s?) ')' |
    'int32' | 'integer' | 'int'

TypeInteger64: TYPE_INTEGER_64
    { $return = { PrimitiveType => $item[0] } }
TYPE_INTEGER_64:
    'integer(' WHITE_SPACE(s?) '64' WHITE_SPACE(s?) ')' |
    'int64' | 'long'

TypeFloatBinary32: TYPE_FLOAT_BINARY_32
    { $return = { PrimitiveType => $item[0] } }
TYPE_FLOAT_BINARY_32:
    'float(' WHITE_SPACE(s?) 'binary' WHITE_SPACE(s?) '32' WHITE_SPACE(s?) ')' |
    'float32' | 'float'

TypeFloatBinary64: TYPE_FLOAT_BINARY_64
    { $return = { PrimitiveType => $item[0] } }
TYPE_FLOAT_BINARY_64:
    'float(' WHITE_SPACE(s?) 'binary' WHITE_SPACE(s?) '64' WHITE_SPACE(s?) ')' |
    'float64' | 'double' | 'real' | 'number'

TypeFloatDecimal32: TYPE_FLOAT_DECIMAL_32
    { $return = { PrimitiveType => $item[0] } }
TYPE_FLOAT_DECIMAL_32:
    'float(' WHITE_SPACE(s?) 'decimal' WHITE_SPACE(s?) '32' WHITE_SPACE(s?) ')' |
    'decimal32'

TypeFloatDecimal64: TYPE_FLOAT_DECIMAL_64
    { $return = { PrimitiveType => $item[0] } }
TYPE_FLOAT_DECIMAL_64:
    'float(' WHITE_SPACE(s?) 'decimal' WHITE_SPACE(s?) '64' WHITE_SPACE(s?) ')' |
    'decimal64' | 'decimal' | 'numeric' | 'money'

TypeDate: TYPE_DATE
    { $return = { PrimitiveType => $item[0] } }
TYPE_DATE: 'date'

TypeTime: TYPE_TIME
    { $return = { PrimitiveType => $item[0] } }
TYPE_TIME: 'time'

TypeTimestamp: TYPE_TIMESTAMP
    { $return = { PrimitiveType => $item[0] } }
TYPE_TIMESTAMP: 'timestamp' | 'datetime'

TypeString: TYPE_STRING
    { $return = { PrimitiveType => $item[0] } }
TYPE_STRING: 'string' | 'str'

TypeBinary: TYPE_BINARY
    { $return = { PrimitiveType => $item[0] } }
TYPE_BINARY: 'binary' | 'bin'


# KEYWORDS AND SYMBOLIC ALIASES

KEYWORD_NAMESPACE: 'namespace'
KEYWORD_IMPORT: 'import'
KEYWORD_ABSTRACT: 'abstract'
KEYWORD_ENTITY: 'entity'
KEYWORD_SERVICE: 'service'
KEYWORD_INCLUDES: 'includes'
KEYWORD_REQUIRED: 'required' | '!'
KEYWORD_NULLABLE: 'nullable' | '?'
KEYWORD_LIST_OF: ('list' WHITE_SPACE(s?) 'of') | '@'
KEYWORD_DICTIONARY_OF: (('dictionary' | 'hash' | 'map') WHITE_SPACE(s?) 'of') | '%'
KEYWORD_APPEND: "+="
KEYWORD_REMOVE: "-="
KEYWORD_ACCEPTS: "accepts" | "<="
KEYWORD_RETURNS: "returns" | "=>"
KEYWORD_AS: "as" | ":"
KEYWORD_BEGIN: "{"
KEYWORD_END: "}"
KEYWORD_CLOSE: ";"


# FRAGMENTS

IDENTIFIER: IDENTIFIER_FIRST_CHARACTOR IDENTIFIER_FILLING_CHARACTOR(s?)
    { $item[1] . join '', @{$item[2]} }
IDENTIFIER_FIRST_CHARACTOR: UPPER_ALPHABET_CHARACTOR
IDENTIFIER_FILLING_CHARACTOR: ALPHABET_NUMERIC_CHARACTOR
QUOTED_STRING: "\"" (ESCAPE_STRING | /[^\\"\r\n']/)(s) "\""
    { $return = join '', @{$item[2]} }
ESCAPE_STRING: /\\(?:[bfnrt\\'"]|x[0-9a-fA-F][0-9a-fA-F]|u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])/
DOCUMENT_COMMENT: /\/#(.*?)#\//s
    { $return = $1 }
MULTI_LINE_COMMENT: /\/\*(.*?)\*\//
    { $return = $1 }
SINGLE_LINE_COMMENT: "//" LINE_CONTENT(s) END_OF_LINE(?)
    { $return = join '', @{$item[2]} }
BLANK: WHITE_SPACE(s)
HEXADECIMAL_CHARACTOR: /[0-9a-fA-F]/
ALPHABET_NUMERIC_CHARACTOR: ALPHABET_CHARACTOR | NUMERIC_CHARACTOR
ALPHABET_CHARACTOR: LOWER_ALPHABET_CHARACTOR | UPPER_ALPHABET_CHARACTOR
LOWER_ALPHABET_CHARACTOR: /[a-z]/
UPPER_ALPHABET_CHARACTOR: /[A-Z]/
NUMERIC_CHARACTOR: /[0-9]/
WHITE_SPACE: /[ \t\r\n]/
LINE_CONTENT: /[^\r\n]/
END_OF_LINE: /\r?\n/
END_OF_FILE: /^\Z/
GRAMMER

has parser => (
    is  => 'ro',
    isa => 'Parse::RecDescent',
    default => sub {
        local $Parse::RecDescent::skip = '([ \t\r\n]|//.*?\r?\n|/\*(.|\r|\n)*?\*/)*';
        return Parse::RecDescent->new($grammer);
    },
);

no Mouse;

sub parse {
    my ($self, $text) = @_;
    my $result = $self->parser->Document($text);
    return $result;
}

1;
__END__

=encoding utf-8

=head1 NAME

Baal::Parser - A Paser for Baal IDL.

=head1 SYNOPSIS

    use Baal::Parser;
    my $parser = Baal::Parser->new;
    my $parsed_document = $parser->parse(<<END);
    namespace Data.Hoge += Hoge.Fuga.* {
        service HogeHoge {
            Hoge: <= !integer => !integer;
        }
    }
    END

=head1 DESCRIPTION

Baal::Parser is A Paser for Baal IDL.
See L<http://techblog.kayac.com/?page=1482198679> and L<http://techblog.kayac.com/unity_advent_calendar_2016_20>
about Baal(They are written in japanese).

=head1 LICENSE

Copyright (C) ohta-nobuyuki.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ohta-nobuyuki E<lt>ohta-nobuyuki@kayac.comE<gt>

=cut

