#!perl

use strict;
use warnings;

use CPAN::Testers::WWW::Statistics;
#use Data::Dumper;
use Test::More;

use lib 't';
use CTWS_Testing;

if(CTWS_Testing::has_environment()) { plan tests    => 32; }
else                                { plan skip_all => "Environment not configured"; }

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );
ok( my $pages = CTWS_Testing::getPages(), "got pages object" );

$pages->setdates();
#diag(Dumper($pages->{dates}));

like($pages->{dates}{RUNTIME},      qr{^\w{3},\s+\d{1,2}\s+\w{3}\s+\d{4}\s+\d{2}:\d{2}:\d{2}\s+\w+$},   'RUNTIME matches pattern');
like($pages->{dates}{RUNDATE},      qr{^\d{1,2}\w{2}\s+\w+\s+\d{4}$},                   'RUNDATE matches pattern');
like($pages->{dates}{RUNDATE2},     qr{^\d{1,2}\w{2}\s+\w+\s+\d{4}$},                   'RUNDATE2 matches pattern');
like($pages->{dates}{RUNDATE3},     qr{^\d{1,2}\w{2}\s+\w+\s+\d{4},\s+\d{2}:\d{2}$},    'RUNDATE3 matches pattern');
like($pages->{dates}{THISMONTH},    qr{^\d{6}$},                                        'THISMONTH matches pattern');
like($pages->{dates}{THISDATE},     qr{^\w+\s+\d+$},                                    'THISDATE matches pattern');
like($pages->{dates}{LASTMONTH},    qr{^\d{6}$},                                        'LASTMONTH matches pattern');
like($pages->{dates}{LASTDATE},     qr{^\w+\s+\d+$},                                    'LASTDATE matches pattern');
like($pages->{dates}{PREVMONTH},    qr{^\d{2}/\d{2}$},                                  'PREVMONTH matches pattern');
like($pages->{dates}{THATMONTH},    qr{^\d{6}$},                                        'THATMONTH matches pattern');

$pages->setdates(1357041600);

like($pages->{dates}{RUNTIME},      qr{^Tue,  1 Jan 2013\s+\d{2}:\d{2}:\d{2}\s+\w+$},   'RUNTIME matches pattern');
like($pages->{dates}{RUNDATE},      qr{^1st January 2013$},                             'RUNDATE matches pattern');
like($pages->{dates}{RUNDATE2},     qr{^2nd \w+ 20\d{2}$},                              'RUNDATE2 matches pattern');
like($pages->{dates}{RUNDATE3},     qr{^2nd \w+ 20\d{2},\s+\d{2}:\d{2}$},               'RUNDATE3 matches pattern');
like($pages->{dates}{THISMONTH},    qr{^201301$},                                       'THISMONTH matches pattern');
like($pages->{dates}{THISDATE},     qr{^January 2013$},                                 'THISDATE matches pattern');
like($pages->{dates}{LASTMONTH},    qr{^201212$},                                       'LASTMONTH matches pattern');
like($pages->{dates}{LASTDATE},     qr{^December 2012$},                                'LASTDATE matches pattern');
like($pages->{dates}{PREVMONTH},    qr{^12/12$},                                        'PREVMONTH matches pattern');
like($pages->{dates}{THATMONTH},    qr{^201211$},                                       'THATMONTH matches pattern');

$pages->setdates(1360843200);

like($pages->{dates}{RUNTIME},      qr{^Thu, 14 Feb 2013\s+\d{2}:\d{2}:\d{2}\s+\w+$},   'RUNTIME matches pattern');
like($pages->{dates}{RUNDATE},      qr{^14th February 2013$},                           'RUNDATE matches pattern');
like($pages->{dates}{RUNDATE2},     qr{^2nd \w+ 20\d{2}$},                              'RUNDATE2 matches pattern');
like($pages->{dates}{RUNDATE3},     qr{^2nd \w+ 20\d{2},\s+\d{2}:\d{2}$},               'RUNDATE3 matches pattern');
like($pages->{dates}{THISMONTH},    qr{^201302$},                                       'THISMONTH matches pattern');
like($pages->{dates}{THISDATE},     qr{^February 2013$},                                'THISDATE matches pattern');
like($pages->{dates}{LASTMONTH},    qr{^201301$},                                       'LASTMONTH matches pattern');
like($pages->{dates}{LASTDATE},     qr{^January 2013$},                                 'LASTDATE matches pattern');
like($pages->{dates}{PREVMONTH},    qr{^01/13$},                                        'PREVMONTH matches pattern');
like($pages->{dates}{THATMONTH},    qr{^201212$},                                       'THATMONTH matches pattern');
