# -*- mode: cperl; -*-
use Test::Dependencies
    exclude => [qw(Test::Dependencies Test::Base Test::Perl::Critic
                   )],
    style   => 'light';
ok_dependencies();
