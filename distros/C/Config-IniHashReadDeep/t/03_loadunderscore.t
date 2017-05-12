#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Config::IniHashReadDeep;
# use Data::Dumper;

use Test::More tests => 7;


my $file;

$file = 'config/bar.ini';

if (!-e $file){
  $file = 't/config/bar.ini';
}

if (!-e $file){
  die('cant run test, relative path wrong.');
}


my $ini = Config::IniHashReadDeep->new( $file , delimiter => '_')->get_ini();

#  print Dumper($ini);

is( $ini->{'digitsmore'}->{'with'}->{'counting'}->[001]->{'foo'}, '111f' , 'value in array' );
is( $ini->{'digits'}->{'with'}->{'counting'}->[000], '111' , 'value in array' );
is( $ini->{'digits'}->{'with'}->{'counting'}->[001], '112'  , 'value in array');
is( $ini->{'digits'}->{'with'}->{'counting'}->[002], '113'  , 'value in array');

is( $ini->{'main'}->{'test'}, '5'  , 'value in hash');
is( $ini->{'main'}->{'foo'}->{'bar'}, '123'  , 'value in hash');
is( $ini->{'main'}->{'foo'}->{'more'}, '77'  , 'value in hash');



1;


