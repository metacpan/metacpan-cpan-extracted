#!/usr/local/bin/perl -w

=head1 NAME 

selectall_html.pl

=head1 SYNOPSIS

  selectall_html.pl -d "dbi:Pg:dbname=mydb;host=localhost" "SELECT * FROM a NATURAL JOIN b"

=head1 DESCRIPTION


=head1 ARGUMENTS

=cut



use strict;

use Carp;
use DBIx::DBStag;
use Data::Stag;
use Getopt::Long;

my $debug;
my $help;
my $db;
my $nesting;
my $show;
my $remove = "";
my $highlight = "";
GetOptions(
           "help|h"=>\$help,
	   "db|d=s"=>\$db,
           "show"=>\$show,
           "remove|r=s"=>\$remove,
           "highlight=s"=>\$highlight,
	   "nesting|p=s"=>\$nesting,
          );
if ($help) {
    system("perldoc $0");
    exit 0;
}

my $dbh = 
  DBIx::DBStag->connect($db);
my $sql = shift @ARGV;
if (!$sql) {
    print STDERR "Reading SQL from STDIN...\n";
    $sql = <STDIN>;
}
my $stag = $dbh->selectall_stag($sql, $nesting);

my @rmlist = split(/\;\s*/, $remove);
foreach (@rmlist) {
    my @was = $stag->findnode($_, []);
}
my %hih = map {$_=>1} split(/\;\s*/, $highlight);

our $BORDER = 0;
our $TDARGS = 'VALIGN="top"';
our $THARGS = 'BGCOLOR=#9999FF';
our $TERMCOLOUR = 'BGCOLOR=#DDDDFF';
print to_html($stag);   
$dbh->disconnect;

sub to_html {
    my $stag = shift;
    my $row = 0;
    return sprintf("<table border=$BORDER>%s</table>",
                   join('',
                        map {
                            _to_html($_, $row++)
                        } $stag->kids));
}
sub _to_html {
    my $stag = shift;
    my $thisrow = shift;
    my @kids = $stag->kids;
    my $el = $stag->element;
#    my $type = $types{$el};
    my $type = 'tr';
    my $out =
      "<$type>";
    my $pre = '';
    my @hdrs = ();
    foreach my $kid (@kids) {
        next unless $kid->isterminal;
        my $data = $kid->data;
        if ($hih{$kid->element}) {
            $data = "<b>$data</b>";
        }
        $out .= sprintf("<td $TERMCOLOUR $TDARGS>%s</td>",
                        $data);
        push(@hdrs, $kid->element);
    }
    my @ntkids = $stag->ntnodes;
    my %elh = ();
    my @elts = ();

    # get unique ordered list
    foreach (@ntkids) {
        if (!$elh{$_->element}) {
            $elh{$_->element} = 1;
            push(@elts, $_->element);
        }
    }
    foreach my $subel (@elts) {
        push(@hdrs, $subel);
        my @stags = $stag->getnode($subel);
        my $inner;
        my @ntstags = grep {!$_->isterminal} @stags;
        if (@ntstags) {
            my $row = 0;
            $inner = sprintf("<table border=$BORDER>%s</table>",
                             join('',
                                  map {
                                      _to_html($_, $row++)
                                  } @stags));
        }
        else {
            $inner = 
              join('<br>',
                   map {
                       _to_html($_) . '\n'
                   } @stags);
        }
        $out .= sprintf("<td $TDARGS>$inner</td>");
    }
    $out .= "</$type>\n";
    if (!$thisrow) {
        $pre = '<tr>' . join('',
                             map {"<th $THARGS>$_</th>"} @hdrs) . '</tr>';
    }
    return $pre . $out;
}
