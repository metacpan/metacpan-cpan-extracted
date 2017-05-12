#!perl

use strict;
use warnings;

use Test::More;
use CPAN::Testers::WWW::Statistics;

use lib 't';
use CTWS_Testing;

if(CTWS_Testing::has_environment()) { plan tests    => 3; }
else                                { plan skip_all => "Environment not configured"; }

my $expected1 = { };
my $expected2 = { 
    '999999' => {
      'solaris' => { 'Jost Krieger (JOST)'          => 2 },
      'darwin'  => { 'Jon Allen (JONALLEN)'         => 2 },
      'openbsd' => { 'bingos + cpan org'            => 1 },
      'linux'   => { 'Oliver Paukstadt (PSTADT)'    => 5,
                     'Dan Collins (DCOLLINS)'       => 4,
                     'Yi Ma Mao (IMACAT)'           => 10,
                     'Andreas J. K&ouml;nig (ANDK)' => 1 },
      'freebsd' => { 'bingos + cpan org'            => 1,
                     'Slaven Rezi&#x0107; (SREZIC)' => 4 },
      'mswin32' => { 'Serguei Trouchelle (STRO)'    => 1,
                     'Ulrich Habel (RHAEN)'         => 2 }
    }
};

ok( my $obj = CTWS_Testing::getObj(), "got parent object" );

$obj->leaderboard( renew => 1 );

#use Data::Dumper;

my $data = $obj->leaderboard( check => 1 );
#diag('check=' . Dumper($data));
is_deeply( $data, $expected1, '.. no differences' );

$data = $obj->leaderboard( results => [ '999999' ] );
#diag('results=' . Dumper($data));
is_deeply( $data, $expected2, '.. known results' );
