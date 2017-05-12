#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../../lib"; # include project lib

use DBI();
use CGI qw( escapeHTML );
use CGI::OptimalQuery();

chdir "$Bin/..";

my $dbh = DBI->connect("dbi:SQLite:dbname=db/dat.db","","", { RaiseError => 1, PrintError => 1 });

my %schema = (
  'dbh' => $dbh,
  'savedSearchUserID' => 12345,
  'title' => 'The People',
  'select' => {
    'U_ID' => ['person', 'person.id', 'SYS ID', { always_select => 1 }],
    'NAME' => ['person', 'person.name', 'Name'],
    'EMAIL' => ['person', 'person.email', 'Email']
  },
  'show' => "NAME,EMAIL",
  'joins' => {
    'person' => [undef, 'person']
  },

  filter => "filter5()",

  # demo of various named_filter forms
  named_filters => {
    'filter1' => ['person', ['person.name != ?','foo'], "Person's name is not 'foo' (type 1)"],
    'filter2' => ['person', "person.name != 'foo'", "Person's name is not 'foo' (type 2)"],

    'filter3' => {
      title => "filter3 title",
      sql_generator => sub {
        my %args = @_;
        return ['person', ["person.name != ?", 'foo'], "Person's name is not 'foo' (type 3)"]
      }
    },

    'filter4' => {
      title => "filter4 title",
      sql_generator => sub {
        my %args = @_;
        return ['person', "person.name != 'foo'", "Person's name is not 'foo' (type 4)"]
      }
    },

    'filter5' => {
      sql_generator => sub {
        my %args = @_;
        return ['person', "person.name != 'foo'", "filter with no title (type 5)"]
      }
    },

    'filter6' => {
      title => "filter6 title",
      html_generator => sub {
        my ($q, $prefix) = @_;
        return "<label>Enter name: ".$q->textfield($prefix.'name')."</label>";
      },
      sql_generator => sub {
        my %args = @_;
        return ['person', ["UPPER(person.name) LIKE ?", '%'.uc($args{name}).'%'], "filter with 1 html_generator (type 6)"]
      }
    },

    'filter7' => {
      title => "filter7 title",
      html_generator => sub {
        my ($q, $prefix) = @_;
        return "<label>Find names: </label>"
          ."<br>".$q->textfield($prefix.'name1')
          ."<br>".$q->textfield($prefix.'name2')
          ."<br>".$q->textfield($prefix.'name3');
      },
      sql_generator => sub {
        my %args = @_;
        return ['person', ["UPPER(person.name) LIKE ?
          OR UPPER(person.name) LIKE ?
          OR UPPER(person.name) LIKE ?",
            '%'.uc($args{name1}).'%',
            '%'.uc($args{name2}).'%',
            '%'.uc($args{name3}).'%'], "name filter (type 7)"]
      }
    }
  }
);

CGI::OptimalQuery->new(\%schema)->output();
