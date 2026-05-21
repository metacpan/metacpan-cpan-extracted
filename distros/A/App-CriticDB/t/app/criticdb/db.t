#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB::DB;
use File::Temp qw/tempfile/;
use Test::More tests=>1;

subtest 'cleanup'=>sub {
	plan tests=>4;
	my ($N,@files)=(4);
	foreach (1..$N) { my ($fh,$fn)=tempfile(UNLINK=>0); push @files,$fn; close($fh); unlink($fn) }
	my $db=bless({store=>{App::CriticDB::DB->_initStore()}},'App::CriticDB::DB');
	foreach my $fn (@files) { $db->store(file=>$fn,violations=>[{policy=>'General'},{policy=>"Specific $fn"}]) }
	is(scalar(keys %{$$db{store}{file}}),$N,'Test data:  {file}');
	is(scalar(grep {%$_} values %{$$db{store}{index}{'policy-file'}{kset}}),1+$N,'Index set');
	#
	$db->cleanup();
	is(scalar(keys %{$$db{store}{file}}),0,'Cleanup:  {file}');
	is_deeply([grep {%$_} values %{$$db{store}{index}{'policy-file'}{kset}}],[],'Index set cleanup');
};
