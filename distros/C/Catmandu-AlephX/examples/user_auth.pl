#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my %args = (
  library => "rug50",
  staff_user => "fvdpitte",
  staff_pass => "demo"
);
my $info = $aleph->user_auth(%args);
print Dumper($info);
