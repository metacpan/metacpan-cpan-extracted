#!/usr/bin/perl

use strict;
use warnings;
use Test::Most;

use App::Prove::Plugin::TraceUse;

my $some_code = <<'EOC';
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'App::Prove::Plugin::TraceUse',
    AUTHOR              => 'Torbjørn Lindahl <torbjorn.lindahl@diagenic.com>',
    VERSION_FROM        => 'lib/App/Prove/Plugin/TraceUse.pm',
    ABSTRACT_FROM       => 'lib/App/Prove/Plugin/TraceUse.pm',
    PL_FILES            => {},
    PREREQ_PM => {
                  'Test::More' => 0,
                  'version'    => 0,
                  'App::Prove' => '3.15',
#                  'Test::Perl::Critic'  => '1.02',
#Test::Pod::Coverage' => '1.08',
                 # 'Test::Most'          => '0.25',
                  #'Set::Object'         => '1.26',
                  'Test::Pod'           => '1.45',
                  'File::Slurp'         => '9999.19',
                  Tree::Simple        => '1.18',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'App-Prove-Plugin-TraceUse-*' },
);
EOC

ok( App::Prove::Plugin::TraceUse::_find_module_in_code("Test::More", $some_code), "Found Test::More in sample code");
ok( App::Prove::Plugin::TraceUse::_find_module_in_code("Tree::Simple", $some_code), "Found Tree::Simple in sample code");

ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Perl::Critic", $some_code),
    "Didn't find commented Test::Perl::Critic in sample code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Pod::Coverage", $some_code),
    "Didn't find commented Test::Pod::Coverage in sample code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Most", $some_code),
    "Didn't find commented Test::Most in sample code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Set::Object", $some_code),
    "Didn't find commented Set::Object in sample code");

my $other_code = <<'EOC2';
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Prove::Plugin::TraceUse',
    license             => 'perl',
    dist_author         => 'Torbjørn Lindahl <torbjorn.lindahl@diagenic.com>',
    dist_version_from   => 'lib/App/Prove/Plugin/TraceUse.pm',
    requires => {
                 'Test::More' => 0,
                 'version'    => 0,
                 'App::Prove' => '3.15',
#                 'Test::Perl::Critic'  => '1.02',
#Test::Pod::Coverage => '1.08',
                # 'Test::Most'          => '0.25',
                 #'Set::Object'         => '1.26',
                 'Test::Pod'           => '1.45',
                 'File::Slurp'         => '9999.19',
                 Tree::Simple        => '1.18',
    },
    add_to_cleanup      => [ 'App-Prove-Plugin-TraceUse-*' ],
);

$builder->create_build_script();

EOC2

ok( App::Prove::Plugin::TraceUse::_find_module_in_code("Test::More", $other_code), "Found Test::More in other code");
ok( App::Prove::Plugin::TraceUse::_find_module_in_code("Tree::Simple", $other_code), "Found Tree::Simple in other code");

ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Perl::Critic", $other_code),
    "Didn't find commented Test::Perl::Critic in other code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Pod::Coverage", $other_code),
    "Didn't find commented Test::Pod::Coverage in other code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Test::Most", $other_code),
    "Didn't find commented Test::Most in other code");
ok( !App::Prove::Plugin::TraceUse::_find_module_in_code("Set::Object", $other_code),
    "Didn't find commented Set::Object in other code");


done_testing();
