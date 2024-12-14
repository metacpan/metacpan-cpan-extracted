use strict;
use Test::More 0.98;

use_ok $_ for qw(
    Daje::Plugin::GeneratePerl
    Daje::Plugin::Perl::Manager
    Daje::Plugin::Perl::Generate::Fields
    Daje::Plugin::Perl::Generate::Methods
    Daje::Plugin::Perl::Generate::Class
    Daje::Plugin::Output::Class
    Daje::Plugin::Perl::Generate::BaseClass
    Daje::Plugin::Perl::Generate::Interface
);

done_testing;

