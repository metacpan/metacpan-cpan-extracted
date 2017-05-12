#!perl -T

use strict;
use warnings;

use Test::More tests => 9;

use Data::Freq::Field;
use Data::Freq;

subtest type_text => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new();
    $data->add('a') foreach 1..3;
    $data->add('b') foreach 1..5;
    $data->add('c') foreach 1..2;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(c b a)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'count', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(c a b)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'count', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b a c)]);
};

subtest type_number => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new();
    $data->add('10') foreach 1..3;
    $data->add('2') foreach 1..5;
    $data->add('3') foreach 1..2;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'number', sort => 'value', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(2 3 10)]);
    
    $field = Data::Freq::Field->new({type => 'number', sort => 'value', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(10 3 2)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(10 2 3)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(3 2 10)]);
};

subtest sort_occurrence => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new();
    $data->add('a') foreach 1..3;
    $data->add('b') foreach 1..5;
    $data->add('c') foreach 1..2;
    $data->add('b') foreach 1..5;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'first', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'first', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(c b a)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'last', order => 'asc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a c b)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'last', order => 'desc'});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c a)]);
};

subtest sort_unique => sub {
    plan tests => 2;
    
    my $data = Data::Freq->new(0, 1);
    $data->add([qw(a x)]) foreach 1..5;
    $data->add([qw(a y)]) foreach 1..5;
    $data->add([qw(b x)]) foreach 1..3;
    $data->add([qw(b y)]) foreach 1..3;
    $data->add([qw(b z)]) foreach 1..3;
    $data->add([qw(c z)]) foreach 1..2;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    my $subfield = Data::Freq::Field->new({type => 'text', aggregate => 'unique'});
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'asc'});
    is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(c a b)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'desc'});
    is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(b a c)]);
};

subtest sort_min_max => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new(0, 1);
    $data->add([qw(a x)]) foreach 1..2;
    $data->add([qw(a y)]) foreach 1..4;
    $data->add([qw(b x)]) foreach 1..3;
    $data->add([qw(b y)]) foreach 1..3;
    $data->add([qw(b z)]) foreach 1..3;
    $data->add([qw(c z)]) foreach 1..5;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    my $subfield;
    
    $subfield = Data::Freq::Field->new({type => 'text', aggregate => 'max'});
    {
        $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'asc'});
        is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(b a c)]);
        
        $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'desc'});
        is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(c a b)]);
    }
    
    $subfield = Data::Freq::Field->new({type => 'text', aggregate => 'min'});
    {
        $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'asc'});
        is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(a b c)]);
        
        $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'desc'});
        is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(c b a)]);
    }
};

subtest sort_average => sub {
    plan tests => 2;
    
    my $data = Data::Freq->new(0, 1);
    $data->add([qw(a x)]) foreach 1..5;
    $data->add([qw(a y)]) foreach 1..1;
    $data->add([qw(b x)]) foreach 1..2;
    $data->add([qw(b y)]) foreach 1..2;
    $data->add([qw(b z)]) foreach 1..2;
    $data->add([qw(c z)]) foreach 1..4;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    my $subfield = Data::Freq::Field->new({type => 'text', aggregate => 'average'});
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'asc'});
    is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(b a c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'score', order => 'desc'});
    is_deeply($field->select_nodes($nodes, $subfield), [map {$children->{$_}} qw(c a b)]);
};

subtest offset => sub {
    plan tests => 9;
    
    my $data = Data::Freq->new();
    $data->add('a') foreach 1..3;
    $data->add('b') foreach 1..5;
    $data->add('c') foreach 1..2;
    $data->add('d') foreach 1..5;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 0});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 3});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 4});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw()]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -3});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -4});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c d)]);
};

subtest limit => sub {
    plan tests => 9;
    
    my $data = Data::Freq->new();
    $data->add('a') foreach 1..3;
    $data->add('b') foreach 1..5;
    $data->add('c') foreach 1..2;
    $data->add('d') foreach 1..5;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => 0});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw()]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => 1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => 2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => 3});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => 4});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c d)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => -1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => -2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a b)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => -3});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(a)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', limit => -4});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw()]);
};

subtest offset_limit => sub {
    plan tests => 4;
    
    my $data = Data::Freq->new();
    $data->add('a') foreach 1..3;
    $data->add('b') foreach 1..5;
    $data->add('c') foreach 1..2;
    $data->add('d') foreach 1..5;
    
    my $children = $data->root->children;
    my $nodes = [values %$children];
    
    my $field;
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 1, limit => 2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -3, limit => 2});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => 1, limit => -1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c)]);
    
    $field = Data::Freq::Field->new({type => 'text', sort => 'value', order => 'asc', offset => -3, limit => -1});
    is_deeply($field->select_nodes($nodes), [map {$children->{$_}} qw(b c)]);
};
