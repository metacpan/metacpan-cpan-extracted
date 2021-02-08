#!/usr/bin/env perl
use strict;

use Test::More tests => 38;

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
mkdir $test_dir or die $!;
chmod 0755, $test_dir;

#----------------------------------------------------------------------
# Create object

my $obj = App::Followme::BaseData->new();
isa_ok($obj, "App::Followme::BaseData"); # test 1
can_ok($obj, qw(new build)); # test 2

#----------------------------------------------------------------------
# Check split name

do {
    my ($sigil, $name) = $obj->split_name('$is_first');
    is($sigil, '$', 'split scalar variable sigil'); # test 3
    is($name, 'is_first', 'split scalar variable name'); # test 4

    ($sigil, $name) = $obj->split_name('@loop');
    is($sigil, '@', 'split array variable sigil'); # test 5
    is($name, 'loop', 'split array variable name'); # test 6

    ($sigil, $name) = $obj->split_name('loop');
    is($sigil, '', 'split module variable sigil'); # test 7
    is($name, 'loop', 'split module variable name'); # test 8

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
};

#----------------------------------------------------------------------
# Check coerce_data

do {
    my $name = 'test';
    my @data = ();

    my %data = $obj->coerce_data($name, @data);
    is_deeply(\%data, {}, "Coerce data with no argument"); # test 12

   push(@data, 'foo');
   %data = $obj->coerce_data($name, @data);
   is_deeply(\%data, {test => 'foo'}, "Coerce data with one argument"); # test 13

   push(@data, 'bar');
   %data = $obj->coerce_data($name, @data);
   is_deeply(\%data, {'foo' => 'bar'}, "Coerce data with two arguments"); # test 14
};

#----------------------------------------------------------------------
# Check sort and format

do {

    my $data = {
        name => [qw(one two three four)],
    };

    my $sorted_ok = {
        name => [qw(four one three two)],
    };

    my $sorted_data = $obj->sort($data, 'name');
    is_deeply($sorted_data, $sorted_ok, "Sort data by name"); # test 15

    my $formatted_data = $obj->format(0, $data);
    is_deeply($formatted_data, $data, "Format data (noop)") # test 16
};

#----------------------------------------------------------------------
# Check build methods

do {
    my %data_ok =  ('$count' => {first => 1,
                                 second => 2,
                                 third => 3,
                                },
                    '$name' => {first => 'first',
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
                    '$target' => {first => 'target1',
                                  second => 'target2',
                                  third => 'target3',
                                 }, 
                    '$target_previous' => {first => '',
                                           second => 'target1',
                                           third => 'target2',
                                          }, 
                    '$target_next' => {first => 'target2',
                                       second => 'target3',
                                       third => '',
                                      }, 
                     );

    my $item;
    my @loop = qw(first second third);

    my $data = $obj->build('loop_by_name', $item, \@loop);
    is_deeply($data, \@loop, 'Build loop'); # test 17

    foreach my $item (@loop) {
        foreach my $name (qw($count $name $is_first $is_last $target 
                             $target_previous $target_next)) {
                                 
            my $by_name = $name . '_by_name';
            my $data = $obj->build($by_name, $item, \@loop);
            my $data_ok = $data_ok{$name}{$item};
            my $ref_ok = ref $data_ok ? $data_ok : \$data_ok;

            is_deeply($data, $ref_ok, "Build $name for $item"); #test 18-38
        }
    }
}
