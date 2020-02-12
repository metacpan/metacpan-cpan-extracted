package inc::MyMakeMaker;

use Moose;
extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_header => sub {
    <<'';
    use ExtUtils::Constant qw(WriteConstants);
    WriteConstants(
        PROXYSUBS => { autoload => 0 },
        NAME => "Config::UCL",
        NAMES => [
            # greple --inside '^(typedef )?enum(.|\n)*?};' -e 'UCL[^ ,|]+' -o libucl-0.8.1/include/ucl.h | ack 'UCL_(EMIT|PARSER|STRING|DUPLICATE|PARSE)_' | awk '!x[$0]++'
            map +{ name => $_, macro => 1 },
                qw(
                    UCL_EMIT_JSON
                    UCL_EMIT_JSON_COMPACT
                    UCL_EMIT_CONFIG
                    UCL_EMIT_YAML
                    UCL_EMIT_MSGPACK
                    UCL_EMIT_MAX
                    UCL_PARSER_ZEROCOPY
                    UCL_PARSER_DEFAULT
                    UCL_PARSER_KEY_LOWERCASE
                    UCL_PARSER_NO_TIME
                    UCL_PARSER_NO_IMPLICIT_ARRAYS
                    UCL_PARSER_SAVE_COMMENTS
                    UCL_PARSER_DISABLE_MACRO
                    UCL_PARSER_NO_FILEVARS
                    UCL_STRING_RAW
                    UCL_STRING_ESCAPE
                    UCL_STRING_TRIM
                    UCL_STRING_PARSE_BOOLEAN
                    UCL_STRING_PARSE_INT
                    UCL_STRING_PARSE_DOUBLE
                    UCL_STRING_PARSE_TIME
                    UCL_STRING_PARSE_NUMBER
                    UCL_STRING_PARSE
                    UCL_STRING_PARSE_BYTES
                    UCL_DUPLICATE_APPEND
                    UCL_DUPLICATE_MERGE
                    UCL_DUPLICATE_REWRITE
                    UCL_DUPLICATE_ERROR
                    UCL_PARSE_UCL
                    UCL_PARSE_MSGPACK
                    UCL_PARSE_CSEXP
                    UCL_PARSE_AUTO
                )
        ],
    );

};

override _build_WriteMakefile_args => sub {
    return +{
        %{ super() },
        LIBS => ['-lucl'],
        INC  => '-I/usr/include/ucl', # Debian libucl-dev
    };
};

__PACKAGE__->meta->make_immutable;
