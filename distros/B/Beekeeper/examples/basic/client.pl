#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }


use MyClient;

my $str = MyClient->uppercase( "Hello!" );

print "$str\n";
