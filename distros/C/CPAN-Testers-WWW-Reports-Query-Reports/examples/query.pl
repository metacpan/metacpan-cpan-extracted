#!/usr/bin/perl -w
use strict;

use lib qw(lib);

use Data::Dumper;
use CPAN::Testers::WWW::Reports::Query::Reports;

my $query = CPAN::Testers::WWW::Reports::Query::Reports->new();
exit    unless($query);

my $data = $query->date( '2012-03-30' );
print Dumper($data);

$data = $query->data();
print Dumper($data);


my $data = $query->date( '20120330' } );
print Dumper($data);

$data = $query->data();
print Dumper($data);
