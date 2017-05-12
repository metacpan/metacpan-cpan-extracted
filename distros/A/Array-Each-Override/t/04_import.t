#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

use Array::Each::Override ();

my @tests = (
    {
        imports  => '',
        locally  => [qw<each keys values>],
        globally => [],
    },
    {
        imports  => ':global',
        locally  => [],
        globally => [qw<each keys values>],
    },
    {
        imports  => ':safe',
        locally  => [qw<array_each array_keys array_values>],
        globally => [],
    },
    {
        imports  => ':global :safe',
        invalid  => 1,
    },
    {
        imports  => 'each :global',
        invalid  => 1,
    },
);

plan tests => 2 * @tests;

my $n = 0;  # oh, the irony: this wants to use array_each()
for my $t (@tests) {
    $n++;
    delete @CORE::GLOBAL::{qw<each keys values>};
    my $package = "Array::Each::Override::_test$n";
    my $imports = $t->{imports} eq '' ? '' : "qw<$t->{imports}>";
    eval "package $package; use Array::Each::Override $imports";
    my $err = $@;
    if ($t->{invalid}) {
        ok($err, "Importing qw<$t->{imports}> failed correctly");
        pass("Stub test following desired exception for qw<$t->{imports}>");
    }
    else {
        my @import_failures = import_failures($package, $err, $t);
        is(@import_failures, 0,
            "Importing qw<$t->{imports}> had the desired effect");
        diag($_) for @import_failures;

        eval "package $package; no Array::Each::Override $imports";
        $err = $@;
        my @unimport_failures = unimport_failures($package, $err, $t);
        is(@unimport_failures, 0,
            "Unimporting qw<$t->{imports}> had the desired effect");
        diag($_) for @unimport_failures;
    }
}

sub import_failures {
    my ($package, $err, $t) = @_;

    if ($err) {
        diag("Importing qw<$t->{imports}> threw an exception ($err)");
        return 0;
    }

    my %local_name  = map { $_ => 1 } @{ $t->{locally} };
    my %global_name = map { $_ => 1 } @{ $t->{globally} };

    my @failures;

    my $stash = do { no strict qw<refs>; \%{"$package\::"} };
    while (my ($name, $typeglob) = CORE::each %$stash) {
        next if $local_name{$name};
        next if $name eq 'BEGIN';
        push @failures, "Incorrectly imported local '$name' for qw<$t->{imports}>";
    }
    for my $name (CORE::keys %local_name) {
        next if $stash->{$name};
        push @failures, "Local '$name' not imported for qw<$t->{imports}>";
    }

    while (my ($name, $typeglob) = CORE::each %CORE::GLOBAL::) {
        next if $global_name{$name};
        push @failures, "Incorrectly imported global '$name' for qw<$t->{imports}>";
    }
    for my $name (CORE::keys %global_name) {
        next if $CORE::GLOBAL::{$name};
        push @failures, "Global '$name' not imported for qw<$t->{imports}>";
    }

    return @failures;
}

sub unimport_failures {
    my ($package, $err, $t) = @_;

    if ($err) {
        diag("Unimporting qw<$t->{imports}> threw an exception ($err)");
        return 0;
    }

    my $package_stash = do { no strict qw<refs>; \%{"$package\::"} };

    my @failures;

    for my $stash ($package_stash, \%CORE::GLOBAL::) {
        while (my ($name, $typeglob) = CORE::each %$stash) {
            next if $name eq 'BEGIN';
            my $package = *$typeglob{PACKAGE};
            push @failures, "Failed to unimport $name from $package";
        }
    }

    return @failures;
}
