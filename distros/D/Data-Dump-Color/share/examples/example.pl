#!/usr/bin/perl

use Data::Dump::Color;

dd({
    undef => undef,

    # strings
    str => 'Jason',
    str_empty => '',
    str_with_newlines => "Mark\nJason\nDominus",

    # numbers
    num_int => 45,
    num_neg_int => -45,
    num_float => 0.23,
    num_neg_float => -0.23,
    num_str_int => "45",
    num_neg_str_int => "-45",
    num_str_float => "0.23",
    num_neg_str_float => "-0.23",
    num_nan => nan,
    num_inf => inf,
    num_neg_nan => -nan,
    num_neg_inf => -inf,
    num_exp => 1.2e+100,
    num_neg_exp => -1.2e-101,

    # arrays
    array => [1, 2.2, "3", "a", "b", undef, []],
    array_empty => [],
    array_long => [qw/For backward compatibility with older implementations that
                      didn't support anonymous globs/],
    array_aoh_mostly => [
        { name => 'Andi', dob => '1988-10-10', employee_id=>1, some_other_attribute => 'some value', },
        { name => 'Budi', dob => '1983-01-22', employee_id=>2, some_other_attribute => 'some value', },
        { name => 'Cika', dob => '1986-07-03', employee_id=>3, some_other_attribute => 'some value', },
        "this one is not a hash",
    ],

    # hashes
    hash => {a=>1, b=>2, c=>[], d=>{}, e=>undef},
    hash_empty => {},
    hash_long => {qw/For backward compatibility with older implementations that
                     didn't support anonymous globs/},
    hash_hoh_mostly => {
        EMP001 => { name => 'Andi', dob => '1988-10-10', employee_id=>'EMP001', some_other_attribute => 'some value', },
        EMP002 => { name => 'Budi', dob => '1983-01-22', employee_id=>'EMP003', some_other_attribute => 'some value', },
        EMP3   => { name => 'Cika', dob => '1986-07-03', employee_id=>'EMP3'  , some_other_attribute => 'some value', },
        key4   => "this one is not a hash",
    },

    # objects
    obj => bless({a=>1, b=>2}, "Foo"),

    # others
    regexp => qr/^ab(?:cd)$/i,
    glob => \*FOO,
    circular => do { my $a = [1]; push @$a, $a; $a },
});
