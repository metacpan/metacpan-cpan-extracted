#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

# Test a bug reported by Pasha Sadri
# <NEBBIPJPBMMMDNHELFELOEEECHAA.pasha@yahoo-inc.com>
my $warnings;
BEGIN {
    $SIG{__WARN__} = sub { $warnings = join '', @_ };
}

package Foo;
use fields;
use protected qw(protected_f);


package Bar;
use public qw(f);
use base qw(Foo); # base comes after 'use public'


::like $warnings,
       '/^Bar is inheriting from Foo but already has its own fields!/',
       'Inheriting from a base with protected fields warns';

