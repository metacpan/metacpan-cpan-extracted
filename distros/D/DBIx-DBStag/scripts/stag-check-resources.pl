#!/usr/local/bin/perl

# cjm@fruitfly.org

use strict;
use Carp;
use DBIx::DBStag;
use Data::Stag qw(:all);
use Data::Dumper;
use Getopt::Long;

my $h = {};

my $term;
my @hist = ();

my $match = shift;
# parent dbh
my $sdbh = 
  DBIx::DBStag->new;

my $resources = $sdbh->resources_list;
foreach my $r (@$resources) {
    next unless $r->{type} eq 'rdb';
    my $name = $r->{name};
    eval {
        my $testdbh = DBIx::DBStag->connect($name);
        $testdbh->disconnect;
    };
    my $ok = $@ ? 'FAIL' : 'PASS';
    printf "%12s $ok\n", $name;
}
exit 0;

__END__

=head1 NAME 

stag-check-resources.pl

=head1 SYNOPSIS

  stag-check-resources.pl

=head1 DESCRIPTION

Iterates all resources pointed at in DBSTAG_DBIMAP_FILE and determines if they are accessible or not

=cut
