#
#===============================================================================
#
#         FILE:  fixme.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko (mn), mehner@fh-swf.de
#      COMPANY:  FH Südwestfalen, Iserlohn
#      VERSION:  1.0
#      CREATED:  13.03.2009 19:26:38
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Test::More;                      # last test to print

eval "use Test::Fixme";
if ( $@ ) {
    plan skip_all => 'Test::Fixme required for validating the distribution';
}

run_tests(match => qr/[T]ODO|[F]IXME/,);
