#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Data::Session; # For the version #.

use Test::More;

use autovivification;
use CGI;
use Class::Load;
use Config::Tiny;
use Data::Dumper;
use Data::UUID;
use DBD::SQLite;
use DBI;
use DBIx::Admin::CreateTable;
use Digest::MD5;
use Digest::SHA;
use Fcntl;
use File::Basename;
use File::Path;
use File::Slurper;
use File::Spec;
use File::Temp;
use FreezeThaw;
use Hash::FieldHash;
use JSON;
use overload;
use parent;
use Safe;
use Scalar::Util;
use Storable;
use strict;
use Try::Tiny;
use vars;
use warnings;
use YAML::Tiny;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	autovivification
	CGI
	Class::Load
	Config::Tiny
	Data::Dumper
	Data::UUID
	DBD::SQLite
	DBI
	DBIx::Admin::CreateTable
	Digest::MD5
	Digest::SHA
	Fcntl
	File::Basename
	File::Path
	File::Slurper
	File::Spec
	File::Temp
	FreezeThaw
	Hash::FieldHash
	JSON
	overload
	parent
	Safe
	Scalar::Util
	Storable
	strict
	Try::Tiny
	vars
	warnings
	YAML::Tiny
/;

diag "Testing Data::Session V $Data::Session::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
