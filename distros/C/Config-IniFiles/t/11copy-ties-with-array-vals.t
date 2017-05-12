#!/usr/bin/perl

use Test::More tests => 1;

use strict;
use warnings;

use File::Spec;

use Config::IniFiles;

{
    tie my %ini, 'Config::IniFiles',
        (-file => File::Spec->catfile('t', 'array.ini'))
        ;

    my %new_sect;

    %new_sect = %{$ini{Sect}};

    $new_sect{Par}[1] = 'A';

    # TEST
    is_deeply ($ini{Sect}{Par}, [1,2,3], '%ini was not modified');
}
