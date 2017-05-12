#!/usr/local/bin/perl

# stag-q
# cjm@fruitfly.org

use strict;
use Carp;
use DBIx::DBStag;
use Data::Stag qw(:all);
use Data::Dumper;
use Getopt::Long;
use Term::ANSIColor;

my $h = {};

my $dbname = '';
my $connect;
my $term;
my @hist = ();

my %cscheme =
  (
   'keyword'=>'cyan',
   'variable'=>'magenta',
   'text' => 'reset',
   'comment' => 'red',
   'block' => 'blue',
   'property' => 'green',
  );

GetOptions(
           "dbname|d=s"=>\$dbname,
           "connect|c"=>\$connect,
          );

my $match = shift;
# parent dbh
my $sdbh = 
  DBIx::DBStag->new;

my $all_templates =
  $sdbh->template_list;

my @templates = @$all_templates;
if ($match) {
    @templates = grep {$_->name =~ /$match/} @templates;
}
foreach my $t (@templates) {
    $t->show(\*STDOUT, \%cscheme);
}

