#!perl -T
#
# Original author: Jonathan Landis <jlandis@akamai.com>
#
# for more info visit https://developer.akamai.com
#

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use JSON;
use Cwd 'abs_path';
use Akamai::Edgegrid;
use HTTP::Request;
use HTTP::Headers;
use URI;
use Data::Dumper;

sub load_testdata {
    my $json_input;
    {
        local ($/, *FH);
        open FH, abs_path($0 .'/../testdata.json') or die "can't open testdata.json";
        $json_input = <FH>;
    }
    return from_json($json_input);
}

sub run_test {
    my ($testdata, $testcase) = @_;
    note("running test: ". $testcase->{testName});
    my $ua = new Akamai::Edgegrid(
        client_token => $testdata->{client_token},
        client_secret => $testdata->{client_secret},
        access_token => $testdata->{access_token},
        headers_to_sign => $testdata->{headers_to_sign},
        max_body => $testdata->{max_body}
    );

    my $uri = new URI($testdata->{base_url});
    $uri->path_query($testcase->{request}->{path});

    my $headers = new HTTP::Headers;
    if (exists $testcase->{request}->{headers}) {
        for my $h (@{$testcase->{request}->{headers}}) {
            while (my ($k,$v) = each %$h) {
                $headers->header($k => $v);
            }
        }
    }

    my $request = new HTTP::Request(
        $testcase->{request}->{method},
        $uri,
        $headers,
        $testcase->{request}->{data}
    );

    my $auth_header = eval {
        return $ua->_make_auth_header(
            $request, $testdata->{timestamp}, $testdata->{nonce}
        );
    };
    if ($@) {
        my $msg = $@;
        chomp($msg);
        note("_make_auth_header died: $msg");
        is($msg, $testcase->{'failsWithMessage'}, $testcase->{testName});
        return;
    }

    is($auth_header, $testcase->{expectedAuthorization}, $testcase->{testName})
}

my $testdata = load_testdata;
my $numtests = scalar @{$testdata->{tests}};

plan tests => $numtests;

for my $test (@{$testdata->{tests}}) {
    run_test($testdata, $test);
}

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Akamai Technologies, Inc. All rights reserved

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


=cut
