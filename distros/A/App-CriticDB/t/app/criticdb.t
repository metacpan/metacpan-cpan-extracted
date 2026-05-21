#!/usr/bin/perl

use strict;
use warnings;
use App::CriticDB;
use File::Temp qw/tempfile/;
use Test::More tests=>1;

subtest 'initialization'=>sub {
	plan tests=>2;
	my $fh=File::Temp->new(UNLINK=>1,SUFFIX=>'.stor');
	my $criticdb=App::CriticDB->new(file=>$fh->filename(),type=>'storable');
	ok(defined($criticdb),'Creation');
	is($$criticdb{mode},'file','Mode=file');
};
