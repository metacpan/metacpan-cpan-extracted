[![Build Status](https://travis-ci.org/wang-q/AlignDB-ToXLSX.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-ToXLSX) [![Coverage Status](http://codecov.io/github/wang-q/AlignDB-ToXLSX/coverage.svg?branch=master)](https://codecov.io/github/wang-q/AlignDB-ToXLSX?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/AlignDB-ToXLSX.svg)](https://metacpan.org/release/AlignDB-ToXLSX)
# NAME

AlignDB::ToXLSX - Create xlsx files from arrays or SQL queries.

# SYNOPSIS

    # Mysql
    my $write_obj = AlignDB::ToXLSX->new(
        outfile => $outfile,
        dbh     => $dbh,
    );

    # MongoDB
    my $write_obj = AlignDB::ToXLSX->new(
        outfile => $outfile,
    );

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
