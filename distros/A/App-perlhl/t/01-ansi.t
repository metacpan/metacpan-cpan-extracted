use strict;
use warnings;
use open qw(:std :encoding(UTF-8));
use Test::Output qw(stdout_is);
use Test::More tests => 2;
use App::perlhl;

my $expected = do { local $/; <DATA> };

stdout_is(
    sub { App::perlhl->new('ansi')->run('highlight', ('t/testfile')) },
    $expected,
    'ANSI highlighting done right'
);

my $system = `$^X bin/perlhl t/testfile 2>&1`;
is $system, $expected, 'perlhl does the same thing';

__DATA__
[1;90m#!/usr/bin/env perl[0m
[37muse[0m [1;91mstrict[0m[37m;[0m
[37muse[0m [1;91mwarnings[0m[37m;[0m

[37mmy[0m [32m$scalar[0m [37m=[0m [34m'[0m[34mhello[0m[34m'[0m[37m;[0m
[37mmy[0m [32m$newline[0m [37m=[0m [34m"[0m[34m[1;91m\n[0m[0m[34m"[0m[37m;[0m
[37mmy[0m [36m@array[0m [37m=[0m [34mqw([0m[34mone two three[0m[34m)[0m[37m;[0m
[37mmy[0m [32m$string[0m [37m=[0m [34mq{[0m[34mHello, world![0m[34m}[0m[37m;[0m
[37mif[0m [37m([0m[32m$scalar[0m[37m)[0m [37m{[0m
    [37mmy[0m [32m$ver[0m  [37m=[0m [32m$File::Basename::VERSION[0m[37m;[0m
    [37mmy[0m [32m$ver2[0m [37m=[0m [92mFile::Basename[0m[37m->[0m[33mVERSION[0m[37m([0m[37m)[0m[37m;[0m
    [34mprint[0m [37m([0m[32m$ver[0m [37m==[0m [32m$ver2[0m [37m?[0m [34m'[0m[34mok[0m[34m'[0m [37m:[0m [34m'[0m[34mnotok[0m[34m'[0m[37m)[0m[37m;[0m
[37m}[0m
[37mmy[0m [35m%hash[0m [37m=[0m [36m@ARGV[0m [37mif[0m [36m@ARGV[0m [35m%[0m [91m2[0m [37m==[0m [91m0[0m[37m;[0m
[37mwhile[0m [37m([0m[37m<[0m[37m>[0m[37m)[0m [37m{[0m
    [91mprint[0m [37mif[0m [34mm/[0m[34m[1;91m\Q[0m[32m$scalar[0m[1;91m\E[0m|hi[0m[34m/[0m[34mi[0m[37m;[0m
[37m}[0m
[91mclose[0m [91m*STDOUT[0m[37m;[0m

