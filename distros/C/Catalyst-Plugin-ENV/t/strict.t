use Test::Strict;

# $Date: 2008-06-04 17:14:49 +0300 (Ср, 04 июн 2008) $ 
# $Author: harper $ 
# $Revision: 2728 $ 

use FindBin qw($Bin);
use lib $Bin.'/../lib';

$Test::Strict::TEST_SYNTAX = 1;
$Test::Strict::TEST_STRICT = 0;
$Test::Strict::TEST_WARNINGS = 0;

all_perl_files_ok("./lib","./t"); # Syntax ok and use strict;
