# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use warnings;

use Test::More qw(no_plan); 

use CGI::Getopt;
my $class = 'CGI::Getopt';
my $obj = CGI::Getopt->new; 

isa_ok($obj, "CGI::Getopt");

my @md = @CGI::Getopt::EXPORT_OK;
foreach my $m (@md) {
    ok($obj->can($m), "$class->can('$m')");
}

# 2005/04/01: get_inputs($ifn, $opt)
# my $ifn = '/opt/orasw/dba/cgi/lib/perl5/Fax/DataFax/DataFax.ini';
# my $opt = 'hvS:a:';
# $obj->debug(5);
# $obj->{ifn} = $ifn;
# $obj->{opt} = $opt;
# $obj->disp_param($obj);
# my $ar = $obj->get_inputs;
# $obj->disp_param($ar);

1;

