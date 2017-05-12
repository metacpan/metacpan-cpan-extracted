[![Build Status](https://travis-ci.org/wang-q/App-RL.svg?branch=master)](https://travis-ci.org/wang-q/App-RL) [![Coverage Status](http://codecov.io/github/wang-q/App-RL/coverage.svg?branch=master)](https://codecov.io/github/wang-q/App-RL?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/App-RL.svg)](https://metacpan.org/release/App-RL)
# NAME

App::RL - operating chromosome runlist files

# SYNOPSIS

      runlist <command> [-?h] [long options...]
          -? -h --help    show help

      Available commands:

      commands: list the application's commands
          help: display a command's help screen
    
       combine: combine multiple sets of runlists
       compare: compare 2 chromosome runlists
         cover: output covers of positions on chromosomes
        genome: convert chr.size to runlists
         merge: merge runlist yaml files
      position: compare runlists against positions
          some: extract some records
          span: operate spans in a YAML file
         split: split runlist yaml files
          stat: coverage on chromosomes for runlists
         stat2: coverage on another runlist for runlists

See `runlist commands` for usage information.

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
