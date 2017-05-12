#!/usr/bin/perl -w
use strict;

use lib qw(./lib);
use Test::More tests => 58;

use CPAN::Testers::Report;
use CPAN::Testers::WWW::Reports::Query::Report;
use JSON::XS;
use Data::Dumper;

# various argument sets for examples

my @args = (
# json: hash=0, self=1
# hash: hash=0, self=1
# as = fact

    { 
        spec    => { as_hash => 1, as_json => 1 },
        args    => { report  => 40000000, as_json => 0, as_hash => 0 },
        results => { guid => '5fa5ec4e-9f27-11e3-9b58-10cf2a990ce1' },
        fact    => 1
    },

# json: hash=undef, self=0
# hash: hash=undef, self=0
# as = fact

    { 
        spec    => { host => 'http://cpantesters.org' },
        args    => { report  => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        fact    => 1
    },

# json: hash=undef, self=0
# hash: hash=1, self=0
# as = hash

    { 
        spec    => {},
        args    => { report  => 40000000, as_hash => 1 },
        results => { guid => '5fa5ec4e-9f27-11e3-9b58-10cf2a990ce1' },
        hash    => 1
    },

# json: hash=undef, self=0
# hash: hash=undef, self=1
# as = hash

    { 
        spec    => { as_hash => 1 },
        args    => { report  => 'b599a190-b601-11e3-add5-ed1d4a243164' },
        results => { guid => 'b599a190-b601-11e3-add5-ed1d4a243164' },
        hash    => 1
    },

# json: hash=1, self=0
# hash: hash=undef, self=0
# as = json

    { 
        spec    => {},
        args    => { report  => 40853050, as_json => 1 },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        json    => 1
    },

# json: hash=undef, self=1
# hash: hash=undef, self=0
# as = json

    { 
        spec    => { as_json => 1 },
        args    => { report  => 40853050 },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        json    => 1
    },

# json: hash=1, self=0
# hash: hash=0, self=1
# as = json

    { 
        spec    => { as_hash => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 1, as_hash => 0 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },

# json: hash=undef, self=0
# hash: hash=undef, self=0
# as = fact

    { 
        spec    => {},
        args    => { report  => 40853050 },
        results => { guid => '1cbc9d0c-b60a-11e3-9e09-941504fe8cc2' },
        fact    => 1
    },

# json: hash=1, self=1
# hash: hash=1, self=1
# as = json

    { 
        spec    => { as_json => 1, as_hash => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 1, as_hash => 1 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },

# json: hash=1, self=0
# hash: hash=1, self=0
# as = json

    { 
        spec    => {},
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 1, as_hash => 1 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },

# json: hash=0, self=1
# hash: hash=1, self=1
# as = hash

    { 
        spec    => { as_json => 1, as_hash => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 0, as_hash => 1 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        hash    => 1
    },

# json: hash=1, self=1
# hash: hash=0, self=1
# as = json

    { 
        spec    => { as_json => 1, as_hash => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_json => 1, as_hash => 0 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },

# json: hash=undef, self=1
# hash: hash=1, self=0
# as = json

    { 
        spec    => { as_json => 1 },
        args    => { report  => '5f7b56be-9f27-11e3-9385-a7e693cf7503', as_hash => 1 },
        results => { guid => '5f7b56be-9f27-11e3-9385-a7e693cf7503' },
        json    => 1
    },



    # bad data
    { 
        spec    => { as_hash => 1, as_json => 1 },
        args    => { report  => 1, as_json => 0, as_hash => 0 },
        results => { guid => '' },
        error   => 'no report found'
    },
);

SKIP: {
    skip "Network unavailable", 55 if(pingtest());

    for my $args (@args) {
        my $spec = $args->{spec};

        my $query = CPAN::Testers::WWW::Reports::Query::Report->new( %$spec );
        isa_ok($query,'CPAN::Testers::WWW::Reports::Query::Report');

        my $error = '';
        my $data = $query->report( %{$args->{args}} );

        if($data && $args->{json}) {
            eval {
                $data = decode_json($data);
                #diag("JSON data=".Dumper($data));
                is($data->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in JSON [$args->{args}{report}]") for(keys %{$args->{results}});
            };

            is($@,'','.. no eval errors on result, expected JSON object');

        } elsif($data && $args->{hash}) {
            eval {
                #diag("hash data=".Dumper($data->{metadata}));
                is($data->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in hash [$args->{args}{report}]") for(keys %{$args->{results}});
            };

            is($@,'','.. no eval errors on result, expected hash');

        } elsif($data && $args->{fact}) {
            eval {
                my $fact = $data->as_struct;
                #diag("fact data=".Dumper($fact));
                is($fact->{metadata}{core}{$_},$args->{results}{$_},".. got '$_' in fact [$args->{args}{report}]") for(keys %{$args->{results}});
            };

            is($@,'','.. no eval errors on result, expected fact object');

        } elsif(!$data && $args->{error}) { #error expected
            $error = $query->error;
            like($error,qr/$args->{error}/,'.. got expected error');
        } else {
            # we are running live tests, so occasionally the server may be busy
            $error = $query->error;
            if($error =~ /No response from server/) {
                ok(1,'skip as server not responding');
            } else {
                diag("error args=".Dumper($args));
                diag("error data=".Dumper($data));
                diag("error message=".$error);
                diag("server response=".$query->content);
                ok(0,'missing results for test');
            }
        }

        is($query->error,$error,'.. errors as anticipated');
    }
}

# Private Method tests

{
    my $query = CPAN::Testers::WWW::Reports::Query::Report->new();
    isa_ok($query,'CPAN::Testers::WWW::Reports::Query::Report');

    my $data = $query->_parse();
    is($query->error(),'no data returned');
    is($data,undef);
}


# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = 'api.cpantesters.org';
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    system($cmd);
    my $retcode = $? >> 8;
    # ping returns 1 if unable to connect
    return $retcode;
}
