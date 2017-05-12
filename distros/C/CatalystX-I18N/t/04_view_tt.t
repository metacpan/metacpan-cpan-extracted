#!perl
use strict;
use warnings;

use Test::Most tests=>12+1;
use Test::NoWarnings; 

use lib qw(t/testapp/lib);

use Catalyst::Test 'TestApp';

{
    my($response) = get('/base/test7');
    my @lines = grep { s/<div>(.+)<\/div>/$1/ }split(/[\n\r]/,$response);
    is($lines[0],'1K','Format 1 (bytes) ok');
    is($lines[1],'12','Format 2 (number) ok');
    is($lines[2],'-12,2','Format 3 (negative number) ok');
    is($lines[3],'++EUR 22,00','Format 4 (price) ok');
    is($lines[4],'-EUR 23,00','Format 5 (negative price) ok');
    is($lines[5],'++EUR 233.634,23','Format 6 ( price) ok');
    is($lines[6],'-12,2','Format 7 (negative number) ok');
    is($lines[7],'-12,200','Format 8 (negative number fixed) ok');
    is($lines[8],'string4 de_AT 4 hasen','Format 9 (maketext) ok');
    is($lines[9],'string4 de_AT 1 hase','Format 10 (maketext) ok');
    is($lines[10],'Afghanistan,Ägypten,Albanien,Algerien,Andorra,Äquatorialguinea,Äthiopien,Bahamas,Zypern','Collate 1 ok');
    is($lines[11],'Afghanistan,Albanien,Algerien,Andorra,Bahamas,Zypern,Ägypten,Äquatorialguinea,Äthiopien','Collate 2 ok');
}