#!/usr/bin/perl

use strict;
use warnings;

use Test::Spec;
use Test::Exception;

use File::Basename;
use lib dirname(__FILE__);

use API::MailboxOrg::Types qw(HashRefRestricted);

describe 'HashRefRestricted' => sub {
    it 'allows an empty hash' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        ok $type->( {} );
    };

    it 'allows only the defined keys, using all allowed keys' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        ok $type->( { a => 1, b => 2 } );
    };

    it 'allows only the defined keys, using a subset of the keys' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        ok $type->( { a => 1 } );
    };

    it 'dies on disallowed keys' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        dies_ok { $type->( { c => 1 } ) };
    };

    it 'dies on disallowed keys, even when allowed keys are present' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        dies_ok { $type->( { c => 1, a => 2 } ) };
    };

    it 'dies on non-hashrefs - arrayref' => sub {
        my $type = HashRefRestricted([qw/a b/]); # allow keys a and b only
        dies_ok { $type->( [] ) };
    };
};

runtests if !caller;
