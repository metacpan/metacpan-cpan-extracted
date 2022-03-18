#!/usr/bin/perl

use strict;
use warnings;

use Test::Spec;
use Test::Exception;

use File::Basename;
use lib dirname(__FILE__);

use API::MailboxOrg::Types qw(Boolean);
use JSON::PP;

{
    package  # private package - do not index
        TestClass;

    use Moo;
    use API::MailboxOrg::Types qw(Boolean);

    has true_or_false => ( is => 'rw', isa => Boolean, coerce => 1 );

    1;
}

describe 'Boolean' => sub {

    it 'allows a JSON::PP::true' => sub {
        my $type = Boolean();
        ok $type->( $JSON::PP::true );
    };

    it 'allows a JSON::PP::false' => sub {
        my $type = Boolean();
        is $type->( $JSON::PP::false ), 0;
        isa_ok $type->( $JSON::PP::false ), 'JSON::PP::Boolean';
    };
};

describe "TestClass' true_or_false" => sub {

    it 'allows a JSON::PP::true' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( $JSON::PP::true );
        };

        is $obj->true_or_false, 1;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'allows a JSON::PP::false' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( $JSON::PP::false );
        };

        is $obj->true_or_false, 0;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'allows a 0' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( 0 );
        };

        is $obj->true_or_false, 0;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'allows a 1' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( 1 );
        };

        is $obj->true_or_false, 1;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'allows undef' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( undef );
        };

        is $obj->true_or_false, 0;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'allows empty string' => sub {
        my $obj = TestClass->new;

        lives_ok {
            $obj->true_or_false( "" );
        };

        is $obj->true_or_false, 0;
        isa_ok $obj->true_or_false, 'JSON::PP::Boolean';
    };

    it 'doesn\'t allow any references' => sub {
        my $obj = TestClass->new;

        dies_ok {
            $obj->true_or_false( [] );
        };
    };

    it 'doesn\'t allow strings other than ""' => sub {
        my $obj = TestClass->new;

        dies_ok {
            $obj->true_or_false( "true" );
        };
    };
};

runtests if !caller;
