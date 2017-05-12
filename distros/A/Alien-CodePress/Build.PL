# $Id$
# $Source$
# $Author$
# $HeadURL$
# $Revision$
# $Date$
use strict;
use warnings;

use FindBin qw($Bin);
use File::Spec;
use lib File::Spec->catdir($Bin, 'inc');
use Module::Build::Alien::CodePress;

sub YES { 1 };
sub NO  { 0 };

my $builder = Module::Build::Alien::CodePress->new({
    module_name         => 'Alien::CodePress',
    license             => 'perl',
    dist_author         => 'Ask Solem <asksh@cpan.org>',
    all_from            => 'lib/Alien/CodePress.pm',
    create_makefile_pl  => 'passthrough',
    create_readme       => YES,
    dynamic_config      => YES,
    requires            => {
        perl                => '5.6.1',
        'Module::Build'     => 0,
        'Archive::Extract'  => 0,
    },
    build_requires      => {
        'Test::Exception'   => 0,
    },
    sign                 => NO, # asksh: have to find out why my signature fails.
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
});

$builder->create_build_script();

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 78
# End:
# vim: expandtab tabstop=4 shiftwidth=4 shiftround
