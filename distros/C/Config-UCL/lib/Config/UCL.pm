package Config::UCL;

use 5.010;
use vars qw($VERSION $ucl_schema_error);
use strict;
use warnings;
use base qw(Exporter);
use bytes ();
use JSON::PP::Boolean;
use XSLoader;
BEGIN {
    $VERSION = '0.04';
    XSLoader::load( 'Config::UCL', $VERSION );
}

{
    no strict qw(refs);
    my $klass = __PACKAGE__;
    push @{"${klass}::EXPORT"}, grep /^ucl_/i, keys %{"${klass}::"};
}

sub ucl_load {
    my $opt = @_ == 2 ? pop : {};
    die unless @_ == 1;
    return undef unless defined $_[0];
    my $parser                 = _new_parser($opt);
    my $len                    = bytes::length($_[0]);
    my $priority               = $opt->{priority} // 0;
    my $ucl_duplicate_strategy = $opt->{ucl_duplicate_strategy} // UCL_DUPLICATE_APPEND;
    my $ucl_parse_type         = $opt->{ucl_parse_type} // UCL_PARSE_UCL;
    $parser->ucl_parser_add_chunk_full($_[0], $len, $priority, $ucl_duplicate_strategy, $ucl_parse_type);
    $parser->ucl_load(!!$opt->{utf8}, $opt->{ucl_string_flags}//UCL_STRING_ESCAPE);
}

sub ucl_load_file {
    my $opt = @_ == 2 ? pop : {};
    die unless @_ == 1;
    return undef unless defined $_[0];
    my $parser                 = _new_parser($opt);
    my $priority               = $opt->{priority} // 0;
    my $ucl_duplicate_strategy = $opt->{ucl_duplicate_strategy} // UCL_DUPLICATE_APPEND;
    my $ucl_parse_type         = $opt->{ucl_parse_type} // UCL_PARSE_UCL;
    $parser->ucl_parser_add_file_full($_[0], $priority, $ucl_duplicate_strategy, $ucl_parse_type);
    $parser->ucl_load(!!$opt->{utf8}, $opt->{ucl_string_flags}//UCL_STRING_ESCAPE);
}

sub _new_parser {
    my ($opt) = @_;
    my $parser = Config::UCL::Parser->new( $opt->{ucl_parser_flags} // 0 );
    if (exists $opt->{ucl_parser_register_variables}) {
        my $ref = $opt->{ucl_parser_register_variables};
        die "option ucl_parser_register_variables must be even." if @$ref%2;
        for (1..@$ref/2) {
            $parser->ucl_parser_register_variable($ref->[$_*2-2],$ref->[$_*2-1]);
        }
    }
    $parser;
}

sub ucl_dump {
    my $opt = @_ == 2 ? pop : {};
    die unless @_ == 1;
    _ucl_dump($_[0], !!$opt->{utf8}, $opt->{ucl_emitter}//UCL_EMIT_CONFIG);
}

sub ucl_schema_error { $ucl_schema_error }

1;

__END__

=encoding utf8

=head1 NAME

Config::UCL - Perl bindings for libucl

=head1 SYNOPSIS

    use Config::UCL;
    use JSON::PP qw(to_json);

    my $hash = ucl_load("key1 : val1");
    say to_json $hash; # {"key1":"val1"}

    my $text = ucl_dump($hash);
    say $text; # key1 = "val1";

    # libucl-0.8.1/tests/schema/required.json
    my $data1  = { foo => 1 };
    my $data2  = { bar => 1 };
    my $schema = {
        properties => {
            foo => {},
            bar => {},
        },
        required => [qw(foo)],
    };
    say ucl_validate($schema, $data1); # 1
    say ucl_schema_error();            #
    say ucl_validate($schema, $data2); #
    say ucl_schema_error();            # object has missing property foo

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 $data = ucl_load($str, [$opt])

$opt hash reference is optional.

=head3 option ucl_parser_flags

Passed to ucl_parser_new().
L<https://github.com/vstakhov/libucl/blob/master/doc/api.md#ucl_parser_new>

    UCL_PARSER_DEFAULT (default)
    UCL_PARSER_KEY_LOWERCASE
    UCL_PARSER_ZEROCOPY
    UCL_PARSER_NO_TIME
    UCL_PARSER_NO_IMPLICIT_ARRAYS
    UCL_PARSER_SAVE_COMMENTS
    UCL_PARSER_DISABLE_MACRO
    UCL_PARSER_NO_FILEVARS

=head3 option ucl_string_flags 

Passed to ucl_string_flags ucl_object_fromstring_common().
L<https://github.com/vstakhov/libucl/blob/master/doc/api.md#ucl_object_fromstring_common>

    UCL_STRING_RAW
    UCL_STRING_ESCAPE (default)
    UCL_STRING_TRIM
    UCL_STRING_PARSE_BOOLEAN
    UCL_STRING_PARSE_INT
    UCL_STRING_PARSE_DOUBLE
    UCL_STRING_PARSE_TIME
    UCL_STRING_PARSE_NUMBER
    UCL_STRING_PARSE
    UCL_STRING_PARSE_BYTES

=head3 option ucl_duplicate_strategy

Passed to ucl_duplicate_strategy ucl_parser_add_chunk_full().

    UCL_DUPLICATE_APPEND (default)
    UCL_DUPLICATE_MERGE
    UCL_DUPLICATE_REWRITE
    UCL_DUPLICATE_ERROR

=head3 option ucl_parse_type

Passed to ucl_duplicate_strategy ucl_parser_add_chunk_full().

    UCL_PARSE_UCL (default)
    UCL_PARSE_MSGPACK
    UCL_PARSE_CSEXP
    UCL_PARSE_AUTO

=head3 option ucl_parser_register_variables

Passed to ucl_parser_register_variable().

    my $hash = ucl_load('var1 = "${var1}"; var2 = "$var2"',
        {
            ucl_parser_register_variables => [ var1 => 'val1', val2 => 'val2' ],
        }
    );
    # {"var1":"val1","var2":"$var2"}

=head3 option utf8

The UTF8 flag of the key and value is turned on.

=head2 $data = ucl_load_file($filename, [$opt])

$opt is the same as ucl_load().

Internally ucl_parser_set_filevars() is called and ${CURDIR} is set.

=head2 $str = ucl_dump($data, [$opt])

$opt hash reference is optional.

=head3 option ucl_emitter

Passed to ucl_object_emit().
L<https://github.com/vstakhov/libucl/blob/master/doc/api.md#emitting-functions-1>

    UCL_EMIT_JSON (default)
    UCL_EMIT_JSON_COMPACT
    UCL_EMIT_CONFIG
    UCL_EMIT_YAML
    UCL_EMIT_MSGPACK
    UCL_EMIT_MAX

=head3 option utf8

The UTF8 flag of the value is turned on.

=head2 $bool = ucl_validate($schema, $data)

Returns true or false.

If it is false, you can get the error string with ucl_schema_error().

=head2 $str = ucl_schema_error()

=head1 SEE ALSO

L<https://github.com/vstakhov/libucl>

=head1 AUTHOR

Tomohiro Hosaka, E<lt>bokutin@bokut.inE<gt>

=head1 COPYRIGHT AND LICENSE

The Config::UCL module is Copyright (C) 2020 by Tomohiro Hosaka.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
