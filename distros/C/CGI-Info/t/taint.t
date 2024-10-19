#!perl -w

# This is disabled, you need to run by hand giving the -T option

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most tests => 7;
use Test::Needs 'Test::Taint';
use Taint::Runtime qw(enable $TAINT taint_env taint_start);

BEGIN {
	taint_start();
	$TAINT = 1;
	taint_env();
}

Test::Taint->import();
taint_checking_ok();

require_ok('CGI::Info');
CGI::Info->import();

$ENV{'C_DOCUMENT_ROOT'} = $ENV{'HOME'};
delete $ENV{'DOCUMENT_ROOT'};

my $i = new_ok('CGI::Info');
untainted_ok($i->tmpdir());
untainted_ok($i->script_name());
untainted_ok($i->tmpdir() . '/' . $i->script_name() . '.foo');
untainted_ok($i->script_path());
