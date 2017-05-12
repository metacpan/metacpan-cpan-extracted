#!/usr/bin/perl

# This script attempts to reproduce:
# http://rt.cpan.org/Public/Bug/Display.html?id=51445
#
# #51445: 2.52 CRLF-ini with multi-value params fails under Linux

use Test::More tests => 20;

use strict;
use warnings;

use Config::IniFiles;

use File::Spec;

my $ini_filename =
    File::Spec->catfile(
        File::Spec->curdir(), "t", 'test25.ini'
    );

{

    # being pedantic, we don't take line breaks from this or an external file for granted
    my $sample_ini =
    "<eol>
    <sol># this is a sample file for testing the proper detection of line endings in Config::IniFiles<eol>
    <sol><eol>
    <sol>[single values]<eol>
    <sol>firstval = first value<eol>
    <sol>secondval=2nd<eol>
    <sol><eol>
    <sol># in v2.52 on linux multi values with crlf lines are failing<eol>
    <sol>[multi value]<eol>
    <sol>Paths=<<EOT<eol>
    <sol>path1<eol>
    <sol>path2<eol>
    <sol>EOT<eol>
    <sol><eol>
    <sol>";

    foreach my $lf (("\x0d\x0a", "\x0d", "\x0a", "\x15", "\n")) {
        my $ini = $sample_ini;
        $ini =~ s/<eol>[^<]*<sol>/$lf/g;

        open my $INI, '>', $ini_filename or die $!;
        binmode $INI;
        print $INI $ini;
        close $INI;

        my $lf_print = join('', map {sprintf '\x%0.2x', ord $_} split(//, $lf));

        my $cfg = Config::IniFiles->new(-file => $ini_filename);

        # TEST
        ok($cfg, "Loading from a '$lf_print'-separated file");

        # TEST
        my $value = $cfg->val('single values', 'firstval');
        is (
            $value, 'first value',
            "Reading a single value from a '$lf_print'-separated file"
        );

        # TEST
        $value = $cfg->val('single values', 'secondval');
        is (
            $value, '2nd',
            "Reading a single value from a '$lf_print'-separated file"
        );

        my @vals = $cfg->val("multi value", "Paths");

        # TEST
        is_deeply(
            \@vals,
            ['path1', 'path2'],
            "Reading a multiple value from a '$lf_print'-separated file",
        );

    }

}

unlink ($ini_filename);
