# NAME

DBIx::CSVDumper - dumping database (DBI) data into a CSV.

# SYNOPSIS

    use DBIx::CSVDumper;
    my $dbh = DBI->connect(...);
    my $dumper = DBIx::CSVDumper->new(
      csv_args  => {
        binary          => 1,
        always_quote    => 1,
        eol             => "\r\n",
      },
      encoding    => 'utf-8',
    );
    

    my $sth = $dbh->prepare('SELECT * FROM item');
    $sth->execute;
    $dumper->dump(
      sth     => $sth,
      file    => 'tmp/hoge.csv',
    );

# DESCRIPTION

DBIx::CSVDumper is a module for dumping database (DBI) data into a CSV.

# CONSTRUCTOR

- `new`

        my $dumper = DBIx::CSVDumper->new(%args);

    Create new dumper object. `%args` is a hash with object parameters.
    Currently recognized keys are:

- `csv_args`

        csv_args => {
          binary          => 1,
          always_quote    => 1,
          eol             => "\r\n",
        },
        (default: same as above)
- `encoding`

        encoding => 'cp932',
        (default: utf-8)

# METHOD

- `dump`

        $dumper->dump(%args);

    Dump CSV file. `%args` is a hash with parameters. Currently recognized
    keys are:

- `sth`

        sth => $sth
        (required)

    the value is a `DBI::st` object. `execute` method should be called beforehand or
    automatically called with DBI 1.41 or newer and no bind parameters.

- `file`

        file => $file

    string of file name.

- `fh`

        fh => $fh

    file handle. args `file` or `fh` is required.

- `encoding`

        enocding => 'euc-jp',
        (default: $dumper->encoding)

    encoding.

- `csv_obj`
- `encoding`

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
