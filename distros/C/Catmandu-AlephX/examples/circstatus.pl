#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

my $aleph = Catmandu::AlephX->new(url => "http://borges1.ugent.be/X");

my $circstatus = $aleph->circ_status(sys_no => '001484478',library => 'rug01');

if($circstatus->is_success){
  print Dumper($circstatus);
}else{
  say STDERR join('',@{$circstatus->errors});
}
