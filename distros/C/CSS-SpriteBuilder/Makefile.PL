# Makefile.PL for CSS::SpriteBuilder.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# Copyright 2013 Yuriy Ustushenko, all rights reserved.

use 5.008008;
use warnings;
use strict;
use ExtUtils::MakeMaker;

our @MODULES = qw( GD Image::Magick );

my $isOK = 0;
print "This module requires at least one of: ", join(", ", @MODULES), "...\n";
foreach (@MODULES){
    print "Looking for $_ ... ";
    eval "require "."$_";
    if ($@) {
        print "not found\n";
    }
    else {
        print "ok\n";
        $isOK = 1;
        last;
    }
}

our @REQUIRED;
unless ($isOK) {
    print <<EOF;

This module requires you have installed on your system
one of either the Image::Magick or GD Perl modules.

It appears you have none of these.
EOF
    push @REQUIRED, $MODULES[0] => 0;
}

WriteMakefile(
    NAME             => 'CSS::SpriteBuilder',
    VERSION_FROM     => 'lib/CSS/SpriteBuilder.pm',
    ABSTRACT_FROM    => 'lib/CSS/SpriteBuilder.pm',
    AUTHOR           => 'Yuriy Ustushenko <yoreek@yahoo.com>',
    LICENSE          => "perl",
    MIN_PERL_VERSION => 5.008008,
    PREREQ_PM     => {
        'File::Spec'   => 0,
        'File::Glob'   => 0,
        'Cwd'          => 0,
        'Scalar::Util' => 0,
        'Test::More'   => 0,
        @REQUIRED,
    },
);
