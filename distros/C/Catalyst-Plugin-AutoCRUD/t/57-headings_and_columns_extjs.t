#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# tests use of both headings and columns at the same time,
# with overlapping configuration

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/headings_and_columns_extjs.conf';
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

ok($cols[0] =~ m/header:\s+'Id'/, 'first heading is Id');
ok($cols[1] =~ m/header:\s+'TheTitle'/, 'second heading is TheTitle');
ok($cols[3] =~ m/header:\s+'RecordedWhen'/, 'fourth heading is RecordedWhen');

foreach my $id (0,1) {
    ok($cols[$id] !~ m/hidden/, "col pos $id is not hidden");
}
foreach my $id (2,3,4,5) {
    ok($cols[$id] =~ m/hidden/, "col pos $id is hidden column");
}

__END__

