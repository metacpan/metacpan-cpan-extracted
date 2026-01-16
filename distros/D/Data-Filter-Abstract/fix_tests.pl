use strict;

$\ = "\n"; $, = "\t";


while (<>) {
    chomp;
    s/\'\((.+)\)\'/'(($1))'/;
    print
}
