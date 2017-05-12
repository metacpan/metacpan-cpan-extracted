#! /usr/bin/perl

use strict;
use warnings;
use Browsermob::Server;
use IO::Socket::INET;
use LWP::UserAgent;
use Test::Spec;
use Test::Deep;
use Browsermob::Proxy::CompareParams qw/cmp_request_params
                                        convert_har_params_to_hash
                                        collect_query_param_keys
                                        replace_placeholder_values
                                       /;

describe 'Param comparison' => sub {
    my ($requests, $assert);

    before each => sub {
        $requests = [{
            request => {
                queryString => [{
                    name => 'query',
                    value => 'string'
                }]
            }
        }, {
            request => {
                queryString => [{
                    name => 'query2',
                    value => 'string2'
                }, {
                    name => 'query3',
                    value => 'string3'
                }]
            }
        }];
    };

    it 'should know how to convert har params' => sub {
        my $converted = convert_har_params_to_hash($requests);
        my $expected = [
            {
                query => 'string'
            },
            {
                query2 => 'string2',
                query3 => 'string3'
            },
        ];
        cmp_deeply($converted, $expected);
    };

    it 'should pass on exact matches: all keys, all values' => sub {
        $assert = { query => 'string' };
        ok(cmp_request_params($requests, $assert));

        $assert = {
            query2 => 'string2',
            query3 => 'string3'
        };
        ok(cmp_request_params($requests, $assert));
    };

    it 'should pass on assert in multiple requests' => sub {
        $requests = [{
            request => {
                queryString => [{
                    name => 'both',
                    value => 'reqs'
                }]
            }
        },{
            request => {
                queryString => [{
                    name => 'both',
                    value => 'reqs'
                }]
            }
        }];

        $assert = { both => 'reqs' };
        ok(cmp_request_params($requests, $assert));
    };

    it 'should pass on a subset match: some keys' => sub {
        $assert = { query2 => 'string2' };
        ok(cmp_request_params($requests, $assert));
    };

    it 'should fail on assert missing key' => sub {
        $assert = { missing => 'string' };
        ok( ! cmp_request_params($requests, $assert));
    };

    it 'should fail on assert with incorrect value' => sub {
        $assert = { query => 'incorrect' };
        ok( ! cmp_request_params($requests, $assert));
    };

    it 'should fail on an assert with an extra k/v pair' => sub {
        $assert = {
            query => 'string',
            missing => 'pair'
        };
        ok( ! cmp_request_params($requests, $assert));
    };

    describe 'in list context' => sub {
        before each => sub {
            my $list_context_fixtures = [{
                request => {
                    queryString => [{
                        name => 'query2',
                        value => 'string2'
                    }]
                }
            }, {
                request => {
                    queryString => [{
                        name => 'query',
                        value => 'string'
                    }, {
                        name => 'query2',
                        value => 'string2'
                    }, {
                        name => 'query3',
                        value => 'string3'
                    }]
                }
            }];

            push( @{ $requests }, @{ $list_context_fixtures } );
        };

        it 'should return an empty hashref when succeeding' => sub {
            $assert = { query => 'string' };

            my ($status, $missing) = cmp_request_params($requests, $assert);
            cmp_deeply($missing, { });
        };

        it 'should return a missing key' => sub {
            $assert = {
                query => 'string',
                missing => 'pair'
            };

            my ($status, $missing) = cmp_request_params($requests, $assert);
            cmp_deeply($missing, { missing => 'pair' });
        };

        it 'should return an incorrect value' => sub {
            $assert = { query => 'incorrect' };

            my ($status, $missing) = cmp_request_params($requests, $assert);
            cmp_deeply( $missing, { query => 'incorrect' } );
        };

        it 'should return the closest request' => sub {
            $assert = {
                query2 => 'string2',
                query3 => 'string3',
                missing => 'param'
            };

            my ($status, $missing) = cmp_request_params($requests, $assert);
            cmp_deeply($missing, { missing => 'param' } );

        };

        describe 'actual params' => sub {

            it 'should have key => undef for missing params' => sub {
                $assert = {
                    query2 => 'string2',
                    query3 => 'string3',
                    missing => 'param'
                };

                my ($status, $missing, $actual) = cmp_request_params($requests, $assert);
                cmp_deeply( $actual, { missing => undef } );
            };

            it 'should have key/value for incorrect params' => sub {
                $assert = {
                    query2 => 'wrong',
                    query3 => 'string3'
                };

                my (undef, undef, $actual) = cmp_request_params( $requests, $assert );
                cmp_deeply( $actual, { query2 => 'string2' } );
            };

            it 'should have key/value for anything-but-this keys' => sub {
                $assert = {
                    '!query2' => 'string2',
                    query3 => 'string3'
                };

                my (undef, undef, $actual) = cmp_request_params( $requests, $assert );
                cmp_deeply( $actual, { query2 => 'string2' } );
            };

            it 'should have key/value for disallowed keys' => sub {
                $assert = {
                    '!query' => '',
                    '!query2' => '',
                    '!query3' => ''
                };

                my ($status, $missing, $actual) = cmp_request_params( $requests, $assert );
                cmp_deeply( $actual, { query => 'string' } );
            };


        };


    };

    describe 'custom comparison' => sub {
        my ($regex_cmp);

        before each => sub {
            $regex_cmp = sub {
                my ($string, $regex_contents) = @_;

                return $string =~ /$regex_contents/i;
            };
        };

        it 'should accept a custom comparison subroutine' => sub {
            # shouldn't match, but the custom comparison sub should
            # override the failed string match
            my $cmp = sub { 1 };
            $assert = { query => 'does not match' };
            ok( cmp_request_params($requests, $assert, $cmp) );
        };

        it 'should be able to pass regex comparisons in the custom sub' => sub {
            # the value isn't a string match, but it would be a regex
            # match
            $assert = { query => '.*' };
            ok( cmp_request_params($requests, $assert, $regex_cmp) );
        };

        it 'should work fine with a more complicated assert' => sub {
            $assert = { query2 => '.*', query3 => '3$' };
            ok( cmp_request_params($requests, $assert, $regex_cmp) );
        };

        it 'should fail non-matching regex custom subs' => sub {
            # We can fail in a custom sub as well
            $assert = { query => '.*2$' };
            ok( ! cmp_request_params($requests, $assert, $regex_cmp) );
        };
    };

    describe 'negative assertion' => sub {
        it 'should pass when the key is missing' => sub {
            my $assert = {
                query => 'string',
                '!missing' => ''
            };

            ok( cmp_request_params( $requests, $assert) );
        };

        it 'should pass against any of the requests in the $got' => sub {
            my $other_assert = {
                query2 => 'string2',
                query3 => 'string3',
                '!missing' => '',
                '!missing2' => '',
            };

            ok( cmp_request_params( $requests, $other_assert ) );
        };

        it 'should fail when the key is present' => sub {
            my $single_request = [ shift @$requests ];
            my $assert = {
                '!query' => ''
            };

            ok( ! cmp_request_params( $single_request, $assert) );
        };

        it 'should pass if two requests are present and one of them matches' => sub {
            my $assert = {
                '!query' => ''
            };

            ok( cmp_request_params( $requests, $assert ) );
        };

        it 'should pass on a negative asserts with an incorrect value' => sub {
            my $single_request = [ shift @$requests ];
            my $assert = {
                '!query' => 'superwoman'
            };

            ok( cmp_request_params( $single_request, $assert ) );
        };

        it 'should pass on a negative value assert that exists in one of the request' => sub {
            my $assert = {
                '!query2' => 'superwoman',
                '!query3' => 'superwoman',
            };

            ok( cmp_request_params( $requests, $assert ) );
        };


        it 'should fail if the key value pair exists' => sub {
            my $single_request = [ shift @$requests ];
            my $assert = {
                '!query' => 'string'
            };

            ok( ! cmp_request_params( $single_request, $assert ) );
        };

        it 'should fail if the key does not exist' => sub {
            my $assert = {
                '!missing key' => 'must exist'
            };

            ok( ! cmp_request_params( $requests, $assert ) );
        };

        it 'should fail on a negative value assert that exists in the requests' => sub {
            my $assert = {
                '!query' => 'string'
            };

            ok( ! cmp_request_params( $requests, $assert ) );
        };

        it 'should pass a complicated combination of positive negative asserts' => sub {
            my $assert = {
                query2 => 'string2',
                query3 => 'string3',
                '!query3' => 'superman',
                '!missing key' => ''
            };

            ok( cmp_request_params( $requests, $assert ) );
        };
    }
};

