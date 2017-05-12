use strict;
use warnings;

use inc::Module::Install;

name     'Class-AutoGenerate';
all_from 'lib/Class/AutoGenerate.pm';

# Code hooks look to be a 5.8 feature... all 5.6.2 perl's fail tests. I looked
# through the changelog for Perl, but couldn't get confirmation of this fact.
# Require hooks are not documented 5.6.2, but are in 5.8.0. That's the best
# evidence I've got right now.
perl_version '5.008';

WriteAll;
