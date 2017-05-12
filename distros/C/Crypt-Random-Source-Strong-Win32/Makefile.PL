use strict;
use inc::Module::Install;

all_from 'lib/Crypt/Random/Source/Strong/Win32.pm';

test_requires 'Test::use::ok' => 0;
test_requires 'Test::Exception' => 0;

requires 'Any::Moose' => 0.11;
# 0.06 was where C::R::S started using Any::Moose.
requires 'Crypt::Random::Source' => '0.06';
# 0.55 fixes a bug with char* that might affect us.
requires 'Win32::API' => 0.55;
# 0.35 fixes a memory leak in GetOSVersion, which we use.
requires 'Win32' => 0.35;

makemaker_args(
    dist => { PREOP => 'pod2text lib/Crypt/Random/Source/Strong/Win32.pm > README' },
);

WriteAll;
