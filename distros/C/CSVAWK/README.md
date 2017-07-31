[![Build Status](https://travis-ci.org/brymck/csvawk.svg?branch=master)](https://travis-ci.org/brymck/csvawk)

CSVAWK
======

This simply passes a CSV file to AWK with a Perl wrapper. It lets you:

* Reference the fields in its header as normal AWK variables (e.g. `$foo`).
  Note that invalid characters are condensed into an underscore (`_`).

Output specific fields:

```sh
csvawk '{ print $foo, $bar }' file.csv
```

Output the header and records matching a specific condition:

```sh
csvawk 'NR==1 || $foo=="bar" { print }' file.csv
```

Edit a single field and output:

```sh
csvawk 'NR>1 { $foo="bar" } { print }' file.csv
```

Count records matching certain conditions:

```sh
csvawk '$foo=="bar" { ++count } END { print count }' file.csv
```

Pretty print your program in `gawk` and inspect it:

```sh
csvawk -g '{ print $foo }' file.csv -- --pretty-print
less awkprof.out
```

List headers, one per line:

```sh
csvawk 'NR == 1 { for (i = 1; i <= NF; i++) print $i }' file.csv
```
