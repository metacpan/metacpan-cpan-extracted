#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Simon Xue (http://carmark.javaeye.com), carmark.dlut@gmail.com
#      COMPANY:  SSDUT/Sun MicoSystems
#      VERSION:  1.0
#      CREATED:  2010年12月17日 10时36分57秒
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;

use Acme::Letter;

my $new = Acme::Letter->new();
$new->printString("PDF::API 2");

$new->printString("CODE2PDF");
$new->printString("2");
