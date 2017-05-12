#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'     => 'CTK::XS::Util',
    'C'        => [ 'Util.c' ],
    'XS'       => { 'Util.xs' => 'Util.c' },
    'OBJECT'   => 'Util.o',
    'VERSION'  => '1.00',
    'NORECURS' => 1,
);

