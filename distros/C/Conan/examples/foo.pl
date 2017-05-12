#!/usr/bin/perl
use strict;
use lib 'lib';

use Conan::Configure::Xen;

my $config = Conan::Configure::Xen->new(
        basedir => './examples',
        name => 'foo01',
        settings => {
                ip => '1.2.3.5',
        },
);
 
$config->parse();
 
print $config->generate();
