#!perl

use FindBin;
use lib $FindBin::Bin;
use lib "$FindBin::Bin/../inc";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

my $content;

$content = get('/model/DM');
is($content, 'TestApp::DM');
$content = get('/model_got_dbh');
is($content, 'DBI::db');

$content = get('/model/DM%3A%3AEmployee');
is($content, 'TestApp::DM::Employee');

$content = get('/model/DM%3A%3ADepartment');
is($content, 'TestApp::DM::Department');
