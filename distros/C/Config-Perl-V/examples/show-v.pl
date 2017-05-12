#!/pro/bin/perl

use strict;
use warnings;

use Data::Peek;
use Config::Perl::V;

my $conf = Config::Perl::V::myconfig [ @ARGV ];
DDumper $conf;

DDumper Config::Perl::V::summary $conf;
