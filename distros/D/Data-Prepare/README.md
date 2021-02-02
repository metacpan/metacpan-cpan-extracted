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

## pk\_insert

    pk_insert({
      column_heading => 'ISO3CODE',
      local_column => 'Country',
      pk_column => 'official_name_en',
    }, $data, $pk_map, $stopwords);

In YAML format, this is the same configuration:

    pk_insert:
      - files:
          - examples/CoreHouseholdIndicators.csv
        spec:
          column_heading: ISO3CODE
          local_column: Country
          pk_column: official_name_en
          use_fallback: true

And the `$pk_map` made with ["make\_pk\_map"](#make_pk_map), inserts the
`column_heading` in front of the current zero-th column, mapping the
value of the `Country` column as looked up from the specified column
of the `pk_spec` file, and if `use_fallback` is true, also tries
["pk\_match"](#pk_match) if no exact match is found. In that case, `stopwords`
must be specified in the configuration

## cols\_non\_empty

    my @col_non_empty = cols_non_empty($data);

In the given data, iterates through all rows and returns a list of
quantities of non-blank entries in each column. This can be useful to spot
columns with only a couple of entries, which are more usefully chopped.

## non\_unique\_cols

    my $col2count = non_unique_cols($data);

Takes the first row of the given data, and returns a hash-ref mapping
any non-unique column-names to the number of times they appear.

## key\_to\_index

Given an array-ref (probably the first row of a CSV file, i.e. column
headings), returns a hash-ref mapping the cell values to their zero-based
index.

## make\_pk\_map

    my $altcol2value2pk = make_pk_map($data, $pk_colkey, \@other_colkeys);

Given `$data`, the heading of the primary-key column, and an array-ref
of headings of alternative key columns, returns a hash-ref mapping each
of those alternative key columns (plus the `$pk_colkey`) to a map from
that column's value to the relevant row's primary-key value.

This is most conveniently represented in YAML format:

    pk_spec:
      file: examples/country-codes.csv
      primary_key: ISO3166-1-Alpha-3
      alt_keys:
        - ISO3166-1-Alpha-2
        - UNTERM English Short
        - UNTERM English Formal
        - official_name_en
        - CLDR display name
      stopwords:
        - islands
        - china
        - northern

## pk\_col\_counts

    my ($colname2potential_key2count, $no_exact_match) = pk_col_counts($data, $pk_map);

Given `$data` and a primary-key (etc) map created by the above, returns
a tuple of a hash-ref mapping each column that gave any matches to a
further hash-ref mapping each of the potential key columns given above
to how many matches it gave, and an array-ref of rows that had no exact
matches.

## pk\_match

    my ($best, $pk_cols_unique_best) = pk_match($value, $pk_map, $stopwords);

Given a value, `$pk_map`, and an array-ref of case-insensitive stopwords,
returns its best match for the right primary-key value, and an array-ref
of which primary-key columns in the `$pk_map` matched the given value
exactly once.

The latter is useful for analysis purposes to select which primary-key
column to use for this data-set.

The algorithm used for this best-match:

- Splits the value into words (or where a word is two or more capital
letters, letters). The search allows any, or no, text, to occur between
these entities. Each configured primary-key column's keys are searched
for matches.
- If there is a separating `,` or `(` (as commonly used for
abbreviations), splits the value into chunks, reverses them, and then
reassembles the chunks as above for a similar search.
- Only if there were no matches from the previous steps, splits the value
into words. Words that are shorter than three characters, or that occur in
the stopword list, are omitted. Then each word is searched for as above.
- "Votes" on which primary-key value got the most matches. Tie-breaks on
which primary-key value matched on the shortest key in the relevant
`$pk_map` column, and then on the lexically lowest-valued primary-key
value, to ensure stable return values.

# SEE ALSO

[Text::CSV](https://metacpan.org/pod/Text%3A%3ACSV)

# LICENSE AND COPYRIGHT

Copyright (C) Ed J

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
