#!perl

use strict;
use warnings;

use Test2::V1 qw( -utf8 -x );
use Test2::Plugin::BailOnFail;
use English qw( -no_match_vars );
use Path::Tiny qw( path );

T2->ok(path('README.md')->is_file(), 'File README.md exists');

my $got = path('README.md')->slurp_utf8 =~ s/[[:space:]]+$//rmsx;

my (@got_lines, @expected_lines);
foreach (split qr{\R}msx, $got) { push @got_lines, $_; }
do {
    local $INPUT_RECORD_SEPARATOR = undef;
    my $expected = <DATA>;
    $expected =~ s/[[:space:]]+$//msx;
    foreach (split qr{\R}msx, $expected) { push @expected_lines, $_; }
};
T2->is(\@got_lines, \@expected_lines, 'File README.md matches expected content');

T2->done_testing;

__DATA__
[![License: Artistic-2.0](https://img.shields.io/badge/License-Perl-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
[![CPAN Version](https://img.shields.io/cpan/v/Dancer2-Plugin-JobScheduler)](https://metacpan.org/dist/Dancer2-Plugin-JobScheduler)
[![kwalitee](https://cpants.cpanauthors.org/dist/Dancer2-Plugin-JobScheduler.svg)](https://cpants.cpanauthors.org/dist/Dancer2-Plugin-JobScheduler)
[![codecov](https://codecov.io/gh/mikkoi/Dancer2-Plugin-JobScheduler/graph/badge.svg?token=KH15ROS3GZ)](https://codecov.io/gh/mikkoi/Dancer2-Plugin-JobScheduler)
[![Coverage Status](https://coveralls.io/repos/github/mikkoi/Dancer2-Plugin-JobScheduler/badge.svg?branch=main)](https://coveralls.io/github/mikkoi/Dancer2-Plugin-JobScheduler?branch=main)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/mikkoi/Dancer2-Plugin-JobScheduler)
[![GH Actions: Linux Build](https://github.com/mikkoi/Dancer2-Plugin-JobScheduler/actions/workflows/linux.yml/badge.svg?event=push&branch=main)](https://github.com/mikkoi/Dancer2-Plugin-JobScheduler/actions/workflows/linux.yml)
[![GH Actions: Windows Build](https://github.com/mikkoi/Dancer2-Plugin-JobScheduler/actions/workflows/windows.yml/badge.svg?event=push&branch=main)](https://github.com/mikkoi/Dancer2-Plugin-JobScheduler/actions/workflows/windows.yml)

# Dancer2-Plugin-JobScheduler

Plugin for Dancer2 web app to send and query jobs in different job schedulers


# VERSION

0.007


# SYNOPSIS

    use Dancer2;
    BEGIN {
        my %plugin_config = (
            default => 'theschwartz',
            schedulers => {
                theschwartz => {
                    client => 'TheSchwartz',
                    parameters => {
                        handle_uniqkey => 'acknowledge',
                        dbh_callback => 'Database::ManagedHandle->instance',
                        databases => {
                            theschwartz_db1 => {
                                prefix => q{schema_name.},
                            },
                        }
                    }
                }
            }
        );
        set log => 'debug';
        set plugins => {
            JobScheduler => \%plugin_config,
        };
    }
    use Dancer2::Plugin::JobScheduler;

    set serializer => 'JSON';

    get q{/submit_job} => sub {
        my %r = submit_job(
            client => 'theschwartz',
            job => {
                task => 'task1',
                args => { name => 'My Name', age => 123 },
                opts => {},
            },
        );
        return to_json(\%r);
    };

    get q{/list_jobs} => sub {
        my %r = list_jobs(
            client => 'theschwartz',
            search_params => {
                task => 'task1',
            },
        );
        return to_json(\%r);
    };


# LICENSE

This software is copyright (c) 2026 by Mikko Koivunalho <mikkoi@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Terms of the Perl programming language system itself:

a) the GNU General Public License as published by the Free
   Software Foundation; either version 1, or (at your option) any
   later version, or
b) the "Artistic License"

The complete licenses are in the files LICENSE-Artistic-2.0 and LICENSE-GPL-3
within this repository. If these files are missing, they can be downloaded
from the following urls:

    * https://www.gnu.org/licenses/
    * https://www.perlfoundation.org/artistic-license-20.html
