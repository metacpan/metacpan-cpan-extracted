#!perl -T
#
# Original author: Jonathan Landis <jlandis@akamai.com>
# Adopted for Akamai::Open client by Martin Probst <internet+cpan@megamaddin.org>
#

use Test::More;

BEGIN {
    use_ok('Akamai::Open::Request::EdgeGridV1');
    use_ok('Akamai::Open::Client');
    use_ok('URI');
}
require_ok('Akamai::Open::Request::EdgeGridV1');
require_ok('Akamai::Open::Client');
require_ok('URI');


use v5.10;
use JSON;
use Cwd 'abs_path';
use URI;

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
    
    my $client = Akamai::Open::Client->new(
        client_token  => $testdata->{client_token},
        client_secret => $testdata->{client_secret},
        access_token  => $testdata->{access_token}
    );

    my $req = Akamai::Open::Request::EdgeGridV1->new(
        client    => $client,
        timestamp => $testdata->{timestamp},
        nonce     => $testdata->{nonce}
    );

    $req->request->method($testcase->{request}->{method});
    $req->request->uri(URI->new($testdata->{base_url}.$testcase->{request}->{path}));

    if(exists($testcase->{request}->{headers})) {
        my %headers;
        for my $h (@{$testcase->{request}->{headers}}) {
            while (my ($k,$v) = each %$h) {
                $headers{$k} = $v if(grep(/$k/, @{$testdata->{headers_to_sign}}));
            }
        }
        $req->signed_headers(\%headers);
    }

    if(exists($testcase->{request}->{data})) {
        $req->request->content($testcase->{request}->{data});
    }

    my $auth_header = eval {
        $req->sign_request;
        return($req->request->headers->header('authorization'));
    };

    if ($@) {
        my $msg = $@;
        chomp($msg);
        note("The signing process died: $msg");
        is($msg, $testcase->{'failsWithMessage'}, $testcase->{testName});
        return;
    }

    is($auth_header, $testcase->{expectedAuthorization}, $testcase->{testName})
}

my $testdata = load_testdata;
my $numtests = scalar @{$testdata->{tests}};

for my $test (@{$testdata->{tests}}) {
    run_test($testdata, $test);
}

done_testing;

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


