# $Id$

use Config;
BEGIN {
    warn "A 64-bit Perl is highly recommended"
        unless $Config{use64bitint};
}

use inc::Module::Install;

name('Data-YUID');
abstract('Distributed unique ID allocator');
author('Six Apart <cpan@sixapart.com>');
all_from('lib/Data/YUID.pm');
license('perl');
no_index(directory => 't');
sign(0);

include('ExtUtils::AutoInstall');

requires('Danga::Socket');
requires('URI::Escape');
test_requires('Time::HiRes');
unless ($Config{use64bitint}) {
    requires('Math::BigInt');
}

install_script('bin/yuidd');

githubmeta;

auto_include();
auto_install();

WriteAll;
