# NAME

Data::Structure::Deserialize::Auto - deserializes data structures from perl, JSON, YAML, or TOML data, from strings or files

# SYNOPSIS

    use Data::Structure::Deserialize::Auto qw(deserialize);

    my $str = '{"db": {"host": "localhost"}}';
    my $ds = deserialize($str); #autodetects JSON
    say $ds->{db}->{host}; # localhost

    # OR 

    $str = <<'END';
    options:
      autosave: 1
    END
    $ds = deserialize($str); #autodetects YAML
    say $ds->{options}->{autosave}; # 1

    # OR

    use Data::Dumper;
    $Data::Dumper::Terse = 1;
    my $filename = ...;
    open(my $FH, '>', $filename);
    my $data = {
      a => 1,
      b => 2,
      c => 3
    };
    print $FH Dumper($data);
    close($FH);
    $ds = deserialize($filename); #autodetects perl in referenced file
    say $ds->{b}; # 2

# DESCRIPTION

[Data::Structure::Deserialize::Auto](https://metacpan.org/pod/Data%3A%3AStructure%3A%3ADeserialize%3A%3AAuto) is a module for converting a string in an
arbitrary format (one of perl/JSON/YAML/TOML) into a perl data structure, without 
needing to worry about what format it was in.

If the string argument given to it is a valid local filename, it is treated as
such, and that file's contents are processed instead.

# FUNCTIONS

## deserialize( $str\[, $hint\] )

Given a string as its first argument, returns a perl data structure by decoding
the perl ([Data::Dumper](https://metacpan.org/pod/Data%3A%3ADumper)), JSON, YAML, or TOML string. Or, if the string is a valid
filename, by decoding the contents of that file.

If a hint is given as the second argument, where its value is one of `yaml`,
`json`, `toml` or `perl`, then this type of deserialization is tried first.
This may be necessary in certain rare edge cases where the input value's format
is ambiguous.

This function can be exported

# AUTHOR

Mark Tyrrell `<mark@tyrrminal.dev>`

# LICENSE

Copyright (c) 2024 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
