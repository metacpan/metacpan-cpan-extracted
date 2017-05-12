#!/usr/bin/perl

# Copyright (c) Nate Wiger http://nateware.com.
# All Rights Reserved. If you're reading this, you're bored.
# 1c-validate.t - test validation

use strict;

our $TESTING = 1;
our $DEBUG = $ENV{DEBUG} || 0;
our $LOGNAME = $ENV{LOGNAME} || '';
our $VERSION;
BEGIN { $VERSION = '3.10'; }

use Test;
use FindBin;

# use a BEGIN block so we print our plan before CGI::FormBuilder is loaded
BEGIN { 
    my $numtests = 13;
    unshift @INC, "$FindBin::Bin/../lib";

    plan tests => $numtests;

    # success if we said NOTEST
    if ($ENV{NOTEST}) {
        ok(1) for 1..$numtests;
        exit;
    }
}

# Need to fake a request or else we stall
$ENV{REQUEST_METHOD} = 'GET';
$ENV{QUERY_STRING} = '_submitted=1&submit=ClickMe&blank=&hiphop=Early+East+Coast';

use CGI::FormBuilder 3.10;

sub is_number {
    my $v = shift;
    return $v =~ /^\d+$/;
}

# What options we want to use, and data to validate
my @test = (
    #1
    {
        opt => { fields => [qw/first_name email/],
                 validate => {email => 'EMAIL'}, 
                 required => [qw/first_name/] ,
                 values => { first_name => 'Nate', email => 'nate@wiger.org' },
               },
        pass => 1,
    },

    #2
    {
        # max it out, baby
        opt => { fields => [qw/supply demand/],
                 options => { supply => [0..9], demand => [0..9] },
                 values  => { supply => [0..4], demand => [5..7] },
                 validate => { supply => [5..9], demand => [0..9] },
               },
        pass => 0,
    },

    #3
    {
        # max it out, baby
        opt => { fields => [qw/supply tag/],
                 options => { supply => [0..9], },
                 values  => { supply => [0..4], tag => ['Johan-Sebastian', 'Bach'] },
                 validate => { supply => 'NUM', tag => 'NAME' },
               },
        pass => 0,
    },

    #4
    {
        opt => { fields => [qw/date time ip_addr name time_confirm/],
                 validate => { date => 'DATE', time => 'TIME', ip_addr => 'IPV4',
                               time_confirm => 'eq $form->field("time")' },
                 values => { date => '03/30/2003', time => '1:30', ip_addr => '129.153.53.1', time_confirm => '1:30' },
               },
        pass => 1,
    },

    #5
    {
        opt => { fields => [qw/security_test/],
                 validate => { security_test => 'ne 42' },
                 values => { security_test => "'; print join ':', \@INC; return; '" },
               },
        pass => 1,
    },

    #6
    {
        opt => { fields => [qw/security_test2/],
                 validate => { security_test2 => 'ne 42' },
                 values => { security_test2 => 'foo\';`cat /etc/passwd`;\'foo' },
               },
        pass => 1,
    },

    #7
    {
        opt => { fields => [qw/subref_num/],
                 values => {subref_num => [0..9]},
                 validate => {subref_num => \&is_number},
               },
        pass => 1,
    },

    #8
    {
        opt => { fields => [qw/blank/],
                 values => {blank => '1@2.com'},
                 validate => {blank => 'EMAIL'},
                 required => 'NONE',
               },
        pass => 1,
    },

    #9
    {
        opt => { fields => [qw/blank/],
                 values => {blank => '1@2.com'},
                 validate => {blank => 'EMAIL'},
                 required => [qw/blank/],
               },
        pass => 0,  # should fail
    },

    #10
    {
        opt => { fields => [qw/tomato potato/],
                 values => {tomato => 'TomaTo', potato => '~SQUASH~'},
                 validate => {tomato => {perl => '=~ /^TomaTo$/',
                                         javascript => 'placeholder'},
                              potato => {perl => 'VALUE',
                                         javascript => 'placeholder'},
                             },
               },
        pass => 1,
    },

    #11
    {
        opt => { fields => [qw/have you seen/],
                 values => { you => 'me', seen => 'OB', have => "Nothing" },
                 validate => { have => '/^Not/' },
                 required => 'ALL' },
        pass => 1,
    },

    #12
    {
        opt => { fields => [qw/required_zero required_space/],
                 values => { required_zero => '0', required_space => ' ' },
                 required => 'ALL' },
        pass => 1,
    },

    #13
    {
        opt => { fields => [qw/required_empty/],
                 values => { required_empty => '' },
                 required => 'ALL' },
        pass => 0,
    },
);

# Cycle thru and try it out
for my $t (@test) {

    my $form = CGI::FormBuilder->new( %{ $t->{opt} }, debug => $DEBUG );
    while(my($f,$o) = each %{$t->{mod} || {}}) {
        $o->{name} = $f;
        $form->field(%$o);
    }

    # just try to validate
    ok($form->validate, $t->{pass} || 0);
}

