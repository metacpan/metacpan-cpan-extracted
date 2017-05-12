#!/usr/bin/env perl
use Test::Most;
use Acme::ReturnValue;

my @boring = qw(Boring RayApp);
plan tests => @boring * 3;

foreach my $boring (@boring) {
    my $arv=Acme::ReturnValue->new;
    $arv->in_file('t/pms/'.$boring.'.pm');
    cmp_deeply($arv->failed,[],"$boring: no failed");
    cmp_deeply($arv->interesting,[],"$boring: no interesting");
    cmp_deeply($arv->bad,[],"$boring: no bad");
}


