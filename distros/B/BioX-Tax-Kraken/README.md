BioX::Tax::Kraken
=========

[![Tests](https://github.com/jvolkening/p5-BioX-Tax-Kraken/actions/workflows/tests.yml/badge.svg)](https://github.com/jvolkening/p5-BioX-Tax-Kraken/actions/workflows/tests.yml)
[![Coverage Status](https://coveralls.io/repos/github/jvolkening/p5-BioX-Tax-Kraken/badge.svg?branch=main)](https://coveralls.io/github/jvolkening/p5-BioX-Tax-Kraken?branch=main)
[![CPAN version](https://badge.fury.io/pl/BioX-Tax-Kraken.svg)](https://badge.fury.io/pl/BioX-Tax-Kraken)

**WARNING**: Currently in testing phase. The API may change in future releases without notice. You have been warned!

`BioX::Tax::Kraken` is a simple interface to a Kraken-style flatfile
taxonomic database, typically using the filename 'taxDB'. This file format is
a four-column tab-delimited text file, where the columns contain:

1. taxonomic ID

2. parent ID

3. name (typically scientific)

4. rank

This distribution has a single class with methods to look up and compare
entries in a Kraken-style taxonomic database based on one or more taxonomic
IDs. It is designed to be simple and correct, and it is written to balance
speed and memory consumption. It is neither blazing fast nor ultra memory
efficient; there are better options for taxonomic data storage formats and
interfaces if you have one of these requirements. This software's only purpose
is to facilitate easy access to the information stored in a Kraken-style
database if you are already using that format for other reasons.

INSTALLATION
------------

To install this module, run the following commands:
    
    git clone https://github.com/jvolkening/p5-BioX-Tax-Kraken.git
    cd p5-BioX-Tax-Kraken
	perl Build.PL
	./Build
	./Build test
	./Build install

Or, with cpanminus:

    cpanm BioX::Tax-Kraken

Or, with conda (although not yet!):

    conda install -c bioconda perl-biox-tax-kraken

SUPPORT AND DOCUMENTATION
-------------------------

After installing, you can find documentation for this module with the
perldoc command.

    perldoc BioX::Tax::Kraken

LICENSE AND COPYRIGHT
---------------------

Copyright (C) 2026 Jeremy Volkening <jeremy.volkening@base2bio.com>

This library is licensed under the same terms as Perl 5 itself. See the LICENSE
file in the top-level directory of this distribution for the full license
terms.
