# CLI::Cmdline
A minimal, zero-dependency command-line parser in pure Perl – supporting both short and long options.

[![Perl](https://img.shields.io/badge/perl-5.010%2B-brightgreen)](https://www.perl.org/)
[![CPAN version](https://img.shields.io/badge/CPAN-1.22-blue)](https://metacpan.org/pod/CLI::Cmdline/)
[![License](https://img.shields.io/badge/license-Perl-orange)](https://dev.perl.org/licenses/)
 
## Features

- Short options: `-v`, `-vh` (bundling), `-header`
- Long options: `--verbose`, `--help`, `--version`
- Long options with arguments:
  - Separate: `--output file.txt`
  - Attached: `--output=file.txt`
- Single-letter short switches can be bundled: `-vh`, `-vvv`
- Single-letter short options can be last in a bundle: `-vd dir`
- Aliases can be used, f.e. '-v|verbose -n|dry-run'
- Switches are counted when repeated (`-v -v` → 2, `--verbose --verbose` → 2)
- Options requiring arguments support repeated values:
  - Collect all values if default is an array reference `[]`
  - Otherwise keep only the last value
- Explicitly ends option processing with `--`
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

    my $switches = '-v|verbose -x -h|help --quiet';
    my $options  = '-f|file --output --header';

    my %opt = (
        header  => [],          # collect multiple values
        output  => 'default.out',
        x => 5,
    );

    CLI::Cmdline::parse(\%opt, $switches, $options)
        or die "Invalid option or missing argument: @ARGV\n";

    # @ARGV now contains only positional arguments
    print "Verbose level: $opt{v}\n";
    print "Output file: $opt{output}\n";
    print "Headers: @{$opt{header}}\n" if @{ $opt{header} };

## Cmdline examples

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

## Perl examples

   There are example scripts in the examples directory

- **Minimal example – switches without explicit defaults**

    You do not need to pre-define every switch with a default value.
    Missing switches are automatically initialized to 0.

        my %opt;
        parse(\%opt, '-v|verbose -h -x')
           or die "usage: $0 [-v] [-h] [-x] files...\n";

        # After parsing ./script.pl -verbose -vvvx file.txt
        # %opt will contain: (v => 4, h => 0, x => 1)
        # @ARGV == ('file.txt')

- **Required Options**

    To make an option required, declare it with an empty string default and check afterward:

        my %opt = ( mode => 'normal');
        parse(\%opt, '', '--input --output --mode')
          or die "usage: $0 --input=FILE [--output=FILE] [--mode=TYPE] files...\n";

        die "Error: --input is required\n"   if ($opt{input} eq '');

- **Collecting multiple values, no default array needed**

    If you want multiple occurrences but don't want to pre-set an array:

       my %opt = (
           define => [],        # explicitly an array ref
       );
       parse(\%opt, '', '--define')
           or die "usage: $0 [--define NAME=VAL ...] files...\n";

       # ./script.pl --define DEBUG=1 --define TEST --define PROFILE
       # $opt{define} == ['DEBUG=1', 'TEST', 'PROFILE']
       
       # Alternative: omit the default entirely (parser will not auto-create array)
       # If you forget the [] default, repeated --define will overwrite the last value.

- **Using -- to pass filenames starting with dash**

       my %opt;
       parse(\%opt, '-r')
           or die "usage: $0 [-r] files...\n";
    
       # Command line:
       ./script.pl -r -- -hidden-file.txt another-file
  
       # Results:
       # $opt{r} == 1
       # @ARGV == ('-hidden-file.txt', 'another-file')

## API

    CLI::Cmdline::parse(\%hash, $switches_string, $options_string)

- `\%hash`            – hash reference to populate with parsed values
- `$switches_string`  – space-separated list of valid switches (no argument)
- `$options_string`   – space-separated list of valid options (require argument)

Returns 1 on success, 0 on error.

## Development & Testing

The distribution includes a comprehensive test suite:

    t/01-basic.t        # 162 tests covering basic features
    t/02-alias.t        #  27 tests covering aliases
    t/03-complex.t      #  28 tests covering edge cases
    t/04-error.t        #  27 tests covering errors
    t/05-integration.t  #  24 tests covering script cases

Run with:

    prove -v t/*.t

## License

This module is free software. 
You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/

