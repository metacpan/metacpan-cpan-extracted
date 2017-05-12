#!/usr/bin/env perl

use strict;
use warnings;

# my %auth = (
#
# );
#
#
# for ( sort { $auth{$a} cmp $auth{$b} } keys %auth ) {
#     my ( $f, $l ) = split /\s/, $auth{$_};
#     print "$f '$_' $l\n";
# }


use lib qw(lib ../lib);
use Acme::CPANAuthors;

my $authors  = Acme::CPANAuthors->new("Canadian");

my $number   = $authors->count;
my @ids      = $authors->id;
my @distros  = $authors->distributions("ZOFFIX");
my $url      = $authors->avatar_url("ZOFFIX");
my $kwalitee = $authors->kwalitee("ZOFFIX");
my $name     = $authors->name("ZOFFIX");
