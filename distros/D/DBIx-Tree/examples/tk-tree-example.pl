#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use DBIx::Tree;

use File::Spec;
use File::Temp;

use Tk;
use Tk::Tree;
use Tk::Label;

use vars qw(@list);   # the list of items in the tree.

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

# Create a new instance of the DBIx::Tree object.
#
my $dbtree = new DBIx::Tree( connection => $dbh,
                            table      => 'food',
                            method     => sub { disp_tree(@_) },
                            columns    => ['id', 'food', 'parent_id'],
                            start_id   => '001');

# Execute the query, and form the tree.
#
$dbtree->traverse;

# Create a new main window.
#
my $top = new MainWindow( -title  => "Tree" );

# Create a scrolled Tree widget.  Behind the scenes, we're forming
# each of the tree elements as a directory style listing. For example,
# Skim Milk is represented as "Dairy/Beverages/Skim Milk".  As long
# as we add the elements in the order in which they appear in the
# tree, the tree will be able to figure out which element is the
# parent of each node we add.
#
my $tree = $top->Scrolled( 'Tree',
                           -separator       => '/',
                           -exportselection => 1,
                           -scrollbars      => 'osoe',
                           -height => 20,
                           -width  => -1);
# Pack the tree.
#
$tree->pack( -expand => 'yes',
             -fill   => 'both',
             -padx   => 10,
             -pady   => 10,
             -side   => 'top' );

# When we ran $dbtree->tree earlier, the @list array was populated.
# It doesn't have a top element, so we need to pre-pend one to the
# list ('/' below).
#
foreach ( '/', @list ) {

    # We don't want the user to see "Dairy/Beverages/Skim Milk",
    # so we'll strip off all but the last words for the label.
    #
    my $text = (split( /\//, $_ ))[-1];

    # If we're on /, let's make its label blank.
    #
    if ($_ eq '/') {
        $text = "";
    }

    # Add the item (in $_) with $text as the label.
    #
    $tree->add( $_, -text => $text );

}

$tree->autosetmode();

my $ok = $top->Button( -text      => 'Ok',
                       -underline => 0,
                       -width     => 6,
                       -command   => sub { $dbh->disconnect; exit } );

my $cancel = $top->Button( -text      => 'Cancel',
                           -underline => 0,
                           -width     => 6,
                           -command   => sub { $dbh->disconnect; exit } );

$ok->pack( -side => 'left', -padx => 10,  -pady => 10 );
$cancel->pack( -side => 'right', -padx => 10, -pady => 10 );

MainLoop();
$dbh->disconnect;

# This is the callback for the $dbtree->tree method. Each time
# A node is added, this method is called.
#
sub disp_tree {

    my %parms = @_;
    my $item = $parms{item};
    my @parent_name = @{ $parms{parent_name} };

    my $treeval = "/";
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

