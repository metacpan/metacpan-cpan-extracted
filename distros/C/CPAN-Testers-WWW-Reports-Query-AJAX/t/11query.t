#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use CPAN::Testers::WWW::Reports::Query::AJAX;
use Test::More;

plan skip_all => "Release tests not required for installation"
    unless ( $ENV{RELEASE_TESTING} );

plan tests => 102;

# various argument sets for examples

my @args = (
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'csv'
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320988,
            pc_fail     => 0.8230452675,
            pc_na       => 0,
            pc_unknown  => 0.4115226337
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'xml'
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320988,
            pc_fail     => 0.8230452675,
            pc_na       => 0,
            pc_unknown  => 0.4115226337
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'html'
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            # default format = xml
        },
        results => {
            all         => 243,
            pass        => 240,
            fail        => 2,
            na          => 0,
            unknown     => 1,
            pc_pass     => 98.7654320988,
            pc_fail     => 0.8230452675,
            pc_na       => 0,
            pc_unknown  => 0.4115226337
        }
    },
    {   args => { 
            dist    => 'CPAN-WWW-Testers',
            format  => 'csv'
        },
        results => {
            all         => 214,
            pass        => 213,
            fail        => 0,
            na          => 0,
            unknown     => 1,
            pc_pass     => 99.5327102804,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0.4672897196
        }
    },
    {   args => { 
            dist    => 'CPAN-WWW-Testers',
            format  => 'xml'
        },
        results => {
            all         => 214,
            pass        => 213,
            fail        => 0,
            na          => 0,
            unknown     => 1,
            pc_pass     => 99.5327102804,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0.4672897196
        }
    },
    {   args => { 
            dist    => 'CPAN-WWW-Testers',
            format  => 'html'
        }
    },
    {   args => { 
            dist    => 'CPAN-WWW-Testers',
            # default format = xml
        },
        results => {
            all         => 214,
            pass        => 213,
            fail        => 0,
            na          => 0,
            unknown     => 1,
            pc_pass     => 99.5327102804,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0.4672897196
        }
    }
);

SKIP: {
    skip "Network unavailable", 102 if(pingtest());

    for my $args (@args) {

        my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new( %{$args->{args}} );
        ok($query,"got response: $args->{args}{dist}" . ($args->{args}{version} ? "-$args->{args}{version}" : '') );

        my $raw  = $query->raw();
        my $data = $query->data();

        #diag( join(', ', map {"$_ => $args->{args}{$_}"} keys %{$args->{args}} ) );
        #diag( "raw=$raw" );

        is($query->is_success,  1,  '.. returned successfully');
        is($query->error,       '', '.. no errors');
        
        if($args->{results}) {
            is($query->all,         $args->{results}{all},          '.. counted all reports');
            is($query->pass,        $args->{results}{pass},         '.. counted pass reports');
            is($query->fail,        $args->{results}{fail},         '.. counted fail reports');
            is($query->na,          $args->{results}{na},           '.. counted na reports');
            is($query->unknown,     $args->{results}{unknown},      '.. counted unknown reports');

            is($query->pc_pass,     $args->{results}{pc_pass},      '.. percentage pass reports');
            is($query->pc_fail,     $args->{results}{pc_fail},      '.. percentage fail reports');
            is($query->pc_na,       $args->{results}{pc_na},        '.. percentage na reports');
            is($query->pc_unknown,  $args->{results}{pc_unknown},   '.. percentage unknown reports');
        }

        if($raw) {
            my $version = $args->{args}{version} || '0.50';
            my $distro  = $args->{args}{dist} || '';

            if($args->{args}{format} && $args->{args}{format} eq 'html') {
                is($query->{options}{format},$args->{args}{format},'.. format the same: html');
                like($raw,qr{<td><a href=(\\)?"javascript:selectReports\('$distro-$version'\);(\\)?">$version</a></td>},'.. got version statement in raw');
                ok(1,".. we don't parse html format");
            } elsif($args->{args}{format} && $args->{args}{format} eq 'csv') {
                is($query->{options}{format},$args->{args}{format},'.. format the same: csv');
                like($raw,qr{$version,\d+},'.. got version statement in raw');
                ok($data->{$version},'.. got version in hash');
            } else { # xml
                is($query->{options}{format},'xml','.. default format: xml');
                like($raw,qr{<version all=(\\"\d+\\"|"\d+").*?>$version</version>},'.. got version statement in raw');
                ok($data->{$version},'.. got version in hash');
            }
        } else {
            diag($query->error());
            ok($query->error());
            ok(1,'..skipped, request did not succeed');
        }
    }
}

# crude, but it'll hopefully do ;)
sub pingtest {
    return 1    unless($ENV{RELEASE_TESTING});

    my $domain = 'www.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
