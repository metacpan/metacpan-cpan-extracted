use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name     'CrawlerCommons-RobotRulesParser';
all_from 'lib/CrawlerCommons/RobotRulesParser.pm';
author   q{Adam K Robinson <akrobinson74@gmail.com>};
license  'artistic2';

perl_version 5.010_001;

tests_recursive('t');

resources (
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   repository => 'git@github.com:akrobinson74/crawlercommons-robotrulesparser.git',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=CrawlerCommons-RobotRulesParser',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   'Const::Fast'            => 0.014,
   'Encode'                 => 2.80,
   'Moose'                  => 2.1804,
   'MooseX::ClassAttribute' => 0.29,
   'MooseX::Enumeration'    => 0.005,
   'MooseX::Log::Log4perl'  => 0.47,
   'namespace::autoclean'   => 0.28,
   'Try::Tiny'              => 0.24,
   'Types::Standard'        => 1.000005,
   'URI'                    => 1.71,
   'URI::Escape'            => 3.31,
);

test_requires (
   'Const::Fast'            => 0.014,
   'Log::Log4perl'          => 1.47,
   'Path::Tiny'             => 0.094,
   'Test::Most'             => 0.34,
   'Try::Tiny'              => 0.24,
);

install_as_cpan;
auto_install;
WriteAll;
