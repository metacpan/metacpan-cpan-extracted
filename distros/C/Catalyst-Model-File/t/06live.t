use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More tests => 2;

BEGIN
{
  $ENV{MODEL_FILE_DIR} = $FindBin::Bin . '/store';
    require Path::Class;
    Path::Class::dir($ENV{MODEL_FILE_DIR})->rmtree;
}

use Catalyst::Test 'TestApp';
use Data::Dumper;

my $res = request('http://localhost/cd');
is $res->content, '/foo';
$res = request('http://localhost/pwd');
is $res->content, '/';
