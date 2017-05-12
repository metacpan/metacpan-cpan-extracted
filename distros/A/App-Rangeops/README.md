[![Build Status](https://travis-ci.org/wang-q/App-Rangeops.svg?branch=master)](https://travis-ci.org/wang-q/App-Rangeops) [![Coverage Status](http://codecov.io/github/wang-q/App-Rangeops/coverage.svg?branch=master)](https://codecov.io/github/wang-q/App-Rangeops?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/App-Rangeops.svg)](https://metacpan.org/release/App-Rangeops)
# NAME

App::Rangeops - operates ranges and links of ranges on chromosomes

# SYNOPSIS

    rangeops <command> [-?h] [long options...]
        -? -h --help    show help

    Available commands:

      commands: list the application's commands
          help: display a command's help screen

        circos: range links to circos links or highlight file
         clean: replace ranges within links, incorporate hit strands and remove nested links
       connect: connect bilaterial links into multilateral ones
        create: create blocked fasta files from range links
        filter: filter links by numbers of ranges or length difference
         merge: merge overlapped ranges via overlapping graph
       replace: replace ranges within links and incorporate hit strands
          sort: sort links and ranges within links

See `rangeops commands` for usage information.

# DESCRIPTION

Types of links:

- Bilateral links

        I(+):13063-17220    I(-):215091-219225
        I(+):139501-141431  XII(+):95564-97485

- Bilateral links with hit strand

        I(+):13327-17227    I(+):215084-218967      -
        I(+):139501-141431  XII(+):95564-97485      +

- Multilateral links

        II(+):186984-190356 IX(+):12652-16010       X(+):12635-15993

- Merge files aren't links

        I(-):13327-17227    I(+):13327-17227

Steps:

    sort
      |
      v
    clean -> merge
      |     /
      |  /
      v
    clean
      |
      V
    connect
      |
      v
    filter

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
