# CLI::Cmdline.pm
A minimal, zero-dependency command-line parser in pure Perl – supporting both short and long options.

[![Perl](https://img.shields.io/badge/perl-5.010%2B-brightgreen)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Perl-orange)](https://dev.perl.org/licenses/)

## Features

- Short options: `-v`, `-vh` (bundling), `-header`
- Long options: `--verbose`, `--help`, `--version`
- Long options with arguments:
  - Separate: `--output file.txt`
  - Attached: `--output=file.txt`
- Single-letter short switches can be bundled: `-vh`, `-vvv`
- Single-letter short options can be last in a bundle: `-vd dir`
- Switches are counted when repeated (`-v -v` → 2, `--verbose --verbose` → 2)
- Options requiring arguments support repeated values:
  - Collect all values if default is an array reference `[]`
  - Otherwise keep only the last value
- `--` explicitly ends option processing
- Full `@ARGV` restoration on any error (unknown flag, missing argument, invalid bundle)
- Returns 1 on success, 0 on error – perfect for `or die`

All this in ~120 lines of pure Perl. No dependencies.

## Installation

    perl Makefile.PL
    make
    make test
    make install

## Usage

    #!/usr/bin/perl
    use strict;
    use warnings;
    use CLI::Cmdline qw(parse);

    my $switches = '-v -h --verbose --quiet --help';
    my $options  = '-f --file --output --header';

    my %opt = (
        header  => [],          # collect multiple values
        output  => 'default.out',
        h => 5,
    );

    CLI::Cmdline::parse(\%opt, $switches, $options)
        or die "Invalid option or missing argument: @ARGV\n";

    # @ARGV now contains only positional arguments
    print "Verbose level: $opt{verbose}\n";
    print "Output file: $opt{output}\n";
    print "Headers: @{$opt{header}}\n" if @{ $opt{header} };

## Examples

    $ script.pl -vh --output=out.txt data.txt
    # → v=1, h=1, output='out.txt', @ARGV = ('data.txt')

    $ script.pl --verbose --verbose --header=title.txt
    # → verbose=2, header => ['title.txt']

    $ script.pl -f file1.txt -f=file2.txt
    # → file => 'file2.txt' (scalar) or ['file1.txt','file2.txt'] if pre-set as []

    $ script.pl --unknown
    # → dies with error, @ARGV fully restored

    $ script.pl --header title.txt -- --
    # → header => ['title.txt'], everything after -- left in @ARGV

## API

    CLI::Cmdline::parse(\%hash, $switches_string, $options_string)

- `\%hash`            – hash reference to populate with parsed values
- `$switches_string`  – space-separated list of valid switches (no argument)
- `$options_string`   – space-separated list of valid options (require argument)

Returns 1 on success, 0 on error.

## Development & Testing

The distribution includes a comprehensive test suite:

    t/01-basic.t  # tests covering all features and edge cases

Run with:

    prove -v t/01-basic.t

## License

This module is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/

