
# To run this test manually:
# perl -I../../lib ../../bin/fatpack file line-test.pl | perl

package OurTest;

use Test::More;

our $main_file = __FILE__;
note "File: $main_file";

# Run the tests in the packed file
do 'line/a.pm';

