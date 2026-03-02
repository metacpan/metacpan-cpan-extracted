# Copyright (c) 2021-2026 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).
#
# The license grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the license.

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 00_modules.t'

use strict;
use warnings;
use Test::More 0.82;
use File::Spec;

my $BUNDLE = File::Spec->catfile('lib', 'Bundle', 'Maintainer', 'MHASCH.pm');

my @modules  = ();
my $versions = 0;
my $errors   = 0;

if (open my $fh, '<', $BUNDLE) {
    while (<$fh>) {
        next if !(/^=head1 CONTENTS/ ... /^=head1/) || /^=/ || !/\S/;
        s/\s+-\s.*//s;
        s/^\s+//;
        s/\s+\z//;
        if (/^(\S+)(?:\s+([0-9]\S*))?\z/) {
            push @modules, [$1, $2];
            ++$versions if $2;
        }
        else {
            diag("strange content: $_");
            ++$errors;
        }
    }
    close $fh;
}
else {
    plan skip_all => "cannot open $BUNDLE";
}
if ($errors || !@modules) {
    plan skip_all => "cannot parse $BUNDLE";
}
plan tests => $versions + @modules;

foreach my $mv (@modules) {
    my ($module, $version) = @{$mv};
    SKIP: {
        my $loadable = eval "require $module";
        skip "$module not loadable", $version? 2: 1 if !$loadable;
        pass("require $module");
        version_ok($module, $version) if $version;
    }
}

sub version_ok {
    my ($module, $version) = @_;
    SKIP: {
        my $loaded = defined eval '$' . $module . '::VERSION';
        skip "$module not loaded", 1 if !$loaded;

        my $have = eval { $module->VERSION($version) };
        my $ok   = defined $have;
        note("we have $module version $have") if $ok && $version ne $have;
        diag($@) if !$ok;
        ok $ok, "version_ok $module => $version";
    }
}

__END__
