#!/usr/bin/env perl

use strict;
use warnings;

use Test::Spec;
use Data::YADV::Structure;

describe 'Data::YADV::Structure' => sub {
    my $structure;

    before each => sub {
        $structure = Data::YADV::Structure->new([
                {key1 => {key2 => ['array1', 'array2'], key3 => ['array3']}},
                'scalar1'
            ]
        );
    };

    it 'should return child element' => sub {
        is $structure->get_child(qw([0] {key1} {key2} [-1]))->get_structure,
          'array2';
    };

    it 'should return undef if path not exists' => sub {
        is $structure->get_child('[2]'), undef;
        is $structure->get_child(qw([0] {key3})), undef;
    };

    it 'should return type node' => sub {
        is $structure->get_type, 'array';
        is $structure->get_child('[0]')->get_type, 'hash';
        is $structure->get_child('[1]')->get_type, 'scalar';
    };

    it 'should return size of node' => sub {
        is $structure->get_size, 2;
        is $structure->get_child('[0]')->get_size, 1;
        is $structure->get_child('[1]')->get_size, 7;
    };

    it 'should iterate through an array' => sub {
        my @elements;
        $structure->get_child(qw([0] {key1} {key2}))->each(
            sub {
                my ($structure, $index) = @_;
                $elements[$index] = $structure->get_structure;
            }
        );

        is_deeply \@elements, [qw/array1 array2/];
    };

    it 'should iterate through a hash' => sub {
        my %elements;
        $structure->get_child(qw([0] {key1}))->each(
            sub {
                my ($structure, $key) = @_;
                $elements{$key} = $structure->get_structure;
            }
        );

        is_deeply \%elements,
          {key2 => [qw(array1 array2)], key3 => ['array3']};
    };

    it 'should return stringified path' => sub {
        is_deeply $structure->get_child(qw([0] {key1}))
          ->get_path_string(qw({key2} [1])),
          '[0]->{key1}->{key2}->[1]';
    };

    it 'should return parent node' => sub {
        is_deeply $structure->get_child(qw([0] {key1}))->get_parent->get_parent,
          $structure;
    };

    it 'should return parent node with get_child' => sub {
        is_deeply $structure->get_child(qw([0] {key1} {key2} [0] .. .. .. ..)), $structure;
    };

    it 'should return root node' => sub {
        is_deeply $structure->get_child(qw([0] {key1} {key2} [0]))->get_root(), $structure;
    };
};

runtests unless caller;
