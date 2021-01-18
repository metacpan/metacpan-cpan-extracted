#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 8;
use Data::FormValidator::URI;
use Data::FormValidator;

###############################################################################
# TEST: URI Constraint - invalid URI scheme
uri_constraint_invalid_scheme: {
    my $res = Data::FormValidator->check( {
        website => 'ftp://www.example.com',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(schemes => [qw( http https )]),
        },
    } );

    my $is_good = $res->valid('website');
    ok !$is_good, 'URI fails to validate when using invalid scheme';
}

###############################################################################
# TEST: URI Constraint - valid URI scheme
uri_constraint_valid_scheme: {
    my $res = Data::FormValidator->check( {
        website => 'http://www.example.com',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(schemes => [qw( http https )]),
        },
    } );

    my $is_good = $res->valid('website');
    ok $is_good, 'URI validates when using a valid scheme';
}

###############################################################################
# TEST: URI Constraint - invalid URI
uri_constraint_invalid_uri: {
    my $res = Data::FormValidator->check( {
        website => 'this is not a URI at all',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(),
        },
    } );

    my $is_good = $res->valid('website');
    ok !$is_good, 'Invalid URI correctly fails to validate';
}

###############################################################################
# TEST: URI Constraint - valid URI
uri_constraint_valid_uri: {
    my $res = Data::FormValidator->check( {
        website => 'http://www.example.com/',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(),
        },
    } );

    my $is_good = $res->valid('website');
    ok $is_good, 'Valid URI validates correctly';
}

###############################################################################
# TEST: URI Constraint - invalid hostname
uri_constraint_invalid_host: {
    my $res = Data::FormValidator->check( {
        website => 'http://www.this-domain-does-not-exist-at-all.com/',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(hostcheck => 1),
        },
    } );

    my $is_good = $res->valid('website');
    ok !$is_good, 'Invalid host name fails host check';
}

###############################################################################
# TEST: URI Constraint - valid hostname
uri_constraint_valid_host: {
    my $res = Data::FormValidator->check( {
        website => 'http://www.google.com/',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(hostcheck => 1),
        },
    } );

    my $is_good = $res->valid('website');
    ok $is_good, 'Valid host name passes host check';
}

###############################################################################
# TEST: URI Constraint - invalid w/embedded user info (by default)
uri_constraint_invalid_user_info: {
    my $res = Data::FormValidator->check( {
        website => 'http://user@yahoo.com/',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(),
        },
    } );

    my $is_good = $res->valid('website');
    ok !$is_good, 'URI invalid w/embedded user info';
}

###############################################################################
# TEST: URI Constraint - embedded user info can be optionally allowed
uri_constraint_allowed_user_info: {
    my $res = Data::FormValidator->check( {
        website => 'http://user@yahoo.com/',
    }, {
        required => [qw( website )],
        constraint_methods => {
            website => FV_uri(allow_userinfo => 1),
        },
    } );

    my $is_good = $res->valid('website');
    ok $is_good, 'URI w/embedded user info valid when allowed';
}
