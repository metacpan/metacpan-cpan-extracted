use ExtUtils::testlib;
use Test::More ;
use Config::Model 2.142;
use Config::Model::Tester::Setup qw/init_test setup_test_dir/;
use Data::Dumper ;
use Path::Tiny;

use Config::Model::Itself ;
use Test::Memory::Cycle;
use Test::Differences;
use Storable qw/dclone/;

use warnings;
use strict;
use v5.20;
use utf8;

subtest "deduplicate level" => sub {
    my $input = {
        A => 'important',
        B => 'hidden',
        C => 'important',
        D => 'standard',
    };
    my $expect = {
        important => [qw/A C/],
        qw/hidden B standard D/
    };
    Config::Model::Itself::factorize_reverse_packed($input);
    
    eq_or_diff($input, $expect, "test factorize_reverse_packed" );
};

subtest "deduplicate summary" => sub {
    my $input = {
        A => 'summary1',
        B => 'summary2',
        C => 'summary1',
        D => 'summary2',
    };
    my $expect = {qw/A summary1 B summary2 C *A D *B/};
    Config::Model::Itself::factorize_with_alias($input);
    
    eq_or_diff($input, $expect, "test factorize_with_alias" );
};

subtest "factorize description and level" => sub {
    my $class = {
        name    => 'Itself::CommonElement::WarnIfMatch',
        element => [
            msg => {
                type       => 'leaf',
                value_type => 'string',
                description => 'msg description',
                level => 'important',
            },
            fix => {
                type       => 'leaf',
                value_type => 'string',
                level => 'important',
            },
        ],
        description => {
            fix => 'fix description',
        }
    };

    my $expect = {
        name    => 'Itself::CommonElement::WarnIfMatch',
        element => [
            'msg' => {
                'type' => 'leaf',
                'value_type' => 'string'
            },
            'fix' => '*msg'
        ],
        description => {
            fix => 'fix description',
            msg => 'msg description',
        },
        level => {
            important => [qw/fix msg/],
        }
    };

    Config::Model::Itself::factorize_model($class,'all');

    eq_or_diff($class, $expect, "test factorized class" );
};

subtest "deduplicate description" => sub {
    my $class = {
        name    => 'Itself::CommonElement::WarnIfMatch',
        element => [
            msg => {
                type       => 'leaf',
                value_type => 'string',
                description => 'a description',
            },
            fix => {
                type       => 'leaf',
                value_type => 'string',
                description => 'a description',
            },
            other => {
                type => 'leaf',
                value_type => 'uniline',
            }
        ],
    };

    my $expect = {
        name    => 'Itself::CommonElement::WarnIfMatch',
        element => [
            'msg' => {
                'value_type' => 'string',
                'type' => 'leaf'
            },
            'fix' => '*msg',
            'other' => {
                'value_type' => 'uniline',
                'type' => 'leaf'
            },
        ],
        description => {
            'fix' => 'a description',
            'msg' => '*fix',
        },
    };

    Config::Model::Itself::factorize_model($class, 'all');

    eq_or_diff($class, $expect, "test factorized class" );
};

subtest "test on many identical elements" => sub {
    my @elt_list =  qw/aa2 ab2 ac2 ad2 Z/;
    my $class = {
        name    => 'DontCare',
        element => [
            map { $_ => { type => 'leaf', value_type => 'string' } } @elt_list
        ]
    };

    my $expect = {
        name    => 'DontCare',
        element => [
            aa2 => {
                type       => 'leaf',
                value_type => 'string',
            },
            qw/ab2 *aa2 ac2 *aa2 ad2 *aa2 Z *aa2/
        ]
    };

    Config::Model::Itself::factorize_element($class->{element});

    eq_or_diff($class, $expect, "test factorized element" );

    # no need to add 'all', element is always factorized
    Config::Model::Itself::factorize_model($class);

    eq_or_diff($class, $expect, "test factorized class" );
};

done_testing;
