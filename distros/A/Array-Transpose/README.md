# NAME

Array::Transpose - Transposes a 2-Dimensional Array

# SYNOPSIS

    use Array::Transpose;
    @array=transpose(\@array);

    use Array::Transpose qw{};
    @array=Array::Transpose::transpose(\@array);

Example:

    use Array::Transpose;
    use Data::Dumper;
    my $array=transpose([
                          [ 0  ..  4 ],
                          ["a" .. "e"],
                        ]);
    print Data::Dumper->Dump([$array]);

Returns

    $VAR1 = [
              [ 0, 'a' ],
              [ 1, 'b' ],
              [ 2, 'c' ],
              [ 3, 'd' ],
              [ 4, 'e' ]
            ];

# DESCRIPTION

This package exports one function named transpose.

In linear algebra, the transpose of a matrix A is another matrix A' created by any one of the following equivalent actions:

- write the rows of A as the columns of A'
- write the columns of A as the rows of A'
- reflect A by its main diagonal (which starts from the top left) to obtain A'

# USAGE

    use Array::Transpose;
    @array=transpose(\@array);

# METHODS

## transpose

Returns a transposed 2-Dimensional Array given a 2-Dimensional Array

    my $out=transpose($in);  #$in=[[],[],[],...];
    my @out=transpose(\@in); #@in=([],[],[],...);

# LIMITATIONS

The transpose function assumes all rows have the same number of columns as the first row.

# BUGS

Please log on RT and send an email to the author.

# AUTHOR

    Michael R. Davis

# COPYRIGHT

This program is free software licensed under the...

    The BSD License

The full text of the license can be found in the LICENSE file included with this module.

# SEE ALSO

## Similar Capabilities

[Math::MatrixReal](https://metacpan.org/pod/Math::MatrixReal) method transpose, [Data::Table](https://metacpan.org/pod/Data::Table) rotate method

## Packages built on top of this package

[Array::Transpose::Ragged](https://metacpan.org/pod/Array::Transpose::Ragged)
