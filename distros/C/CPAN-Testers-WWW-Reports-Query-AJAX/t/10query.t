#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 118;

use CPAN::Testers::WWW::Reports::Query::AJAX;

#----------------------------------------------------------------------------
# Test Data

my ($RAW,$nomock,$mock1);

my @args = (
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            format  => 'csv'
        },
        raw => q{0.15,243,240,2,0,1},
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
        raw => q{<versions><version all="243" pass="240" fail="2" na="0" unknown="1">0.15</version> </versions>},
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
        },
        raw => q{<OT><body onLoad="parent.OpenThought.ResponseComplete(self)"></body><script>parent.OpenThought.ServerResponse({"reportsummary": "<h3>Version Summary:</h3> <table> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.15');\">0.15</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"79.0123456790123\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/yellow.png\" width=\"0.329218106995885\" height=\"16\" alt=\"UNKNOWN\" /><img src=\"/images/layout/red.png\" width=\"0.65843621399177\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> </table> "});</script><OT>}
    },
    {   args => { 
            dist    => 'App-Maisha',
            version => '0.15',  # optional, will default to latest version
            # default format = xml
        },
        raw => q{<versions><version all="243" pass="240" fail="2" na="0" unknown="1">0.15</version> </versions>},
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
            format  => 'csv'
        },
        raw => q{0.18,139,139,0,0,0
0.17,123,123,0,0,0
0.16,113,113,0,0,0
0.15,243,240,2,0,1
0.14,56,56,0,0,0
0.13,96,96,0,0,0
0.12,106,103,3,0,0
0.11,38,38,0,0,0
0.10,36,36,0,0,0
0.09,23,23,0,0,0
0.08,26,26,0,0,0
0.07,23,23,0,0,0
0.06,35,15,20,0,0
0.05,29,4,25,0,0
0.04,39,11,28,0,0
0.03,32,6,26,0,0
0.02,33,4,29,0,0
0.01,39,3,36,0,0},
        results => {
            all         => 139,
            pass        => 139,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'xml'
        },
        raw => q{<versions>
<version all="139" pass="139" fail="0" na="0" unknown="0">0.18</version>
<version all="123" pass="123" fail="0" na="0" unknown="0">0.17</version>
<version all="113" pass="113" fail="0" na="0" unknown="0">0.16</version>
<version all="243" pass="240" fail="2" na="0" unknown="1">0.15</version>
<version all="56" pass="56" fail="0" na="0" unknown="0">0.14</version>
<version all="96" pass="96" fail="0" na="0" unknown="0">0.13</version>
<version all="106" pass="103" fail="3" na="0" unknown="0">0.12</version>
<version all="38" pass="38" fail="0" na="0" unknown="0">0.11</version>
<version all="36" pass="36" fail="0" na="0" unknown="0">0.10</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.09</version>
<version all="26" pass="26" fail="0" na="0" unknown="0">0.08</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.07</version>
<version all="35" pass="15" fail="20" na="0" unknown="0">0.06</version>
<version all="29" pass="4" fail="25" na="0" unknown="0">0.05</version>
<version all="39" pass="11" fail="28" na="0" unknown="0">0.04</version>
<version all="32" pass="6" fail="26" na="0" unknown="0">0.03</version>
<version all="33" pass="4" fail="29" na="0" unknown="0">0.02</version>
<version all="39" pass="3" fail="36" na="0" unknown="0">0.01</version> </versions>},
        results => {
            all         => 139,
            pass        => 139,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'html'
        },
        raw => q{<OT><body onLoad="parent.OpenThought.ResponseComplete(self)"></body><script>parent.OpenThought.ServerResponse({"reportsummary": "<h3>Version Summary:</h3> <table> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.18');\">0.18</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.17');\">0.17</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.16');\">0.16</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.15');\">0.15</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"79.0123456790123\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/yellow.png\" width=\"0.329218106995885\" height=\"16\" alt=\"UNKNOWN\" /><img src=\"/images/layout/red.png\" width=\"0.65843621399177\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.14');\">0.14</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.13');\">0.13</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.12');\">0.12</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"77.7358490566038\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"2.26415094339623\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.11');\">0.11</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.10');\">0.10</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.09');\">0.09</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.08');\">0.08</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.07');\">0.07</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"80\" height=\"16\" alt=\"PASS\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.06');\">0.06</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"34.2857142857143\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"45.7142857142857\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.05');\">0.05</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"11.0344827586207\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"68.9655172413793\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.04');\">0.04</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"22.5641025641026\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"57.4358974358974\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.03');\">0.03</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"15\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"65\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.02');\">0.02</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"9.6969696969697\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"70.3030303030303\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> <tr>\n<td><a href=\"javascript:selectReports('App-Maisha-0.01');\">0.01</a></td>\n<td><img src=\"/images/layout/green.png\" width=\"6.15384615384615\" height=\"16\" alt=\"PASS\" /><img src=\"/images/layout/red.png\" width=\"73.8461538461538\" height=\"16\" alt=\"FAIL\" />\n</td>\n</tr> </table> "});</script><OT>}
    },
    {   args => { 
            dist    => 'App-Maisha',
            # default format = xml
        },
        raw => q{<versions>
<version all="139" pass="139" fail="0" na="0" unknown="0">0.18</version>
<version all="123" pass="123" fail="0" na="0" unknown="0">0.17</version>
<version all="113" pass="113" fail="0" na="0" unknown="0">0.16</version>
<version all="243" pass="240" fail="2" na="0" unknown="1">0.15</version>
<version all="56" pass="56" fail="0" na="0" unknown="0">0.14</version>
<version all="96" pass="96" fail="0" na="0" unknown="0">0.13</version>
<version all="106" pass="103" fail="3" na="0" unknown="0">0.12</version>
<version all="38" pass="38" fail="0" na="0" unknown="0">0.11</version>
<version all="36" pass="36" fail="0" na="0" unknown="0">0.10</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.09</version>
<version all="26" pass="26" fail="0" na="0" unknown="0">0.08</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.07</version>
<version all="35" pass="15" fail="20" na="0" unknown="0">0.06</version>
<version all="29" pass="4" fail="25" na="0" unknown="0">0.05</version>
<version all="39" pass="11" fail="28" na="0" unknown="0">0.04</version>
<version all="32" pass="6" fail="26" na="0" unknown="0">0.03</version>
<version all="33" pass="4" fail="29" na="0" unknown="0">0.02</version>
<version all="39" pass="3" fail="36" na="0" unknown="0">0.01</version> </versions>},
        results => {
            all         => 139,
            pass        => 139,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    },
    {   args => { 
            dist    => 'App-Maisha',
            format  => 'blah'
        },
        raw => q{<versions>
<version all="139" pass="139" fail="0" na="0" unknown="0">0.18</version>
<version all="123" pass="123" fail="0" na="0" unknown="0">0.17</version>
<version all="113" pass="113" fail="0" na="0" unknown="0">0.16</version>
<version all="243" pass="240" fail="2" na="0" unknown="1">0.15</version>
<version all="56" pass="56" fail="0" na="0" unknown="0">0.14</version>
<version all="96" pass="96" fail="0" na="0" unknown="0">0.13</version>
<version all="106" pass="103" fail="3" na="0" unknown="0">0.12</version>
<version all="38" pass="38" fail="0" na="0" unknown="0">0.11</version>
<version all="36" pass="36" fail="0" na="0" unknown="0">0.10</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.09</version>
<version all="26" pass="26" fail="0" na="0" unknown="0">0.08</version>
<version all="23" pass="23" fail="0" na="0" unknown="0">0.07</version>
<version all="35" pass="15" fail="20" na="0" unknown="0">0.06</version>
<version all="29" pass="4" fail="25" na="0" unknown="0">0.05</version>
<version all="39" pass="11" fail="28" na="0" unknown="0">0.04</version>
<version all="32" pass="6" fail="26" na="0" unknown="0">0.03</version>
<version all="33" pass="4" fail="29" na="0" unknown="0">0.02</version>
<version all="39" pass="3" fail="36" na="0" unknown="0">0.01</version> </versions>},
        results => {
            all         => 139,
            pass        => 139,
            fail        => 0,
            na          => 0,
            unknown     => 0,
            pc_pass     => 100,
            pc_fail     => 0,
            pc_na       => 0,
            pc_unknown  => 0
        }
    }
);

