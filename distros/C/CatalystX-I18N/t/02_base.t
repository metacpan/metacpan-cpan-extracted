#!perl
use strict;
use warnings;

use Test::Most tests=>87+1;
use Test::NoWarnings;

use lib qw(t/);
use testlib;


my $mech = init();
$mech->{catalyst_debug} = 1;

# Test 1 - set current locale
{
    my $response = request($mech,'/base/test1');
    is($response->{default_locale},'de_AT','Default locale');
    is($response->{locale},'de_CH','Current locale');
    
}

# Test 2 - get locale
{
    $mech->add_header( 'user-agent' => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2) Gecko/20100115 Firefox/3.6" );
    my $response = request($mech,'/base/test2');
    is($response->{session},'de_CH','Session locale');
    is($response->{user},undef,'User locale');
    is($response->{browser},'fr','Browser language');
}

# Test 3a - get locale again
{
    $mech->add_header( 'user-agent' => "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; fr; rv:1.9.2) Gecko/20100115 Firefox/3.6" );
    my $response = request($mech,'/base/test3');
    is($response->{datetime}{locale},'German Austria','DateTime locale');
    is($response->{datetime}{timezone},'Europe/Vienna','DateTime timezone');
    is($response->{locale},'de_AT','Locale');
    is($response->{locale_from_c},'de_AT','Locale from $c');
    is($response->{request}{browser_language},'fr','Browser language');
    like($response->{number_format},qr/^\+\+EUR\s+27,03$/,'Browser language');
}


# Test 3b - get with strange user-agent
{
    $mech->add_header( 'user-agent' => "hidden-agent" );
    my $response = request($mech,'/base/test3');
    is($response->{request}{browser_territory},undef,'Browser territory');
    is($response->{request}{browser_language},undef,'Browser language');

}

# Test 4a - maketext inheritance
{
    my $response = request($mech,'/base/test4/de_AT');
    is($response->{locale},'de_AT','Locale');
    is($response->{translation}{1},'string1 de_AT','String 1 for de_AT ok');
    is($response->{translation}{4},'string4 de_AT 4 hasen','String 4 for de_AT ok');
    is($response->{translation}{5},'string5 de','String 5 for de_AT ok');
    is($response->{translation}{6},'string6','String 6 for de_AT ok');
}

# Test 4b - maketext inheritance
{
    my $response = request($mech,'/base/test4/de_CH');
    is($response->{locale},'de_CH','Locale');
    is($response->{translation}{1},'string1 de','String 1 for de_CH ok');
    is($response->{translation}{4},'string4 de 4 hasen','String 4 for de_CH ok');
    is($response->{translation}{5},'string5 de','String 5 for de_CH ok');
    is($response->{translation}{6},'string6','String 6 for de_CH ok');
}

# Test 4c - maketext inheritance
{
    my $response = request($mech,'/base/test4/fr_CH');
    is($response->{locale},'fr_CH','Locale');
    is($response->{translation}{1},'string1 fr_CH','String 1 for fr_CH ok');
    is($response->{translation}{4},'string4 fr_CH 4 lapins','String 4 for fr_CH ok');
    is($response->{translation}{5},'string5','String 5 for fr_CH ok');
    is($response->{translation}{6},'string6','String 6 for fr_CH ok');
}

# Test 4d - maketext inheritance
{
    my $response = request($mech,'/base/test4/fr');
    is($response->{locale},'fr','Locale');
    is($response->{translation}{1},'string1','String 1 for fr ok');
    is($response->{translation}{4},'string4','String 4 for fr ok');
    is($response->{translation}{5},'string5','String 5 for fr ok');
    is($response->{translation}{6},'string6','String 6 for fr ok');
}

# Test 4e - invalid locale
{
    my $response = request($mech,'/base/test4/xx');
    is($response->{locale},'de_AT','Locale');
}


# Test 5 - locale set
{
    my $response = request($mech,'/base/test5');
    cmp_deeply($response,{
       'de_AT' => {
         'timezone' => 'Europe/Vienna'
       },
       'de_CH' => {
         'timezone' => 'Europe/Zurich'
       },
       'de_DE' => {
         'timezone' => 'Europe/Berlin'
       },
       'fr_CH' => {
         'timezone' => 'Europe/Zurich'
       },
       'fr' => {
         'timezone' => 'floating',
       }
    },'Multiple locales ok');
}

# Test 5 - locale set
{
    my $response = request($mech,'/base/test8');
    is($response->{sort_collate},'Afghanistan,Ägypten,Albanien,Algerien,Andorra,Äquatorialguinea,Äthiopien,Bahamas,Zypern');
    is($response->{sort_perl},'Afghanistan,Albanien,Algerien,Andorra,Bahamas,Zypern,Ägypten,Äquatorialguinea,Äthiopien');
}

# Test 6a - data localize inheritance
{
    my $response = request($mech,'/base/test9/de_AT');
    is($response->{locale},'de_AT','Locale');
    is($response->{translation}{1},'string1 de_AT','String 1 for de_AT ok');
    is($response->{translation}{4},'string4 de_AT 4 hasen','String 4 for de_AT ok');
    is($response->{translation}{5},'string5 de','String 5 for de_AT ok');
    is($response->{translation}{6},'string6','String 6 for de_AT ok');
}

# Test 6b - data localize inheritance
{
    my $response = request($mech,'/base/test9/de_CH');
    is($response->{locale},'de_CH','Locale');
    is($response->{translation}{1},'string1 de','String 1 for de_CH ok');
    is($response->{translation}{4},'string4 de 4 hasen','String 4 for de_CH ok');
    is($response->{translation}{5},'string5 de','String 5 for de_CH ok');
    is($response->{translation}{6},'string6','String 6 for de_CH ok');
}

# Test 6c - data localize inheritance
{
    my $response = request($mech,'/base/test9/fr_CH');
    is($response->{locale},'fr_CH','Locale');
    is($response->{translation}{1},'string1 fr_CH','String 1 for fr_CH ok');
    is($response->{translation}{4},'string4 fr_CH 4 lapins','String 4 for fr_CH ok');
    is($response->{translation}{5},'string5','String 5 for fr_CH ok');
    is($response->{translation}{6},'string6','String 6 for fr_CH ok');
}

# Test 6d - data localize inheritance
{
    my $response = request($mech,'/base/test9/fr');
    is($response->{locale},'fr','Locale');
    is($response->{translation}{1},'string1','String 1 for fr ok');
    is($response->{translation}{4},'string4','String 4 for fr ok');
    is($response->{translation}{5},'string5','String 5 for fr ok');
    is($response->{translation}{6},'string6','String 6 for fr ok');
}