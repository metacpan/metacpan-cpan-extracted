use 5.010;
use strict;
use warnings;

use Test::More tests => 9;
use Test::NoWarnings;

use Business::DPD;

{
    my $dpd = Business::DPD->new;

    is($dpd->schema_class,'Business::DPD::DBIC::Schema','default schema class');
    is(@{$dpd->dbi_connect},1,'default dbi connect, 1 element');
    like($dpd->dbi_connect->[0],qr{t/dpd_test.sqlite$},'default dbi connect, connect');
}

{
    my $dpd = Business::DPD->new({
        schema_class => 'My::Schema',
        dbi_connect => ['dbi:Pg:dbname=foo','user','passwd'],
    });

    is($dpd->schema_class,'My::Schema','my schema class');
    is(@{$dpd->dbi_connect},3,'custom dbi connect, 3 element');
    is($dpd->dbi_connect->[0],'dbi:Pg:dbname=foo','custom dbi connect, connect');
    is($dpd->dbi_connect->[1],'user','custom dbi connect, connect');
    is($dpd->dbi_connect->[2],'passwd','custom dbi connect, connect');
}

