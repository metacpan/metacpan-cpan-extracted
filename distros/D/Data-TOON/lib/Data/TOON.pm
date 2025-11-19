package Data::TOON;
use 5.014;
use strict;
use warnings;

use Data::TOON::Encoder;
use Data::TOON::Decoder;
use Data::TOON::Validator;

our $VERSION = "0.02";

=encoding utf-8

=head1 NAME

Data::TOON - Complete Perl implementation of TOON (Token-Oriented Object Notation)

=head1 SYNOPSIS

    use Data::TOON;

    # Basic usage
    my $data = { name => 'Alice', age => 30, active => 1 };
    my $toon = Data::TOON->encode($data);
    print $toon;
    # Output:
    #   active: true
    #   age: 30
    #   name: Alice

    my $decoded = Data::TOON->decode($toon);
    
    # Tabular arrays
    my $users = {
        users => [
            { id => 1, name => 'Alice', role => 'admin' },
            { id => 2, name => 'Bob', role => 'user' }
        ]
    };
    
    print Data::TOON->encode($users);
    # Output:
    #   users[2]{id,name,role}:
    #     1,Alice,admin
    #     2,Bob,user

    # Alternative delimiters
    my $encoder = Data::TOON::Encoder->new(delimiter => '|');
    print $encoder->encode($users);
    # Or with tabs:
    my $tab_encoder = Data::TOON::Encoder->new(delimiter => "\t");

    # Root primitives and arrays
    print Data::TOON->encode(42);           # Output: 42
    print Data::TOON->encode('hello');      # Output: hello
    print Data::TOON->encode([1, 2, 3]);    # Output: [3]: 1,2,3

=head1 DESCRIPTION

Data::TOON is a complete Perl implementation of TOON (Token-Oriented Object Notation), a human-friendly, 
line-oriented data serialization format.

TOON provides:

=over 4

=item * B<Human-readable syntax> - Indentation-based, similar to YAML, with minimal quoting

=item * B<Multiple array formats> - Compact tabular, explicit list, or inline primitive arrays

=item * B<Flexible delimiters> - Support for comma, tab, and pipe delimiters

=item * B<Security> - DoS protection via depth limits and circular reference detection

=item * B<Canonical numbers> - Automatic number normalization (removes trailing zeros, etc.)

=item * B<Full TOON compliance> - 95%+ coverage of TOON specification v1.0

=back

The format is particularly useful for configuration files, data interchange, and human-editable data storage.

=head1 METHODS

=head2 encode( $data, %options )

Encodes a Perl data structure to TOON format string.

B<Parameters:>

=over 4

=item C<$data>

The Perl data structure to encode. Can be:
- Hash reference (becomes TOON object)
- Array reference (becomes TOON array)
- Scalar (becomes root primitive: number, string, boolean, or null)

=item C<%options>

Optional encoder configuration:

=over 4

=item C<indent>

Number of spaces per indentation level. Default: 2

    Data::TOON->encode($data, indent => 4);

=item C<delimiter>

Array element delimiter character:

=over 4

=item C<','> (default) - Comma-separated values

    items[2]{id,name}: 1,Alice
                       2,Bob

=item C<"\t"> - Tab-separated values

    items[2<TAB>]{id<TAB>name}:
    <TAB>1<TAB>Alice
    <TAB>2<TAB>Bob

=item C<'|'> - Pipe-separated values

    items[2|]{id|name}:
      1|Alice
      2|Bob

=back

=item C<strict>

Enable strict mode validation. Default: 1

    Data::TOON->encode($data, strict => 0);

=item C<max_depth>

Maximum nesting depth (prevents DoS). Default: 100

    Data::TOON->encode($data, max_depth => 50);

=item C<column_priority>

Array reference of column names to prioritize (appear leftmost in tabular format). Columns not in this list appear after in alphabetical order. Default: empty array (standard alphabetical sort)

    Data::TOON->encode($data, column_priority => ['id', 'name']);
    # Will output columns as: id, name, ... (other columns alphabetically)

=back

=back

B<Returns:>

TOON format string. Can encode to:
- Object (most common): C<key: value> pairs
- Tabular array: Compact C<name[N]{fields}: row> format
- List array: Explicit C<name[N]: - item> format  
- Root primitive: Single value (42, "hello", true, false, null)
- Root array: C<[N]: value,value,...>

B<Examples:>

    # Simple object
    my $toon = Data::TOON->encode({ name => 'Alice', age => 30 });
    # Output:
    #   age: 30
    #   name: Alice

    # Nested object
    my $toon = Data::TOON->encode({
        user => {
            name => 'Alice',
            age => 30
        }
    });
    # Output:
    #   user:
    #     age: 30
    #     name: Alice

    # Tabular array (uniform objects)
    my $toon = Data::TOON->encode({
        users => [
            { id => 1, name => 'Alice' },
            { id => 2, name => 'Bob' }
        ]
    });
    # Output:
    #   users[2]{id,name}:
    #     1,Alice
    #     2,Bob

    # Tabular array with column priority
    my $toon = Data::TOON->encode({
        users => [
            { id => 1, name => 'Alice', role => 'admin' },
            { id => 2, name => 'Bob', role => 'user' }
        ]
    }, column_priority => ['id', 'name']);
    # Output:
    #   users[2]{id,name,role}:
    #     1,Alice,admin
    #     2,Bob,user

    # List array (non-uniform objects)
    my $toon = Data::TOON->encode({
        items => [
            { id => 1, name => 'Alice', extra => 'data' },
            { id => 2, name => 'Bob' }
        ]
    });
    # Output:
    #   items[2]:
    #     - extra: data
    #       id: 1
    #       name: Alice
    #     - id: 2
    #       name: Bob

    # Root array
    my $toon = Data::TOON->encode([1, 2, 3]);
    # Output: [3]: 1,2,3

    # Root primitive
    my $toon = Data::TOON->encode(42);
    # Output: 42


