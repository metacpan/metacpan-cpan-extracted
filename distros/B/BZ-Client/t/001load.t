#!/usr/bin/env perl

use strict;
use warnings 'all';

use lib 't/lib';

use Test::More;

my @MODULES = qw(
        BZ::Client::XMLRPC
        BZ::Client::Product
        BZ::Client::Exception
        BZ::Client::XMLRPC::Array
        BZ::Client::XMLRPC::Value
        BZ::Client::XMLRPC::Handler
        BZ::Client::XMLRPC::Response
        BZ::Client::XMLRPC::Struct
        BZ::Client::XMLRPC::Parser
        BZ::Client::Bug
        BZ::Client::Bug::Attachment
        BZ::Client::Bug::Comment
        BZ::Client::BugUserLastVisit
        BZ::Client::Bugzilla
        BZ::Client::Classification
        BZ::Client::Component
        BZ::Client::FlagType
        BZ::Client::Group
        BZ::Client::User
        BZ::Client::API
        BZ::Client::Test
        BZ::Client
    );

plan( tests => scalar(@MODULES) );

for my $module (@MODULES) {

    require_ok($module) or BAIL_OUT('unable to load module');

}

diag( "Testing BZ::Client $BZ::Client::VERSION, Perl $], $^X" );
