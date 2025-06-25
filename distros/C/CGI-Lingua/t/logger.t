#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most tests => 2;

BEGIN { use_ok('CGI::Lingua') }

my @messages;

my $lingua = CGI::Lingua->new(supported => ['en'], logger => \@messages);
$lingua->{logger}->level('trace');

my $country = $lingua->country();

diag(Data::Dumper->new([\@messages])->Dump()) if($ENV{'TEST_VERBOSE'});

is_deeply(\@messages, [
	{
		'level' => 'trace',
		'message' => 'CGI::Lingua: Entered country()'
	}
]);
