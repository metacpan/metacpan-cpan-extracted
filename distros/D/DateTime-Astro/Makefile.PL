use inc::Module::Install;

name 'DateTime-Astro';
all_from 'lib/DateTime/Astro.pm';
license 'artistic_2';

use_ppport;
requires 'DateTime';
requires 'DateTime::Set';
requires 'Exporter' => '5.57';

# cc_assert_lib lib => 'mpfr';
use_xshelper;
cc_warnings;
cc_libs 'mpfr';
cc_src_paths 'xs';
author_tests 'xt';
auto_set_repository;

WriteAll;