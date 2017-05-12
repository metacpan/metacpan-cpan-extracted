#!/usr/bin/env perl
use Test::Most;
use Acme::ReturnValue;
use utf8;
use Encode;

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/Interesting.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->bad,[],'no bad');
    
    my $data = $arv->interesting->[0];
    is($data->{package},'Interesting','package');
    is($data->{value},q|q{that's interesting!}|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/UseUninstalled.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->bad,[],'no bad');
    
    my $data = $arv->interesting->[0];
    is($data->{package},'UseUninstalled','package');
    is($data->{value},q|'ha!'|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/MockTime.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->interesting,[],'no interesting');
    
    my $data = $arv->bad->[0];
    is($data->{package},'Test::MockTime','package');
    is($data->{bad},q|*restore_time = \\&restore|,'value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/RT83963_encoding.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->bad,[],'no bad');

    my $data = $arv->interesting->[0];
    is($data->{package},'Acme::CPANAuthors::French','package');
    is($data->{value},'q<
    listen to 「陽の当たる月曜日」 by サエキけんぞう
    » http://www.myspace.com/cloclomadeinjapan
>','utf8 value');
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/Envolve.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->bad,[],'no bad');
    cmp_deeply($arv->interesting,[],'no interesting');

    my $data = $arv->interesting->[0];
}

{
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/TinyClick.pm');
    cmp_deeply($arv->failed,[],'no failed');
    cmp_deeply($arv->bad,[],'no bad');
    my $data = $arv->interesting->[0];
    is($data->{package},'WWW::Shorten::TinyClick','package');
    is($data->{value},'0','interesting: 0');
}

done_testing();

# invalid returns:
# Test::MockTime
# SpamMonkey::Config

# wrong postives
# RayApp
