#!/usr/bin/perl -w

use strict;
use Module::Build;

my $builder = Module::Build->new(
    module_name        => 'CGI::Safe',
    license            => 'perl',
    dist_author        => 'Curtis "Ovid" Poe <moc.oohay@eop_divo_sitruc>',
    dist_version_from  => 'lib/CGI/Safe.pm',
    requires           => { CGI => 2.20 },
    add_to_cleanup     => ['CGI-Safe-*'],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
