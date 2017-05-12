#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use DBIx::Tree;

use File::Spec;
use File::Temp;

use Tk;
use Tk::Label;
use Tk::HList;

use vars qw(@list);

my($dir)  = File::Temp -> newdir;
my($file) = File::Spec -> catfile($dir, 'test.sqlite');
my(@opts) =
(
$ENV{DBI_DSN}  || "dbi:SQLite:dbname=$file",
$ENV{DBI_USER} || '',
$ENV{DBI_PASS} || '',
);

my $dbh = DBI->connect(@opts, {RaiseError => 0, PrintError => 1, AutoCommit => 1});

if ( !defined $dbh ) {
    die $DBI::errstr;
}

my $tree = new DBIx::Tree( connection => $dbh,
                          table      => 'food',
                          method     => sub { disp_tree(@_) },
                          columns    => ['id', 'food', 'parent_id'],
                          start_id   => '001');
$tree->traverse;

my $mw = MainWindow->new();
my $hlist = $mw->HList(
                   -itemtype   => 'text',
                   -separator  => '/',
		   -width => -1,
		   -height => 10,
                   -selectmode => 'single',
                    );

my $scroll = $mw->Scrollbar(-command => ['yview', $hlist]);
$hlist->configure(-yscrollcommand => ['set', $scroll]);
$hlist->pack(-side => 'left', -fill => 'y', -expand => 1);
$scroll->pack(-side => 'right', -fill => 'y');

   foreach ( '/', @list ) {
       my $text;
       $text = (split( /\//, $_ ))[-1];
       $hlist->add($_, -text=>$text);
   }

   MainLoop;


sub disp_tree {

    my %parms = @_;
    my $item = $parms{item};
    my @parent_name = @{ $parms{parent_name} };
    my $treeval;
    foreach (@parent_name) {
        s/^\s+//;
        s/\s+$//;
        $treeval .= "$_/";
    }
    $item =~ s/^\s+//;
    $item =~ s/\s+$//;
    $treeval .= $item;
    push @list, $treeval;
}

############# close the dbh
$dbh->disconnect;
