#!/usr/bin/env perl
# Validates META.{yml,json} against their CPAN spec via Test::CPAN::Meta
# and Test::CPAN::Meta::JSON. kwalitee already does conformance, but
# these run earlier in the local author flow so a malformed META gets
# caught before make dist.
use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING=1 to run distmeta tests'
    unless $ENV{RELEASE_TESTING};

my @missing = grep { !-f $_ } qw(META.yml META.json);
plan skip_all => "META not generated yet (run 'make dist' first): missing @missing"
    if @missing;

my $have_yaml = eval { require Test::CPAN::Meta;       1 };
my $have_json = eval { require Test::CPAN::Meta::JSON; 1 };
my $have_cm   = eval { require CPAN::Meta;             1 };
plan skip_all => 'need Test::CPAN::Meta, Test::CPAN::Meta::JSON, or CPAN::Meta'
    unless $have_yaml || $have_json || $have_cm;

subtest 'structural conformance' => sub {
    if ($have_yaml) {
        Test::CPAN::Meta->import;
        Test::CPAN::Meta::meta_yaml_ok();
    }
    if ($have_json) {
        Test::CPAN::Meta::JSON->import;
        Test::CPAN::Meta::JSON::meta_json_ok();
    }
    pass 'no structural validator installed' unless $have_yaml || $have_json;
};

# Value-level invariants (Test::CPAN::Meta only checks structure).
subtest 'meta values' => sub {
    plan skip_all => 'CPAN::Meta not available' unless $have_cm;
    my $m = CPAN::Meta->load_file('META.json');
    my @lic = $m->license;
    is($lic[0], 'perl_5',                    'license is perl_5');
    like($m->abstract, qr/ClickHouse|encoder/i,
                                              'abstract mentions ClickHouse');
    my $repo = ($m->resources->{repository} || {})->{url} // '';
    like($repo, qr{github\.com/vividsnow},    'repo URL points to vividsnow github');
    like($m->name, qr/^ClickHouse-Encoder$/,  'dist name is ClickHouse-Encoder');
};

done_testing();
