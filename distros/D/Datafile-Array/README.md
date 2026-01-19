# Datafile::Array - README

**Datafile::Array** is a lightweight pure-Perl module for handling tabular/delimited data files.

It provides:
- Reading and writing delimited data files (CSV, TSV, custom delimiters)
- Optional CSV quoting with multi-line support
- Header line handling
- H/R prefix mode for data files
- UTF-8 encoding
- Consistent return values and error handling
- Verbose messaging support
- Safe atomic writes (temp file + rename)

[![Perl](https://img.shields.io/badge/perl-5.014%2B-brightgreen)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Perl-orange)](https://dev.perl.org/licenses/)

## Installation

    perl Makefile.PL
    make
    make test
    make install

## Modules

### Datafile::Array

Handles reading and writing delimited data files with optional CSV quoting, headers, and prefix lines.

#### SYNOPSIS

    use Datafile::Array qw(readarray writearray parse_csv_line);

    my @records;
    my @fields;

    my ($count, $msgs) = readarray('data.txt', \@records, \@fields, {
        delimiter    => ';',
        csvquotes    => 1,        # full CSV support with multi-line
        has_headers  => 1,
        prefix       => 1,        # H/R prefix mode
        trim_values  => 1,
        verbose      => 1,
    });

    writearray('data.txt', \@records, \@fields, {
        header  => 1,
        prefix  => 1,
        backup  => 1,
        comment => 'Exported on ' . scalar localtime,
    });

    # Standalone CSV parsing
    my @parts = parse_csv_line('a,"b,c","d""e"', ',');

#### FUNCTIONS

- **readarray($file, $data_ref, $fields_ref, \%opts)**  
  Returns `($record_count, \@messages)`

- **writearray($file, $data_ref, $fields_ref, \%opts)**  
  Returns `($record_count, \@messages)`

- **parse_csv_line($line, [$delimiter = ','])**  
  Lightweight standalone CSV line parser.  
  Handles quoted fields, escaped quotes (""), fields containing delimiter/newlines.  
  Lenient on unclosed quotes. Returns array of fields.

#### KEY OPTIONS

- delimiter       => ';'     (default)
- csvquotes       => 0 | 1   (enable full CSV parsing)
- has_headers     => 1       (expect header line(s))
- prefix          => 0 | 1   (H/R line prefix mode)
- key_fields      => 1       (composite keys for hash mode)
- trim_values     => 1
- comment_char    => '#'
- skip_empty      => 1
- search          => undef   (filter lines)
- verbose         => 0
- header          => 0 | 1   (writearray: write header)
- backup          => 0 | 1   (writearray: keep .bak)
- prot            => 0660    (writearray: file permissions)
- comment         => undef   (writearray: top comments)

## Common Features

The module:
- Uses UTF-8 encoding
- Skips comment lines (default #)
- Supports search filtering
- Returns verbose messages when requested
- Performs safe atomic writes
- Gracefully handles I/O errors (return errors instead of die)

## License

This module is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/
