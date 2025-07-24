#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use CPAN::MetaCurator; # For the version #.

use Test::More;

use boolean;
use Config::Tiny;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Simple;
use Data::Dumper::Concise;
use DateTime;
use DateTime::Tiny;
use ExtUtils::MakeMaker;
use File::Slurper;
use File::Spec;
use Getopt::Long;
use HTML::Entities;
use HTML::TreeBuilder;
use lib;
use Log::Handler;
use Mojo::JSON;
use Mojo::Log;
use Moo;
use parent;
use Path::Tiny;
use Pod::Usage;
use strict;
use Text::CSV::Encoded;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	boolean
	Config::Tiny
	DBI
	DBIx::Admin::CreateTable
	DBIx::Simple
	Data::Dumper::Concise
	DateTime
	DateTime::Tiny
	ExtUtils::MakeMaker
	File::Slurper
	File::Spec
	Getopt::Long
	HTML::Entities
	HTML::TreeBuilder
	lib
	Log::Handler
	Mojo::JSON
	Mojo::Log
	Moo
	parent
	Path::Tiny
	Pod::Usage
	strict
	Text::CSV::Encoded
	Types::Standard
	warnings
/;

diag "Testing CPAN::MetaCurator V $CPAN::MetaCurator::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
