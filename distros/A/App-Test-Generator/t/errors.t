#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir tempfile);
use Test::Most;

BEGIN { use_ok('App::Test::Generator') }

throws_ok(sub { App::Test::Generator::generate() }, qr/^Usage: /, 'Dies with no args');

my $dir = tempdir(CLEANUP => 1);
my $conf_file = File::Spec->catfile($dir, 'example.yml');

open my $fh, '>', $conf_file or die $!;
print $fh <<"CONF";
---
module: Foo::Bar::Bletch
function: run

input:
  type: string

CONF

close $fh;

{
	my $warnings;

	local $SIG{'__WARN__'} = sub {
		$warnings .= $_[0];
	};

	App::Test::Generator::generate($conf_file);

	like($warnings, qr/Module .+ not found/, 'Error generated when a module is not found');
}

unlink $conf_file;

open $fh, '>', $conf_file or die $!;
print $fh <<"CONF";
---
module: Test::Simple
function: ok

input:
  arg1:
    type: string

output:
  type: string

yaml_cases: /not_there_at_all

CONF

close $fh;

throws_ok(sub { App::Test::Generator::generate($conf_file) }, qr/not_there_at_all:\s/, 'Dies when yaml_cases file is not found');

unlink $conf_file;

open $fh, '>', $conf_file or die $!;
print $fh <<"CONF";
---
module: Test::Simple
function: nan

CONF

close $fh;

throws_ok(sub { App::Test::Generator::generate($conf_file) }, qr/least one of input and output/, 'Check we are told something to set or get');

unlink $conf_file;

open $fh, '>', $conf_file or die $!;
print $fh <<"CONF";
---
module: Test::Simple
function: wrong_type

input:
  name:
    type: freddy

CONF

close $fh;

throws_ok(sub { App::Test::Generator::generate($conf_file) }, qr/Invalid type/, 'Type must be sensible');

done_testing();
