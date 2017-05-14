#!/usr/bin/perl
use Test::More;
use lib 't';
use utf8;
use Encode;
binmode( STDERR, ":utf8" );
binmode( STDOUT, ":utf8" );
use testlib::Object::Nested;
use testlib::TestDB qw($dbh $schema);

# ugly hack to override fixed class in Test-Row, so I don't have to create another table
package testlib::Schema::Test;
DBIx::Class::InflateColumn::JSON2Object->fixed_class({
    column=>'fixed_class',
    class=>'testlib::Object::NestedRecipe',
});
# end of hack, back to main
package main;

my $id;
use JSON::MaybeXS;

subtest 'insert object' => sub {
    my $obj = testlib::Object::NestedRecipe->new({
        name=>'Mac and Cheese',
        ingredients=>[
            {
                name=>'Mac',
                amount=>'500g',
                is_vegan=>1,
            },
            {
                name=>'Cheese',
                amount=>'a lot',
                is_vegan=>0,
            },
        ],
    });

    my $row = $schema->resultset('Test')->create({fixed_class=>$obj});
    $id = $row->id;

    my ($via_dbi) = $dbh->selectrow_array("select fixed_class from test where id = ?",undef, $id);
    my $data = decode_json($via_dbi);
    is($data->{name},'Mac and Cheese','recipe name');
    is($data->{ingredients}[0]{name},'Mac','ingredient 1 name');
    is($data->{ingredients}[1]{amount},'a lot','amount 2');
    is($data->{ingredients}[0]{is_vegan},1,'ingredient 1 is vegan');
    is($data->{ingredients}[1]{is_vegan},0,'ingredient 2 is not vegan');

};

subtest 'fetch JSON as object' => sub {
    my $row = $schema->resultset('Test')->find($id);
    my $obj = $row->fixed_class;
    is(ref($obj),'testlib::Object::NestedRecipe','class');
    is($obj->name,'Mac and Cheese','title');
    is($obj->ingredients->[0]->name,'Mac','ingredient 1 name');
    is($obj->ingredients->[1]->amount,'a lot','amount 2');
    is($obj->ingredients->[0]->is_vegan,1,'ingredient 1 is vegan');
    is($obj->ingredients->[1]->is_vegan,0,'ingredient 2 is not vegan');
};

subtest 'fetch and update' => sub {
    my $row = $schema->resultset('Test')->find($id);

    my $obj = $row->fixed_class;
    $obj->add_ingredient(testlib::Object::NestedIngredient->new({
        name=>'Pepper',
        amount=>'a good pinch',
        is_vegan=>1,
    }));

    $row->update({fixed_class=>$obj});

    my $fresh = $schema->resultset('Test')->find($id);
    is(@{$fresh->fixed_class->ingredients} ,3,'3 ingredients');
};

subtest 'replace' => sub {
    my $row = $schema->resultset('Test')->find($id);

    my $obj = testlib::Object::NestedRecipe->new({
        name=>'Eierspeis',
        ingredients=>[
            {
                name=>'Eier',
                amount=>'2 per person',
                is_vegan=>0,
            },
        ],
    });

    $row->update({fixed_class=>$obj});

    my $fresh = $schema->resultset('Test')->find($id);
    is($fresh->fixed_class->name,'Eierspeis','name');
    is(@{$fresh->fixed_class->ingredients} ,1,'1 ingredient');
};

subtest 'insert object from raw json' => sub {
    my $raw_json = '{"name":"sushi","ingredients":[{"name":"some fish","amount":"100g"},{"name":"rice","amount":"just enough"}]}';

    my $row = $schema->resultset('Test')->create({fixed_class=>$raw_json});
    $row->discard_changes;
    is($row->fixed_class->name,'sushi','name');
    is($row->fixed_class->ingredients->[1]->amount,'just enough','amount 2');
};

done_testing();
