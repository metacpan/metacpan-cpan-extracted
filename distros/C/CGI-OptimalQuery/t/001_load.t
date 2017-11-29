# -*- perl -*-

# t/001_load.t - check module loading and create testing directory
use Test::More tests => 19;

use strict;
no warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";

use_ok('DBIx::OptimalQuery');
use_ok('CGI::OptimalQuery::Base');
use_ok('CGI::OptimalQuery::CSV');
use_ok('CGI::OptimalQuery::CustomOutput');
use_ok('CGI::OptimalQuery::ExportDataTool');
use_ok('CGI::OptimalQuery::InteractiveFilter2');
use_ok('CGI::OptimalQuery::InteractiveFilter');
use_ok('CGI::OptimalQuery::InteractiveQuery2');
use_ok('CGI::OptimalQuery::InteractiveQuery2Tools');
use_ok('CGI::OptimalQuery::InteractiveQuery');
use_ok('CGI::OptimalQuery::LoadSearchTool');
use_ok('CGI::OptimalQuery::PrinterFriendly');
use_ok('CGI::OptimalQuery::RecView');
use_ok('CGI::OptimalQuery::SavedSearches');
use_ok('CGI::OptimalQuery::SaveSearchTool');
use_ok('CGI::OptimalQuery::ShowColumns');
use_ok('CGI::OptimalQuery::XML');
use_ok('CGI::OptimalQuery::JSON');
use_ok('CGI::OptimalQuery');

1;