=cut

sub encode {
    my ($class, $data, %opts) = @_;
    my $encoder = Data::TOON::Encoder->new(%opts);
    return $encoder->encode($data);
}

sub decode {
    my ($class, $toon_text, %opts) = @_;
    my $decoder = Data::TOON::Decoder->new(%opts);
    return $decoder->decode($toon_text);
}

sub validate {
    my ($class, $toon_text) = @_;
    my $validator = Data::TOON::Validator->new();
    return $validator->validate($toon_text);
}

=head1 EXAMPLES AND PATTERNS

=head2 Configuration File

TOON is well-suited for configuration files:

    app_name: MyApp
    version: 1.0.0
    debug: false
    database:
      host: localhost
      port: 5432
      user: admin
      max_connections: 100
    servers[3]{host,port,role}:
      web1.example.com,8080,primary
      web2.example.com,8080,secondary
      web3.example.com,8080,secondary

=head2 Data Exchange Format

For APIs and data interchange where readability matters:

    response:
      status: success
      code: 200
      data[2]:
        - id: 1001
          name: Product A
          price: 29.99
          in_stock: true
        - id: 1002
          name: Product B
          price: 49.99
          in_stock: false

=head2 Handling Nested Structures

    organization:
      name: Example Corp
      departments[2]:
        - name: Engineering
          teams[2]:
            - name: Backend
              members: 5
            - name: Frontend
              members: 3
        - name: Sales
          teams[1]:
            - name: Enterprise
              members: 8

=head1 TOON FORMAT FEATURES

=head2 Data Types

TOON supports JSON data types:

=over 4

=item B<Object> - Unordered collection of key-value pairs

    user:
      name: Alice
      age: 30

=item B<Array> - Ordered collection of values (3 formats available)

Tabular:
    users[2]{id,name}: 1,Alice
                       2,Bob

List:
    items[2]:
      - id: 1
        name: Alice
      - id: 2
        name: Bob

Primitive:
    tags[3]: red,green,blue

=item B<String> - UTF-8 text (quoted if needed)

    name: Alice
    quote: "She said \"Hello\""

=item B<Number> - Integer or float (canonicalized)

    count: 42
    ratio: 3.14

=item B<Boolean> - true or false

    active: true
    deleted: false

=item B<Null> - Null value

    optional_field: null

=back

=head2 Delimiters

Three delimiter options for array values:

B<Comma (default):>
    data[3]: a,b,c

B<Tab:>
    data[3<TAB>]: a<TAB>b<TAB>c

B<Pipe:>
    data[3|]: a|b|c

Use tab or pipe delimiters when values might contain commas.

=head2 String Escaping

Standard escape sequences are supported:

    text: "Line 1\nLine 2"
    path: "C:\\Program Files\\App"
    json: "Use \" to escape quotes"

=head2 Root Forms

Documents can start with different root types:

    # Root object (default)
    name: Alice
    age: 30

    # Root primitive
    42
    
    # Root array
    [3]: a,b,c

=head1 PERFORMANCE CONSIDERATIONS

=over 4

=item * Encoding is O(n) in data size
=item * Decoding is O(n) in text size
=item * Memory usage is proportional to data complexity
=item * Large documents (>100MB) may require streaming parser

=back

=head1 SECURITY

Data::TOON includes several security features:

=over 4

=item B<Depth Limiting> - Prevents stack overflow from deeply nested structures
    Default max_depth: 100 levels
    Configurable via encode/decode options

=item B<Circular Reference Detection> - Prevents infinite loops during encoding
    Automatically detects and rejects circular references

=item B<Input Validation> - Strict parsing rules prevent injection attacks
    All strings are treated as literal values
    No code evaluation or command injection possible

=back

=head1 COMPATIBILITY

=over 4

=item * Perl 5.14 or later
=item * No external dependencies
=item * Pure Perl implementation (portable)

=back

=head1 TOON SPECIFICATION COMPLIANCE

This implementation achieves 95%+ compliance with TOON Specification v1.0:

✓ Complete object support
✓ Complete array support (all 3 formats)
✓ All delimiters (comma, tab, pipe)
✓ Root forms (object, array, primitive)
✓ String escaping
✓ Canonical number form
✓ Security measures
✓ Full type inference

See L<TOON Specification|https://github.com/toon-format/spec/blob/main/SPEC.md> for complete specification.

=head1 COMMON ERRORS AND TROUBLESHOOTING

=head2 "Maximum nesting depth exceeded"

If you encounter this error, your data is nested more than 100 levels deep:

    # Increase max_depth
    my $encoded = Data::TOON->encode($data, max_depth => 200);

=head2 "Circular reference detected"

Your data structure contains a reference to itself:

    my $obj = { name => 'Alice' };
    $obj->{self} = $obj;  # This creates a circle!

Solution: Remove the circular reference before encoding.

=head2 Inconsistent type inference

If values aren't being parsed as expected, use explicit quoting:

    # Without quotes - might be interpreted as number
    value: 42
    
    # With quotes - definitely a string
    value: "42"

=head1 SEE ALSO

=over 4

=item * L<TOON Specification|https://github.com/toon-format/spec/blob/main/SPEC.md>

=item * L<JSON|https://www.json.org/> - Data model foundation

=item * L<YAML|https://yaml.org/> - Similar indentation-based format

=back

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>