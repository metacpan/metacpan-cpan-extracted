use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DBIx::Class::Visualizer;
use TestFor::DbicVisualizer::Schema;

my $schema = TestFor::DbicVisualizer::Schema->connect;

subtest standard => sub {
    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema);
    my $result_handler = $vis->result_handler('Author');

    my @relations = $result_handler->get_relations('author_id');

    my $book_author_relation = (grep { $_->destination_table eq 'BookAuthor'} @relations)[0];
    my $author_thing_relation = (grep { $_->destination_table eq 'AuthorThing'} @relations)[0];

    is $book_author_relation->relation_type, 'has_many', 'Correct relation type';
    ok $book_author_relation->added_to_graph, 'Relation is added';
    is $vis->result_handler('BookAuthor')->get_relation_between('author_id', 'Author', 'author_id')->relation_type, 'belongs_to', 'Correct reverse relation type';

    is $author_thing_relation->arrow_type, 'vee', 'Correct arrow type';
};

subtest wanted => sub {
    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema, wanted_result_source_names => ['Author'], degrees_of_separation => 1);
    my $result_handler = $vis->result_handler('Author');

    my @relations = $result_handler->get_relations('author_id');
    my $book_author_relation = (grep { $_->destination_table eq 'BookAuthor'} @relations)[0];
    is $book_author_relation->relation_type, 'has_many', 'Correct relation type';
    ok $book_author_relation->added_to_graph, 'Relation is added';

    my $book_handler = $vis->result_handler('Book');
    my @book_relations = $book_handler->get_relations('book_id');

    ok !$book_relations[0]->added_to_graph, 'Relation from unwanted result source not added';
};
subtest skipped => sub {
    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema, skip_result_source_names => ['Book'], degrees_of_separation => 10);
    my $result_handler = $vis->result_handler('Author');

    my @relations = $result_handler->get_relations('author_id');
    my $book_author_relation = (grep { $_->destination_table eq 'BookAuthor'} @relations)[0];
    is $book_author_relation->relation_type, 'has_many', 'Correct relation type';
    ok $book_author_relation->added_to_graph, 'Relation is added';

    my $book_handler = $vis->result_handler('Book');
    my @book_relations = $book_handler->get_relations('book_id');

    ok !$book_relations[0]->added_to_graph, 'Relation from skipped result source not added';
};
subtest svg => sub {
    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema);
    my $svg = $vis->svg;
    like $svg, qr/<title>Book</, 'SVG appears rendered correctly';
};
subtest only_keys => sub {
    plan skip_all => 'Mojolicious not installed' if $@;

    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema, only_keys => 1);
    my $svg = $vis->svg;
    unlike $svg, qr/birth_date/, 'Non-key column excluded';
};
subtest transformed_svg => sub {
    eval { require Mojolicious };
    plan skip_all => 'Mojolicious not installed' if $@;

    my $vis = DBIx::Class::Visualizer->new(logger_conf => [], schema => $schema);
    my $svg = $vis->transformed_svg;
    like $svg, qr/data-column-name="book_id"/, 'SVG appears to have transformed correctly';
};
done_testing;
