#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

use CPANPLUS::Backend;
use CPANPLUS::Config;

use Test::More;

if (!$ENV{RELEASE_TESTING}) {
    plan skip_all => 'these tests are for release candidate testing';
}
elsif ($ENV{NO_NETWORK_TESTING}) {
    plan skip_all => 'no network testing';
}
elsif (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 4;
}

my $tempdir = tempdir(CLEANUP => 1);

local $ENV{BUILD}               = 1;
local $ENV{DEBFULLNAME}         = 'Test';
local $ENV{DEBEMAIL}            = 'test@example.com';
local $ENV{HOME}                = $tempdir;
local $ENV{INSTALLDIRS}         = 'vendor';
local $ENV{DEVEL_COVER_OPTIONS} = '+ignore,File/Next';

my $config = CPANPLUS::Configure->new;
$config->set_conf(allow_build_interactivity => 0);
$config->set_conf(base                      => $tempdir);
$config->set_conf(dist_type                 => 'CPANPLUS::Dist::Debora');
$config->set_conf(flush                     => 0);
$config->set_conf(verbose                   => 0);

my $mirror = $ENV{CPAN_MIRROR};
if (defined $mirror && $mirror =~ m{\A ([^:]+):// ([^/]+) (.*)}xms) {
    my $hosts = [{scheme => $1, host => $2, path => $3}];
    $config->set_conf(hosts => $hosts);
}

my $backend = CPANPLUS::Backend->new($config);

my $module = $backend->parse_module(module => 'File::Next');

isa_ok $module, 'CPANPLUS::Module';
ok $module->prepare, 'can prepare module';
ok $module->create,  'can create module';
ok $module->install, 'can install module';
