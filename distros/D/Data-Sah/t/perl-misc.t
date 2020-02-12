#!perl

use 5.010;
use strict;
use warnings;

# Test::Builder requires these modules, we preload them to
BEGIN {
    require overload;
    require List::Util;
}

use Test::Data::Sah qw(test_sah_cases);
use Test::More 0.98;

require lib::filter;

{
    # check double popping of _sahv_dpath, fixed in 0.42+
    my @tests = (
        {
            schema => ["array", {of=>["hash", keys=>{a=>[array=>of=>"any"]}]}],
            input  => [{a=>[]}, {a=>[]}],
            valid  => 1,
        },
    );
    test_sah_cases(\@tests, {gen_validator_opts=>{return_type=>"str_errmsg"}});
}

my @num_tests = (
    {schema => ["int"], input => -5, valid => 1},
    {schema => ["int"], input => 1.1, valid => 0},

    {schema => ["float"], input => -5, valid => 1},
    {schema => ["float"], input => 1.1, valid => 1},
    {schema => ["float"], input => "2e-10", valid => 1},
    {schema => ["float"], input => "NaN", valid => 1},
    {schema => ["float"], input => "NaNx", valid => 0},
    {schema => ["float"], input => "Inf", valid => 1},
    {schema => ["float"], input => "-inf", valid => 1},
    {schema => ["float"], input => "info", valid => 0},

    {schema => ["num"], input => -5, valid => 1},
    {schema => ["num"], input => 1.1, valid => 1},
    {schema => ["num"], input => "2e-10", valid => 1},
    {schema => ["num"], input => "NaN", valid => 1},
    {schema => ["num"], input => "NaNx", valid => 0},
    {schema => ["num"], input => "Inf", valid => 1},
    {schema => ["num"], input => "-inf", valid => 1},
    {schema => ["num"], input => "info", valid => 0},

    {schema => ["float", is_nan=>1], input => "NaN", valid => 1},
    {schema => ["float", is_nan=>1], input => -5, valid => 0},
    {schema => ["float", is_nan=>0], input => "NaN", valid => 0},
    {schema => ["float", is_nan=>0], input => -5, valid => 1},

    {schema => ["float", is_inf=>1], input => "inf", valid => 1},
    {schema => ["float", is_inf=>1], input => "-inf", valid => 1},
    {schema => ["float", is_inf=>1], input => -5, valid => 0},
    {schema => ["float", is_inf=>0], input => "inf", valid => 0},
    {schema => ["float", is_inf=>0], input => "-inf", valid => 0},
    {schema => ["float", is_inf=>0], input => -5, valid => 1},

    {schema => ["float", is_pos_inf=>1], input => "inf", valid => 1},
    {schema => ["float", is_pos_inf=>1], input => "-inf", valid => 0},
    {schema => ["float", is_pos_inf=>1], input => -5, valid => 0},
    {schema => ["float", is_pos_inf=>0], input => "inf", valid => 0},
    {schema => ["float", is_pos_inf=>0], input => "-inf", valid => 1},
    {schema => ["float", is_pos_inf=>0], input => -5, valid => 1},

    {schema => ["float", is_neg_inf=>1], input => "inf", valid => 0},
    {schema => ["float", is_neg_inf=>1], input => "-inf", valid => 1},
    {schema => ["float", is_neg_inf=>1], input => -5, valid => 0},
    {schema => ["float", is_neg_inf=>0], input => "inf", valid => 1},
    {schema => ["float", is_neg_inf=>0], input => "-inf", valid => 0},
    {schema => ["float", is_neg_inf=>0], input => -5, valid => 1},
);

subtest "compile option: no_modules" => sub {
    no warnings 'once';
    local $Data::Sah::Compiler::perl::NO_MODULES = 1;
    lib::filter->import(allow_core=>0, allow_noncore=>0, allow_re=>'^(Data::Sah::Type::.+|Data::Sah::Compiler::(human|perl)::.+|Data::Sah::Coerce::perl::.+|alias::module)$');
    test_sah_cases(\@num_tests);
    lib::filter->unimport;
};

subtest "compile option: core" => sub {
    no warnings 'once';
    local $Data::Sah::Compiler::perl::CORE = 1;
    lib::filter->import(disallow => 'Scalar::Util::Numeric;Scalar::Util::Numeric::PP');
    test_sah_cases(\@num_tests);
    lib::filter->unimport;
};

subtest "compile option: core_or_pp" => sub {
    no warnings 'once';
    local $Data::Sah::Compiler::perl::CORE_OR_PP = 1;
    lib::filter->import(disallow => 'Scalar::Util::Numeric');
    test_sah_cases(\@num_tests);
    lib::filter->unimport;
};

subtest "compile option: pp" => sub {
    no warnings 'once';
    local $Data::Sah::Compiler::perl::PP = 1;
    lib::filter->import(disallow => 'Scalar::Util::Numeric');
    test_sah_cases(\@num_tests);
    lib::filter->unimport;
};

subtest "coerce input data" => sub {
    test_sah_cases(
        [
            {
                schema => 'date',
                input => '2016-06-01',
                valid => 1,
            },
        ]
    );
};

subtest "coerce clause value" => sub {
    test_sah_cases(
        [
            {
                schema => [date => min => '2016-01-01'],
                input => 1464541200, # 2016-05-30
                valid => 1,
            },
        ]
    );
};

subtest "coerce array elements + has" => sub {
    test_sah_cases(
        [
            {
                schema => [array => of => 'date', has => '2016-06-01T00:00:00Z'],
                input => [1464739200, '2016-05-30'],
                valid => 1,
            },
        ]
    );
};

done_testing();
