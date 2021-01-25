# NAME

Data::Prepare - prepare CSV (etc) data for automatic processing

# SYNOPSIS

    use Text::CSV qw(csv);
    use Data::Prepare qw(
      cols_non_empty non_unique_cols
      chop_lines chop_cols header_merge
    );
    my $data = csv(in => 'unclean.csv', encoding => "UTF-8");
    chop_cols([0, 2], $data);
    header_merge($spec, $data);
    chop_lines(\@lines, $data); # mutates the data

    # or:
    my @non_empty_counts = cols_non_empty($data);
    print Dumper(non_unique_cols($data));

# DESCRIPTION

A module with utility functions for turning spreadsheets published for
human consumption into ones suitable for automatic processing. Intended
to be used by the supplied [data-prepare](https://metacpan.org/pod/data-prepare) script. See that script's
documentation for a suggested workflow.

All the functions are exportable, none are exported by default.
All the `$data` inputs are an array-ref-of-array-refs.

# FUNCTIONS

## chop\_cols

    chop_cols([0, 2], $data);

Uses `splice` to delete each zero-based column index. The example above
deletes the first and third columns.

## chop\_lines

    chop_lines([ 0, (-1) x $n ], $data);

Uses `splice` to delete each zero-based line index, in the order
given. The example above deletes the first, and last `$n`, lines.

## header\_merge

    header_merge([
      { line => 1, from => 'up', fromspec => 'lastnonblank', to => 'self', matchto => 'HH', do => [ 'overwrite' ] },
      { line => 1, from => 'self', matchfrom => '.', to => 'down', do => [ 'prepend', ' ' ] },
      { line => 2, from => 'self', fromspec => 'left', to => 'self', matchto => 'Year', do => [ 'prepend', '/' ] },
      { line => 2, from => 'self', fromspec => 'literal:Country', to => 'self', tospec => 'index:0', do => [ 'overwrite' ] },
    ], $data);
    # Turns:
    # [
    #   [ '', 'Proportion of households with', '', '', '' ],
    #   [ '', '(HH1)', 'Year', '(HH2)', 'Year' ],
    #   [ '', 'Radio', 'of data', 'TV', 'of data' ],
    # ]
    # into (after a further chop_lines to remove the first two):
    # [
    #   [
    #     'Country',
    #     'Proportion of households with Radio', 'Proportion of households with Radio/Year of data',
    #     'Proportion of households with TV', 'Proportion of households with TV/Year of data'
    #   ]
    # ]

Applies the given transformations to the given data, so you can make the
given data have the first row be your desired headers for the columns.
As shown in the above example, this does not delete lines so further
operations may be needed.

Broadly, each hash-ref specifies one operation, which acts on a single
(specified) line-number. It scans along that line from left to right,
unless `tospec` matches `index:\d+` in which case only one operation
is done.

The above merge operations in YAML format:

    spec:
      - do:
          - overwrite
        from: up
        fromspec: lastnonblank
        line: 2
        matchto: HH
        to: self
      - do:
          - prepend
          - ' '
        from: self
        line: 2
        matchfrom: .
        to: down
      - do:
          - prepend
          - /
        from: self
        fromspec: left
        line: 3
        matchto: Year
        to: self
      - do:
          - overwrite
        from: self
        fromspec: literal:Country
        line: 3
        to: self
        tospec: index:0

This turns the first three lines of data excerpted from the supplied example
data (shown in CSV with spaces inserted for alignment reasons only):

          ,Proportion of households with,       ,     ,
          ,(HH1)                        ,Year   ,(HH2),Year
          ,Radio                        ,of data,TV   ,of data
    Belize,58.7                         ,2019   ,78.7 ,2019

into the following. Note that the first two lines will still be present
(not shown), possibly modified, so you will need your chop\_lines to
remove them. The columns of the third line are shown, one per line,
for readability:

    Country,
    Proportion of households with Radio,
    Proportion of households with Radio/Year of data,
    Proportion of households with TV,
    Proportion of households with TV/Year of data

This achieves a single row of column-headings, with each column-heading
being unique, and sufficiently meaningful.

## cols\_non\_empty

    my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

## non\_unique\_cols

    my $col2count = non_unique_cols($data);

Takes the first row of the given data, and returns a hash-ref mapping
any non-unique column-names to the number of times they appear.

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV)

# LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
