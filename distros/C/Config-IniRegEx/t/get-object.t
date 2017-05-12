#
#===============================================================================
#
#         FILE:  get-object.t
#
#  DESCRIPTION:  to test whether it is New call returns object
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:   (), <>
#      COMPANY:  
#      VERSION:  1.16
#      CREATED:  01/28/09 16:04:46 IST
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More tests => 1;                      # last test to print
use Config::IniRegEx;

my $obj = Config::IniRegEx->New("./examples/sample_config.ini", 1);

ok( defined $obj );
