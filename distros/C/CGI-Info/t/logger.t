#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 4;

BEGIN { use_ok('CGI::Info') }

my @messages;
my $info = new_ok('CGI::Info');

$info->set_logger(\@messages);

my $name = $info->script_name();

diag(Data::Dumper->new([\@messages])->Dump()) if($ENV{'TEST_VERBOSE'});

is_deeply(\@messages, [
	{
		'level' => 'trace',
		'message' => 'CGI::Info: entering _find_paths'
	}
]);

cmp_deeply(\@messages, $info->messages(), 'messages() works');
