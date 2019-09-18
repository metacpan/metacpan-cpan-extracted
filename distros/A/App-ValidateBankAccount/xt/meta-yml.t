#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use App::ValidateBankAccount;
use Test::More;

eval "use Test::CPAN::Meta";
plan skip_all => "Test::CPAN::Meta required for testing MYMETA.yml" if $@;

my $meta    = meta_spec_ok('MYMETA.yml');
my $version = $App::ValidateBankAccount::VERSION;

is($meta->{version}, $version, 'MYMETA.yml distribution version matches');

if ($meta->{provides}) {
    foreach my $mod (keys %{$meta->{provides}}) {
        eval("use $mod;");
        my $mod_version = eval(sprintf("\$%s::VERSION", $mod));
        is($meta->{provides}{$mod}{version}, $version, "MYMETA.yml entry [$mod] version matches");
        is($mod_version, $version, "Package $mod doesn't match version.");
    }
}

done_testing();
