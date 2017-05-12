# $Id: Build.PL 4 2007-09-13 10:16:35Z asksol $
# $Source: /opt/CVS/Getopt-LL/Build.PL,v $
# $Author: asksol $
# $HeadURL: https://class-dot-model.googlecode.com/svn/trunk/Build.PL $
# $Revision: 4 $
# $Date: 2007-09-13 12:16:35 +0200 (Thu, 13 Sep 2007) $
use strict;
use warnings;

sub BEGIN {
    use File::Spec;
    use FindBin qw($Bin);
    my $inc = File::Spec->catdir($Bin, 'inc');
    unshift @INC, $inc;
}

use Module::Build::Class::Dot::Model;

# ##########################################################



sub YES { 1 };
sub NO  { 0 };

$ENV{DEVEL_COVER_OPTIONS} = '-ignore,blib/Class/InsideOut/Policy/Modwheel.pm';
my $builder = Module::Build::Class::Dot::Model->new(
    module_name          => 'Class::Dot::Model',
    dist_version        => '0.1.3',
    license              => 'perl',
    dist_author          => 'Ask Solem <ASKSH@cpan.org>',
    all_from             => 'lib/Class/Dot/Model.pm',
    dynamic_config       => NO,
    sign                 => NO, # asksh: have to find out why my signature fails.
    create_makefile_pl   => 'traditional',
    create_readme        => YES,
    recursive_test_files => YES,
    requires             => {
        'version'                               => 0,
        'Getopt::LL'                            => 0,
        'Class::Dot'                            => 0,
        'Class::Plugin::Util'                   => 0,
        'Params::Util'                          => 0,
        'Config::PlConfig'                      => 0,
        'DBIx::Class'                           => 0,
    },
    recommends           => {
        'Test::Exception'       => 0.25,
        'IO::Capture::Stderr'   => 0,
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
);

$builder->create_build_script( );

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
