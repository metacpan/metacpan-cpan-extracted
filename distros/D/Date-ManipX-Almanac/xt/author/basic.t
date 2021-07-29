package main;

use 5.010;

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::LoadModule;

use lib qw{ inc };
use My::Module::Meta;

my $meta = My::Module::Meta->new();

note 'Ensure all optional modules are present for author testing';

load_module_ok $_ for $meta->optionals_for_testing();

done_testing;

1;

# ex: set textwidth=72 :
