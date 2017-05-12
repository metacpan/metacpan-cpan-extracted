#!/usr/bin/perl

use strict;
use warnings;
use lib qw( t/lib );

use Test::More 'no_plan';

# this test checks that custom headings are passed into templates
# and the correct extjs columnmodel created. also checks an undef
# has no effect.

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/headings_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album", "Get HTML for album table");
my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

# nasty, but simple
my ($colmodel) = ($content =~ m/Ext.grid.ColumnModel\(\[(.+?)\]\);/s);
#print STDERR $colmodel;
my @cols = ($colmodel =~ m/{(.+?)}\s*,/sg);
#use Data::Dumper;
#print STDERR Dumper \@cols;

ok(scalar @cols == 8, 'number of columns in ColumnModel');

ok($cols[1] =~ m/header:\s+'Deleted'/, 'second heading is TheTitle');
ok($cols[2] =~ m/header:\s+'Recorded'/, 'undefined heading is ignored');

__END__

