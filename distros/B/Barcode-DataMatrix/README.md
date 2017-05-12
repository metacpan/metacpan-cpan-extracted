# Barcode::DataMatrix - Generate data for Data Matrix barcodes

This class is used to generate data for Data Matrix barcodes. It is primarily
useful as a data source for barcode modules that do rendering, such as
`HTML::Barcode::DataMatrix`. You can easily make a version that renders an
image, PDF, or anything else.

    use Barcode::DataMatrix;
    my $data = Barcode::DataMatrix->new->barcode('MONKEY');
    for my $row (@$data) {
        print for map { $_ ? "#" : ' ' } @$row;
        print "\n";
    }

## Installation

The simplest way to install `Barcode::DataMatrix` is via `cpanm`:

    $ cpanm Barcode::DataMatrix

One can also install from source by first cloning the repository:

    $ git clone git@github.com:mstratman/Barcode-DataMatrix.git

then installing the build dependencies:

    $ cpanm Module::Install::Repository Module::Install::AuthorTests

followed by the usual build and test steps:

    $ perl Makefile.PL
    $ make
    $ make test

If all went well, you can now install the distribution by running:

    $ make install

## Documentation

Detailed documentation about this distribution can be found in
`lib/Barcode/DataMatrix.pm` or be shown by simply running

    $ perldoc lib/Barcode/DataMatrix.pm

## Authors

 - Mons Anderson, <inthrax@gmail.com> (author of `GD::Barcode::DataMatrix`,
   from which this distribution originates)

 - Mark A. Stratman, <stratman@gmail.com>

 - Paul Cochrane, https://github.com/paultcochrane

## License and Copyright

Copyright 2015 the Authors listed above.

This program is free software; you can redistribute it and/or modify it under
the terms of either: the GNU General Public License as published by the Free
Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
