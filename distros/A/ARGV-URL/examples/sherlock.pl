#!perl

use lib '../lib', 'lib';

BEGIN {
    @ARGV = ('http://www.gutenberg.org/cache/epub/1661/pg1661.txt');
}

use ARGV::URL;

while (<>) {
    print "$.: $_" if /Sherlock/;
}