describe 'Placeholder values' => sub {
    my ($requests, $assert);
    before each => sub {
        $requests = [{
            request => {
                queryString => [{
                    name => 'query',
                    value => 'string'
                }, {
                    name => 'query2',
                    value => 'string'
                }]
            }
        }, {
            request => {
                queryString => [{
                    name => 'query2',
                    value => 'string2'
                }, {
                    name => 'query3',
                    value => 'string3'
                }]
            }
        }];

        $assert = { query => 'string', query2 => ':query' };
    };

    it 'should collect query param keys properly' => sub {
        my $query_keys = collect_query_param_keys($requests);
        cmp_deeply($query_keys, [ 'query', 'query2', 'query3' ]);
    };

    it 'should pass through a normal assert' => sub {
        $assert->{query2} = 'string';
        my $mutated = replace_placeholder_values($requests, $assert);
        cmp_deeply($mutated, $assert);
    };

    it 'should mutate an assert with a keyref in it' => sub {
        my $mutated = replace_placeholder_values($requests, $assert);
        cmp_deeply($mutated, { query => 'string', query2 => 'string' } );
    };

    it 'should not mutate assert values that are missing a corresponding actual key' => sub {
        $assert = { query => ':query_missing' };
        my $mutated = replace_placeholder_values($requests, $assert);
        cmp_deeply($mutated, $assert);
    };

    it 'should pass a mutated assert through cmp_request_params' => sub {
        my $mutated = replace_placeholder_values($requests, $assert);
        ok( cmp_request_params($requests, $mutated) );
    };

    it 'should fail an assert with a placeholder through cmp_request_params' => sub {
        ok( ! cmp_request_params($requests, $assert) );
    };

};

SKIP: {
    my $server = Browsermob::Server->new;
    my $has_connection = IO::Socket::INET->new(
        PeerAddr => 'www.perl.org',
        PeerPort => 80,
        Timeout => 5
    );

    skip 'No server found for e2e tests', 2
      unless $server->_is_listening(5) and $has_connection;

    describe 'E2E Comparing params' => sub {
        my ($ua, $proxy, $har);

        before each => sub {
            $ua = LWP::UserAgent->new;
            $proxy = $server->create_proxy;
            $ua->proxy($proxy->ua_proxy);
            $ua->get('http://www.perl.org/?query=string');

            $har = $proxy->har;
        };

        it 'should properly match traffic' => sub {
            ok(cmp_request_params($har, { query => 'string' }));
        };

        it 'should reject non-matching traffic' => sub {
            ok( ! cmp_request_params($har, { query2 => 'string2' }));
        };
    };
}

runtests;
