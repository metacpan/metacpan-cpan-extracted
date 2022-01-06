#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Scalar::Util qw(tainted);

use CPANPLUS::Dist::Debora::Util qw(
    parse_version
    module_is_distributed_with_perl
    slurp_utf8
    spew_utf8
    can_run
    run
    unix_path
    filetype
);

use Test::More;

if (tainted($ENV{PWD})) {
    plan skip_all => 'taint mode enabled';
}
else {
    plan tests => 10;
}

my $tempdir = tempdir(CLEANUP => 1);

my $version = parse_version('2.32');
isa_ok $version, 'version';
ok module_is_distributed_with_perl('Module::CoreList', $version),
    'Module::CoreList is distributed with Perl';

my $filename = catfile($tempdir, 'motorhead.txt');
ok spew_utf8($filename, 'Motörhead'), 'can write text to UTF-8 encoded file';
is slurp_utf8($filename), 'Motörhead', 'can read text from UTF-8 encoded file';

is filetype("Makefile.PL"), 'script', 'Makefile.PL is a script';

SKIP:
{
    skip 'these tests are for release candidate testing', 5
        if !$ENV{RELEASE_TESTING};

    my $perl = can_run('perl');
    skip 'perl interpreter not found', 5 if !$perl;

    like filetype($perl), qr{executable|script}xms, 'perl is an executable';

    my $output = q{};
    ok run(command => [$perl, '-v'], dir => $tempdir, buffer => \$output),
        'can run program';
    isnt $output, q{}, 'program output is not empty';

    my $has_failed = 0;
    run(command => [$perl, '-e', 'die'], on_error => sub { $has_failed = 1 });
    ok $has_failed, 'on_error is called';

    like unix_path($ENV{PWD}), qr{/}xms, 'path has forward slashes';
}
