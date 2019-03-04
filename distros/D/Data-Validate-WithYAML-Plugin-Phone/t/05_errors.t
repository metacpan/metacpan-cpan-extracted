#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::Validate::WithYAML::Plugin::Phone;

my $module = 'Data::Validate::WithYAML::Plugin::Phone';

{
    my $error;
    eval {
        $module->check(undef);
    } or $error = $@;

    like $error, qr/no value to check/;
}

{
    my $error;
    eval {
        $module->check('+4917712346799', { country => 'TEST' } );
    } or $error = $@;

    like $error, qr/No support for TEST/;
}

done_testing();
