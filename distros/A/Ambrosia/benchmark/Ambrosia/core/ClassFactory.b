#!/usr/bin/perl
use strict;
use warnings;
use lib qw(lib t);

use Benchmark;

use Ambrosia::core::ClassFactory;

my $i = 0;
timethese(50_000, {
        'create'    => sub {
            Ambrosia::core::ClassFactory::create('Employes::Person::' . $i++, {public => [qw/FirstName LastName Age/]});
        },
});

timethese(500_000, {
        'create_object'    => sub {
            Ambrosia::core::ClassFactory::create_object('Person', (FirstName => 'John', LastName => 'Smith', Age => 33));
        },
});

