use strict;
use warnings;

use Test::More;

use JSON qw/ from_json /;

use Test::TCP;
use WWW::Mechanize::PhantomJS;
use Dancer::Plugin::Test::Jasmine::Results;

Test::TCP::test_tcp(
    client => sub {
        my $port = shift;

        my $mech = WWW::Mechanize::PhantomJS->new;
        $mech->get("http://localhost:$port?test=hello");

        jasmine_results( from_json
            $mech->eval_in_page('jasmine.getJSReportAsString()') 
        );
    },
    server => sub {
        my $port = shift;

        use Dancer;
        use jajaja;
        Dancer::Config->load;

        set( startup_info => 0,  port => $port );
        Dancer->dance;
    },
);

done_testing;
