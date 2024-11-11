# TITLE

Data::FastPack::JPacker - backend class for packing FastPack data files into web loadable JPack

# SYNOPSIS

```perl
use Data::FastPack::JPacker;

my @pairs=("input/path", "output/location");

my %options=();

my $jpacker=Data::FastPack::JPaker->new(%options)
$jpacker->pack_files(@pairs);

```

# DESCRIPTION

Backend to the fastpack-split program. Splits input files or standard input
(assumed FastPack messages/frames) in to output files encoded in JPack. A
sequence of files may be created representing a single input file. The
resulting jpack files are loadable via JPack in the browser

# API

## new

Create a new packer. No arguments

## init

```
$jpacker->init( OPTIONS )
```

Initializes a packer with the options (key value pairs) given

The options to this are 

- html\_container

    The path to the root dir or 'index.html' file in the root of the html
    directory. Data will be stored relative to the container

- jpack\_options

    Options specific to the JPack encoding. Please refere to [Data::JPack](https://metacpan.org/pod/Data%3A%3AJPack) for
    more details

- message\_limit

    Maximum number of FastPack messages to store in an output file

- read\_size

    Size of read buffer in bytes. Default is 4096\*8

- write\_size

    Size of buffer to accumulate output before writing out to disk. Default is 4096\*8

### pack\_files

Takes a list of pairs (input, output) files and converts them according to the
options initially set up for the object.

Output files sequences is calculated for each file, so multiple files can be
added to the output location without knowledge of the current count

# AUTHOR

Ruben Westerberg, &lt;drclaw@mac.com&lt;gt>

# REPOSITORTY and BUGS

Please report any bugs via git hub: [https://github.com/drclaw1394/perl-data-fastpack-jpacker](https://github.com/drclaw1394/perl-data-fastpack-jpacker)

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl or the MIT license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE.
