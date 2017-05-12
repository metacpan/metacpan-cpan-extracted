#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Data::Freq::Field;
use Data::Freq::Record;

local $" = ' '; # list separator for "@array"

subtest text => sub {
    plan tests => 3;
    my $field = Data::Freq::Field->new('text');
    is $field->evaluate_record(Data::Freq::Record->new('test')), 'test';
    is $field->evaluate_record(Data::Freq::Record->new(['foo', 'bar'])), 'foo';
    is $field->evaluate_record(Data::Freq::Record->new({foo => 1, bar => 2})), undef;
};

subtest number => sub {
    plan tests => 4;
    my $field = Data::Freq::Field->new('number');
    is $field->evaluate_record(Data::Freq::Record->new(123)), 123;
    is $field->evaluate_record(Data::Freq::Record->new("123 456 789")), 123;
    is $field->evaluate_record(Data::Freq::Record->new([10, 20, 30])), 10;
    is $field->evaluate_record(Data::Freq::Record->new({1 => 2, 3 => 4})), undef;
};

subtest date => sub {
    plan tests => 3;
    my $field;
    
    $field = Data::Freq::Field->new('date');
    is $field->evaluate_record(Data::Freq::Record->new('[2012-01-01 02:03:04]')), '2012-01-01';
    
    $field = Data::Freq::Field->new('month');
    is $field->evaluate_record(Data::Freq::Record->new('[2012-01-01 02:03:04]')), '2012-01';
    
    $field = Data::Freq::Field->new('%H:%M');
    is $field->evaluate_record(Data::Freq::Record->new('[2012-01-01 02:03:04]')), '02:03';
};

subtest pos => sub {
    plan tests => 3;
    my $field;
    
    $field = Data::Freq::Field->new({pos => 2});
    is $field->evaluate_record(Data::Freq::Record->new('a b [c d] e {f g}')), '[c d]';
    
    $field = Data::Freq::Field->new({pos => [1..3]});
    is $field->evaluate_record(Data::Freq::Record->new('a b [c d] e {f g}')), 'b [c d] e';
    
    $field = Data::Freq::Field->new({pos => [-3..-1]});
    is $field->evaluate_record(Data::Freq::Record->new('a b [c d] e {f g}')), '[c d] e {f g}';
};

subtest key => sub {
    plan tests => 2;
    my $field;
    
    $field = Data::Freq::Field->new({key => 'user'});
    is $field->evaluate_record(Data::Freq::Record->new({user => 'foo', bar => 'baz'})), 'foo';
    
    $field = Data::Freq::Field->new({key => [qw(a b c)]});
    is $field->evaluate_record(Data::Freq::Record->new({a => 'A', b => 'B', c => 'C', d => 'D'})), 'A B C';
};

subtest convert => sub {
    plan tests => 1;
    my $field;
    
    $field = Data::Freq::Field->new({convert => sub {
        my $str = shift;
        $str =~ s/ .*//;
        return $str;
    }});
    
    is $field->evaluate_record(Data::Freq::Record->new('foo bar baz')), 'foo';
};
