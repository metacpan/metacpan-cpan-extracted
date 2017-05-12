[![Build Status](https://travis-ci.org/wang-q/AlignDB-Run.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-Run) [![Coverage Status](http://codecov.io/github/wang-q/AlignDB-Run/coverage.svg?branch=master)](https://codecov.io/github/wang-q/AlignDB-Run?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/AlignDB-Run.svg)](https://metacpan.org/release/AlignDB-Run)
# NAME

AlignDB::Run - Run in parallel without pains.

# SYNOPSIS

    use AlignDB::Run;

    my $worker = sub {
        my $job = shift;

        print "$job\n";
        return;
    };

    my $run = AlignDB::Run->new(
        parallel => 4,
        jobs     => [1 .. 8],
        code     => $worker,
        opt      => {foo => "bar",}
    );
    $run->run;

# ATTRIBUTES

`parallel` - run in parallel mode

`jobs` - All jobs to be done

`code` - code ref

`opt` - hash ref

# METHODS

## run

Start run your code

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2009- by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