#----------------------------------------------------------------------------
# Test Conditions

BEGIN {
    eval "use Test::MockObject";
    $nomock = $@;

    unless($nomock) {
        $mock1 = Test::MockObject->new();
        $mock1->fake_module( 'WWW::Mechanize',
                    'agent_alias'   =>  \&fake_alias,
                    'get'           =>  \&fake_get,
                    'success'       =>  \&fake_success,
                    'content'       =>  \&fake_content  );
        $mock1->fake_new( 'WWW::Mechanize' );
        $mock1->mock( 'agent_alias',    \&fake_alias    );
        $mock1->mock( 'get',            \&fake_get      );
        $mock1->mock( 'success',        \&fake_success  );
        $mock1->mock( 'content',        \&fake_content  );
    }
}

#----------------------------------------------------------------------------
# Test Main

SKIP: {
    skip "Test::MockObject required for testing", 118 if $nomock;

    my $query = CPAN::Testers::WWW::Reports::Query::AJAX->new();
    is($query,undef,"no args, no object" );

    for my $args (@args) {

        $RAW = $args->{raw};

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
            my $version = $args->{args}{version} || '0.15';

            if($args->{args}{format} && $args->{args}{format} eq 'html') {
                is($query->{options}{format},$args->{args}{format},'.. format the same: html');
                like($raw,qr{<td><a href=(\\)?"javascript:selectReports\('App-Maisha-$version'\);(\\)?">$version</a></td>},'.. got version statement in raw');
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
    my $domain = 'www.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}

sub fake_alias      {}
sub fake_get        {}
sub fake_success    { return 1; }
sub fake_content    { return $RAW; }
