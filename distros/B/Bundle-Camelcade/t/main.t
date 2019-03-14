use warnings FATAL => 'all';
use strict;
use Test::More;

#     Devel::Camelcadedb attempts to start debugger
#     Devel::Cover missing dry run
#     Devel::NYTProf missing dry run

use_ok($_) for qw/
    App::cpanminus
    App::Prove::Plugin::PassEnv
    B::Deparse
    Config
    File::Find
    JSON
    Perl::Critic
    Perl::Tidy
    TAP::Formatter::Camelcade
    Test::Harness
/;

done_testing;