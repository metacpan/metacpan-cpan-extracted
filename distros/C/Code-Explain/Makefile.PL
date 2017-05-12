use 5.008008;
use strict;
use inc::Module::Install 0.94;

# Workaround for the fact that Module::Install loads the modules
# into memory and when Test::NoWarnings is loaded it will hide
# the warnings generated from that point.
eval {
	require Test::NoWarnings;
	$SIG{__WARN__} = 'DEFAULT';
};

#####################################################################
# Normal Boring Commands

# NOTE: Core modules that aren't dual-life should always have a version of 0

name 'Code-Explain';
license 'perl';
author 'Gabor Szabo';
all_from 'lib/Code/Explain.pm';

requires 'perl'                    => '5.008008';

requires 'Pod::Usage';
requires 'PPI'                     => '1.213';

test_requires 'Test::More'         => '0.88';
test_requires 'Test::Deep'         => '0.01';
test_requires 'Test::NoWarnings'   => '0.084';

no_index 'directory' => qw{ t xt eg share inc privinc };

install_script 'script/explain-code';

homepage 'http://code.szabgab.com/';
#bugtracker '';
repository 'http://github.com/szabgab/Code-Explain';

WriteAll;
