#-------------------------------------------------------------------------------
# NAME: Init.t
# PURPOSE: test script for the parameters defined in the Bio::Prospect::Init class
#          used in conjunction with Makefile.PL to test installation
#
# $Id: Init.t,v 1.5 2003/11/18 19:45:46 rkh Exp $
#-------------------------------------------------------------------------------

use Bio::Prospect::Init;
use Test::More;
use warnings;
use strict;

plan tests => 3;

ok( -d $Bio::Prospect::Init::PROSPECT_PATH,      "PROSPECT_PATH ($Bio::Prospect::Init::PROSPECT_PATH) valid" );
ok( -d $Bio::Prospect::Init::PDB_PATH,           "PDB_PATH ($Bio::Prospect::Init::PDB_PATH) valid" );
ok( -x $Bio::Prospect::Init::MVIEW_APP,          "MVIEW_APP ($Bio::Prospect::Init::MVIEW_APP) executable" );
