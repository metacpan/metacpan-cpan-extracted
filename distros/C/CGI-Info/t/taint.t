#!perl -wT

use strict;
use warnings;
use Test::Most tests => 7;
use Test::Needs 'Test::Taint';

Test::Taint->import();
taint_checking_ok();
require_ok('CGI::Info');

$ENV{'C_DOCUMENT_ROOT'} = $ENV{'HOME'};
delete $ENV{'DOCUMENT_ROOT'};

my $i = new_ok('CGI::Info');
untainted_ok($i->tmpdir());
untainted_ok($i->script_name());
untainted_ok($i->tmpdir() . '/' . $i->script_name() . '.foo');
untainted_ok($i->script_path());
