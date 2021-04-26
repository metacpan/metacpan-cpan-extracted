#!/usr/bin/perl -wT

use strict;
use warnings;

BEGIN { unshift @INC, ($ENV{'PERL5LIB'} =~ m/([^:]+)/g); }

use MyApp::Client;


my $client = MyApp::Client->new;

$client->run;

1;
