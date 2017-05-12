use strict;
use warnings;
use inc::Module::Install;

name           'CairoX-Pager';
all_from       'lib/CairoX/Pager.pm';

# Specific dependencies
requires       'Cairo'  => 0;
requires       'File::Spec' => 0;

WriteAll;
