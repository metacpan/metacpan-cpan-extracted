# Algorithm-QuineMcCluskey

## version 1.01

This module creates objects designed to solve boolean expressions via
the Quine-McCluskey algorithm. The effectiveness of the algorithm is
dependent upon the size of problem; the number of minterms that can be set
goes up exponentially (approximately 3^n/n) with the number of variables.
This does limit, unfortunately, the size of the problems that can be solved
with this algorithm.

For example, a test with 12 variables (resulting in 4,096 possible input
combinations) currently takes 3 minutes to solve on a not-terribly-modern
Intel Core i7 laptop computer with 4G of memory. A 12-input problem would
therefore seem to be a reasonable upper limit to what this algorithm can
solve.

## INSTALLATION

To install this module, run the following commands:

```shell
perl Build.PL
./Build
./Build test
./Build install
```

## SUPPORT AND DOCUMENTATION

Depending upon your system, you can view documentation using the 'perldoc'
or 'man' command. Online, you can also look for information at
[MetaCPAN](https://metacpan.org/release/Algorithm-QuineMcCluskey) or
[Github](https://github.com/jgamble/Algorithm-QuineMcCluskey)

Helpful links to supporting web sites and documentation are listed on the page.

## COPYRIGHT AND LICENCE

Copyright (C) 2006 Darren Kulp

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
