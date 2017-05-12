#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib"; # include project lib

use DBI();
use CGI::OptimalQuery();
use CGI::OptimalQuery::EmailMergeTool();
use CGI::OptimalQuery::AutoActionTool();

chdir "$Bin/..";

my $dbh = DBI->connect("dbi:SQLite:dbname=db/dat.db","","", { PrintError => 1, RaiseError => 1 });

my %schema = (
  'dbh' => $dbh,
  'title' => 'The People',
  'select' => {
    'U_ID' => ['person', 'person.id', 'SYS ID', { always_select => 1 }],
    'NAME' => ['person', 'person.name', 'Name'],
    'EMAIL' => ['person', 'person.email', 'Email']
  },
  'joins' => {
    'person' => [undef, 'person']
  },

  'tools' => {
    'emailmerge' => {
      'title' => 'Email Merge',
      'handler' => \&CGI::OptimalQuery::EmailMergeTool::handler,
      'options' => {
        readonly_to => 0,
        from => 'pmc2@sr.unh.edu',
        readonly_from => 1,
        template_vars => {
          'CURRENT_USER_EMAIL' => 'test.me@foo.com',
        }
      }
    },
    'autoaction' => {
      title => 'Auto Actions',
      handler => \&CGI::OptimalQuery::AutoActionTool::handler
    }
  }
);

CGI::OptimalQuery->new(\%schema)->output();
