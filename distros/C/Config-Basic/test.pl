#!/usr/bin/perl
use Test::Simple tests => 4;
use strict;
use lib "./lib/Config";
use Basic;
use IO::All;

use Data::Dumper;

my $data_file = "test.cfg";
my @data      = io( $data_file )->chomp->slurp;  
ok( scalar( @data) > 10,        'NumExplodingSheep() get' );
my $a         = Config::Basic->new(
    -data => \@data,
    -sections => [ 'global', '#\s+listen', 'listen', 'defaults' ],
);


my $res = $a->parse();

my ($s ,$p)= $a->sections() ;

ok((scalar(@$s)) == 4, "Number of section in file" );
ok($res->{listen}[0]->{start} == 25 , "Start line in section header");
ok($res->{listen}[0]->{end} == 31 , "Start line in section header");
