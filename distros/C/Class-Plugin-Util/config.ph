# $Id: config.ph,v 1.2 2007/05/24 19:01:57 ask Exp $
# $Source: /opt/CVS/classpluginutil/config.ph,v $
# $Author: ask $
# $HeadURL$
# $Revision: 1.2 $
# $Date: 2007/05/24 19:01:57 $
module_name          => 'Class::Plugin::Util',
license              => 'perl',
dist_author          => 'Ask Solem <ASKSH@cpan.org>',
all_from             => 'lib/Class/Plugin/Util.pm',
dynamic_config       => NO,
sign                 => NO, # asksh: have to find out why my signature fails.
recursive_test_files => YES,
create_makefile_pl   => 'traditional',
requires             => {
    'Module::Find'      => 0.05,
},
recommends           => {
},
build_requires       => {
    'Test::Simple'            => 0.42,    # 
},
add_to_cleanup       => [ qw(
    a.out
    test.pl
    test.c
    test.cpp
    test.m
    *.swp
    .gdb_history
    install.cache
    t/cache
    cache/
) ],
meta_merge => {
    distribution_type   => 'Module',
},
