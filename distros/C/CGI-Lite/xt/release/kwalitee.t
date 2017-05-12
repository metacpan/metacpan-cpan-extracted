#!/usr/bin/perl
#
#===============================================================================
#
#         FILE:  kwalitee.t
#
#  DESCRIPTION:  Test Kwalitee
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pete Houston (cpan@openstrike.co.uk)
#      COMPANY:  Openstrike
#      CREATED:  26/02/15 17:45:01
#===============================================================================

use strict;
use warnings;

use Test::More;
use Test::Kwalitee 'kwalitee_ok';
kwalitee_ok();
done_testing();
