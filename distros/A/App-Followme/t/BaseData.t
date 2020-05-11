#!/usr/bin/env perl
use strict;

use Test::More tests => 37;

use File::Path qw(rmtree);
use File::Spec::Functions qw(catdir catfile rel2abs splitdir);

#----------------------------------------------------------------------
# Load package

my @path = splitdir(rel2abs($0));
pop(@path);
pop(@path);

my $lib = catdir(@path, 'lib');
unshift(@INC, $lib);

$lib = catdir(@path, 't');
unshift(@INC, $lib);

require App::Followme::BaseData;

my $test_dir = catdir(@path, 'test');

rmtree($test_dir);
mkdir $test_dir;
chmod 0755, $test_dir;

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::BaseData->new(labels => 'one,two,three');
isa_ok($obj, "App::Followme::BaseData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Check split name

do {
    my ($sigil, $name) = $obj->split_name('$is_first');
    is($sigil, '$', 'split scalar variable sigil'); # test 3
    is($name, 'is_first', 'split scalar variable name'); # test 4

    ($sigil, $name) = $obj->split_name('@sequence');
    is($sigil, '@', 'split array variable sigil'); # test 5
    is($name, 'sequence', 'split array variable name'); # test 6

    ($sigil, $name) = $obj->split_name('sequence');
    is($sigil, '', 'split module variable sigil'); # test 7
    is($name, 'sequence', 'split module variable name'); # test 8

};

#----------------------------------------------------------------------
# Check ref value

do {
    my $value;
    my $ok_value = '';
    my $ref_value = $obj->ref_value($value, '$', 'is_first');
    is_deeply($ref_value, \$ok_value, 'ref value of scalar undef'); # test 9

    $value = 1;
    $ok_value = $value;
    $ref_value = $obj->ref_value($value, '$', 'is_first');
    is_deeply($ref_value, \$ok_value, 'ref value of scalar value'); # test 10

    $value = \1;
    $ok_value = $value;
    $ref_value = $obj->ref_value($value, '$', 'is_first');
    is ($ref_value, $ok_value, 'ref value of scalar reference'); # test 11

    undef $value;
    eval {$ref_value = $obj->ref_value($value, '@', 'sequence')};
    ok($@, 'ref value of array undef'); # test 12

    $value =  [qw(first.html last.html)];
    $ok_value = $value;
    $ref_value = $obj->ref_value($value, '@', 'sequence');
    is_deeply($ref_value, $ok_value, 'ref value of array value'); # test 13

    undef $value;
    eval {$ref_value = $obj->ref_value($value, '', 'sequence')};
    ok($@, 'ref value of module undef'); # test 14

    $value =  [qw(first.html last.html)];
    $ok_value = $value;
    $ref_value = $obj->ref_value($value, '', 'sequence');
    is_deeply($ref_value, $ok_value, 'ref value of module value'); # test 15

};

#----------------------------------------------------------------------
# Check coerce_data

do {
    my $name = 'test';
    my @data = ();

    my %data = $obj->coerce_data($name, @data);
    is_deeply(\%data, {}, "Coerce data with no argument"); # test 16

   push(@data, 'foo');
   %data = $obj->coerce_data($name, @data);
   is_deeply(\%data, {test => 'foo'}, "Coerce data with one argument"); # test 17

   push(@data, 'bar');
   %data = $obj->coerce_data($name, @data);
   is_deeply(\%data, {'foo' => 'bar'}, "Coerce data with two arguments"); # test 18
};

#----------------------------------------------------------------------
# Check build methods

do {
    my %data_ok =  ('$count' => {first => 1,
                                 second => 2,
                                 third => 3,
                                },
                    '$item' => {first => 'first',
                                second => 'second',
                                third => 'third',
                               },
                    '$is_first' => {first => 1,
                                    second => 0,
                                    third => 0,
                                  },
                    '$is_last' => {first => 0,
                                   second => 0,
                                   third => 1,
                                  },
                    '@sequence' => {first => ['', 'second'],
                                    second => ['first', 'third'],
                                    third => ['second', ''],
                                   },
                    '$label' =>  {first => 'One',
                                  second => 'Two',
                                  third => 'Three',
                                  },
                     );

    my $item;
    my @loop = qw(first second third);

    my $data = $obj->build('loop', $item, \@loop);
    is_deeply($data, \@loop, 'Build loop'); # test 19

    foreach my $item (@loop) {
        foreach my $name (qw($count $item $is_first $is_last @sequence $label)) {
            my $data = $obj->build($name, $item, \@loop);
            my $data_ok = $data_ok{$name}{$item};
            my $ref_ok = ref $data_ok ? $data_ok : \$data_ok;

            is_deeply($data, $ref_ok, "Build $name for $item"); #test 19-37
        }
    }
}
