#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use App::Office::CMS; # For the version #.

use Test::More;

use Brannigan;
use Capture::Tiny;
use CGI;
use CGI::Application;
use CGI::Application::Dispatch;
use CGI::Application::Dispatch::PSGI;
use CGI::Untaint;
use Config::Tiny;
use Data::Session;
use Date::Format;
use DBD::SQLite;
use DBI;
use DBIx::Admin::CreateTable;
use DBIx::Admin::TableInfo;
use DBIx::Simple;
use File::Path;
use File::Spec;
use File::Slurper;
use FindBin;
use JSON::XS;
use Lingua::EN::Inflect::Number;
use Log::Handler;
use Moo;
use parent;
use Path::Class;
use Plack::Builder;
use strict;
use String::Dirify;
use Text::Xslate;
use Tree;
use Tree::DAG_Node;
use Tree::DAG_Node::Persist;
use Try::Tiny;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Brannigan
	Capture::Tiny
	CGI
	CGI::Application
	CGI::Application::Dispatch
	CGI::Application::Dispatch::PSGI
	CGI::Untaint
	Config::Tiny
	Data::Session
	Date::Format
	DBD::SQLite
	DBI
	DBIx::Admin::CreateTable
	DBIx::Admin::TableInfo
	DBIx::Simple
	File::Path
	File::Spec
	File::Slurper
	FindBin
	JSON::XS
	Lingua::EN::Inflect::Number
	Log::Handler
	Moo
	parent
	Path::Class
	Plack::Builder
	strict
	String::Dirify
	Text::Xslate
	Tree
	Tree::DAG_Node
	Tree::DAG_Node::Persist
	Try::Tiny
	Types::Standard
	warnings
/;

diag "Testing App::Office::CMS V $App::Office::CMS::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
