#!/usr/bin/perl -w

use DBI;
use DB::Introspector;



my %TRAVERSED_TABLES;

&main;

sub main {
    my $dbh = DBI->connect(@ARGV);

    my $introspector = DB::Introspector->get_instance($dbh);

    my $table = $introspector->find_table('locations')
      || die("table flavors could not be found");

    &print_dependencies($table,0);
    $dbh->disconnect();
}

sub print_dependencies {
    my $table = shift;
    my $levels = shift;

    return if($TRAVERSED_TABLES{$table});
    $TRAVERSED_TABLES{$table} = 1; # marking that we visited this table

    print " " x $levels++."-".$table->name."\n";
    foreach $foreign_key ($table->dependencies) {
        print_dependencies($foreign_key->local_table, $levels);
    }
}
