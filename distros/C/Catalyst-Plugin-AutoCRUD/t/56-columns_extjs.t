#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# this test should restrict the displayed columns to only two
# but not alter headings. it uses the hidden setting in extjs

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/columns_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album", "Get HTML for album table");
my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

# nasty, but simple
my ($colmodel) = ($content =~ m/Ext.grid.ColumnModel\(\[(.+?)\]\);/s);
my @cols = ($colmodel =~ m/{(.+?)}\s*,/sg);
#use Data::Dumper;
#print STDERR Dumper \@cols;

ok(scalar @cols == 8, 'number of columns in ColumnModel');

foreach my $id (0,1) {
    ok($cols[$id] !~ m/hidden/, "col pos $id is not hidden");
}
foreach my $id (2,3,4,5) {
    ok($cols[$id] =~ m/hidden/, "col pos $id is hidden column");
}

__END__

