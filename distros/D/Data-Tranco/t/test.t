#!/usr/bin/perl
use Test::More;
use strict;
use constant {
    TTL         => 31536000, # one year
    SAMPLE_SIZE => 5,
    TLD         => 'microsoft', # will be present but won't have lots of entries
    DOMAIN      => 'microsoft.com', # should also always be present
};
use vars qw(@random @top @sample @all);
use warnings;

require_ok('Data::Tranco');

$Data::Tranco::TTL = TTL;

cmp_ok($Data::Tranco::TTL, '==', TTL);

@random = Data::Tranco->random_domain;
cmp_ok(scalar(@random), '==', 2);

@top = Data::Tranco->top_domain;
cmp_ok(scalar(@top), '==', 2);

@sample = Data::Tranco->sample(SAMPLE_SIZE);
cmp_ok(scalar(@sample), '==', SAMPLE_SIZE);

@top = Data::Tranco->top_domains(SAMPLE_SIZE);
cmp_ok(scalar(@top), '==', SAMPLE_SIZE);

@all = Data::Tranco->all(TLD);
cmp_ok(scalar(@all), '>', 0);

cmp_ok(scalar(Data::Tranco->rank(DOMAIN)), '>=', 1);

done_testing;
