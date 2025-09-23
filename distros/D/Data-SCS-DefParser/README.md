## Data::SCS::DefParser

This software is a Perl module to parse units contained in SII
definition files (plain text variant). SII files are used with the
[ATS](https://americantrucksimulator.com/) and
[ETS2](https://eurotrucksimulator2.com/) truck simulator games.

What I originally needed was a quick solution to read basic city and
company data. Instead of creating a generic SII parser, I ended up just
throwing regular expressions at the problem until I got what I wanted.
The result turned out to be capable of parsing many other def files as
well to some extent, although it might not be very reliable. That said,
it's served me well in practice for many years without needing too
much maintenance. Which is good, since that quick-and-dirty approach
let readability suffer.

The code is structured around the expectation that the game files
have already been extracted to the file system, and have been
limited to just the files you want to parse. While you *can*
easily point the parser to the full game installation thanks to
[Archive::SCS](https://metacpan.org/dist/Archive-SCS), doing so
is comparatively slow. Fixing that would be a bit of a redesign
and I don't think I'll bother with it.

### Usage

```perl
my $game_data = Data::SCS::DefParser->new(
  mount => ( $game_name or $dir_path or [@scs_files] ),
  parse => ( $def_file or [@def_files] ),
)->data;

# Example: Write out a YAML representation of definitions;
# omitting "parse" will default to city and company files.
use YAML::Tiny;
my $ats = Data::SCS::DefParser->new( mount => 'ATS' )->data;
YAML::Tiny->new( $ats )->write( 'ats.yml' );

# Example: List city tokens from the Texas DLC; the correct
# def name city.dlc_tx.sii will be automatically determined.
say for ( sort keys Data::SCS::DefParser->new(
  mount => ['dlc_tx.scs'],
  parse => ['def/city.sii'],
)->data->{city}->%* );
```

### Installation

Using [cpanminus](https://metacpan.org/pod/App::cpanminus)
on Perl v5.36 or later:

```sh
cpanm https://github.com/nautofon/Data-SCS-DefParser.git
```

Performing a manual installation should be considered slightly
advanced because you'll need to handle all prerequisites yourself.
For general information on installing Perl modules, see
<https://www.cpan.org/modules/INSTALL.html>.

```sh
perl Makefile.PL
make
make test
make install
```

### Contact

Feel free to post any kind of feedback or questions in the
[SCS forum thread on Archive::SCS](https://forum.scssoft.com/viewtopic.php?t=330746).
The two modules are somewhat related.
(Or send a PM to `nautofon`, if you prefer.)

### License

Copyright © 2025 [nautofon](https://github.com/nautofon)

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
