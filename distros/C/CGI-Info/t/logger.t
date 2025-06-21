#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most tests => 6;

BEGIN { use_ok('CGI::Info') }

# my $info = new_ok('CGI::Info');
my @messages;
my $info = CGI::Info->new({ logger => \@messages });
$info->{logger}->level('debug');

my $name = $info->script_name();

diag(Data::Dumper->new([\@messages])->Dump()) if($ENV{'TEST_VERBOSE'});
diag(Data::Dumper->new([$info->{logger}])->Dump()) if($ENV{'TEST_VERBOSE'});

is_deeply(\@messages, [
	{
		'level' => 'trace',
		'message' => 'CGI::Info: entering _find_paths'
	}
]);

cmp_deeply($info->{'logger'}->messages(), $info->messages(), 'messages() works with logger passed to new()');

my @messages2;
$info = new_ok('CGI::Info');
$info->set_logger(logger => \@messages2);
$info->{logger}->level('trace');

$name = $info->script_name();

diag(Data::Dumper->new([\@messages2])->Dump()) if($ENV{'TEST_VERBOSE'});

is_deeply(\@messages2, [
	{
		'level' => 'trace',
		'message' => 'CGI::Info: entering _find_paths'
	}
]);

cmp_deeply(\@messages2, $info->messages(), 'messages() works with set_logger');
