#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Transpose::Validator;

eval "use  DateTime::Format::ISO8601";

if ($@) {
    plan skip_all => "No  DateTime::Format::ISO8601 module.";
}

plan tests => 19;

require Data::Transpose::Validator::DateTime;

my @valid = (
    '1985-04-12T10:15:30.5+04:00', #YYYY-MM-DDThh:mm:ss.sshh:mm
    '19850412T101530+04', #YYYYMMDDThhmmsshh
    '1985-04-12T10:15:30+04', #YYYY-MM-DDThh:mm:sshh
    '19850412T1015', #YYYYMMDDThhmm
    '1985-04-12T10:15', #YYYY-MM-DDThh:mm
    '1985102T1015Z', #YYYYDDDThhmmZ
    '1985-102T10:15Z', #YYYY-DDDThh:mmZ
    '1985W155T1015+0400', #YYYYWwwDThhmmhhmm
    '1985-W15-5T10:15+04', #YYYY-Www-DThh:mmhh
    );

my @invalid = (
    'May20th1943',
    '607-467-5525',
    '991985102T1015Z',
    'string',
    '4444111111111111',
    '5/20/1988',
    '1985-W15-5T10:1504',
);

my $datetime = Data::Transpose::Validator::DateTime->new;

foreach (@valid) {
    ok( $datetime->is_valid($_), "$_ is valid" );
}

foreach (@invalid) {
    ok( !$datetime->is_valid($_), "$_ is not valid");
}

my $form = { mydate => '19850412T101530+04' };

my $dtv = Data::Transpose::Validator->new();

$dtv->prepare(
    mydate => {
        validator => "DateTime",
        required => 1,
    }
);

my $clean = $dtv->transpose($form);
ok($clean, "validation ok");

$form = { mydate => '05/20/1977' };

$dtv = Data::Transpose::Validator->new();

$dtv->prepare(
    mydate => {
        validator => "DateTime",
        required => 1,
    }
);

$clean = $dtv->transpose($form);
ok( !$clean, "validation fails");

$form = { mydate => '' };

$dtv = Data::Transpose::Validator->new();

$dtv->prepare(
    mydate => {
        validator => "DateTime",
        required => 1,
    }
);

$clean = $dtv->transpose($form);
ok( !$clean, "validation failed field blank");

done_testing;
