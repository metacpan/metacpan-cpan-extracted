#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 5;
use Data::FormValidator::URI;

###############################################################################
# TEST: URI Filter - default scheme added when no scheme present
uri_filter_default_scheme: {
    my $fcn = FV_uri_filter(default_scheme => 'ftp');
    my $got = $fcn->('www.example.com/public/');
    is $got, 'ftp://www.example.com/public/',
        'Default scheme added when missing in URI';
}

###############################################################################
# TEST: URI Filter - default scheme ignored when a scheme *is* present
uri_filter_ignore_default_scheme: {
    my $fcn = FV_uri_filter(default_scheme => 'ftp');
    my $got = $fcn->('http://www.example.com/');
    is $got, 'http://www.example.com/',
        'Default scheme ignored when present in URI';
}

###############################################################################
# TEST: URI Filter - canonicalized
uri_filter_canonicalized: {
    my $fcn = FV_uri_filter();
    my $got = $fcn->('http://WWW.ExAmPlE.cOm:80/BuT/LeAvE/ThIs/AlOne');
    is $got, 'http://www.example.com/BuT/LeAvE/ThIs/AlOne',
        'Hostname lower-cased';
}

###############################################################################
# TEST: URI Filter - make sure "://" was typed correctly
uri_filter_ensure_double_slash: {
    my $fcn = FV_uri_filter();
    my $got = $fcn->('http:/www.example.com/');
    is $got, 'http://www.example.com/',
        'Double-slash typo corrected';
}

###############################################################################
# TEST: URI Filter - pass-through
uri_filter_pass_through: {
    my $fcn = FV_uri_filter();
    my $got = $fcn->('http://www.example.com/is/a/good/uri');
    is $got, 'http://www.example.com/is/a/good/uri',
        'URI passed through untouched when it looks good';
}
