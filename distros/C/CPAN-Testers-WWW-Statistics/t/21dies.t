#!perl

use strict;
use warnings;

use CPAN::Testers::WWW::Statistics;
use CPAN::Testers::WWW::Statistics::Pages;
use CPAN::Testers::WWW::Statistics::Graphs;

use lib 't';
use CTWS_Testing;

use Test::More;

if(CTWS_Testing::has_environment()) { plan tests    => 12; }
else                                { plan skip_all => "Environment not configured"; }

my $dbconfig    = 't/_DBDIR/databases.ini';

my %config = (
    't/data/21config00.ini' => { db => 0, result => "Cannot load configuration file [t/data/21config00.ini]\n" },
    't/data/21config01.ini' => { db => 1, result => "Must specify the output directory\n" },        # no output directory
    't/data/21config02.ini' => { db => 1, result => "Must specify the template directory\n" },      # no template directory
    't/data/21config03.ini' => { db => 0, result => "No configuration for CPANSTATS database\n" },  # no CPANSTATS database
);

for my $file (sort keys %config) {
    my $config = $config{$file}->{db} ? CTWS_Testing::create_config( $file ) : $file;
    eval { CPAN::Testers::WWW::Statistics->new(config => $config) };
    is($@, $config{$file}->{result}, "config: $config");
}

%config = (
    't/data/21config07.ini' => { db => 1, result =>  "Template directory not found\n" },
    't/data/21config10.ini' => { db => 1, result =>  "Must specify the path of the address file\n" },
    't/data/21config11.ini' => { db => 1, result =>  "Address file not found\n" },
);

for my $file (sort keys %config) {
    my $config = $config{$file}->{db} ? CTWS_Testing::create_config( $file ) : $file;
    ok( my $obj   = CPAN::Testers::WWW::Statistics->new(config => $config), "got parent object" );
    eval { $obj->make_pages };
    is($@, $config{$file}->{result}, "config: $config");
}

eval { CPAN::Testers::WWW::Statistics->new() };
is($@,"Must specify the configuration file\n");
eval { CPAN::Testers::WWW::Statistics->new(config => 'doesnotexist') };
is($@,"Configuration file [doesnotexist] not found\n");
