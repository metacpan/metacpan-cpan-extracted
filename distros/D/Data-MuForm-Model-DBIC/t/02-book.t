use strict;
use warnings;
use Test::More;
use lib 't/lib';

use_ok( 'Data::MuForm::Model::DBIC' );

use_ok( 'BookDB::Form::Book');

use_ok( 'BookDB::Schema');

my $schema = BookDB::Schema->connect('dbi:SQLite:t/db/book.db');
ok($schema, 'get db schema');

my $model = $schema->resultset('Book')->new_result({});
my $form = BookDB::Form::Book->new;

ok( !$form->process( model => $model ), 'Empty data' );

# check authors options
my $author_options = $form->field('authors')->options;
is( $author_options->[0]->{label}, 'J.K. Rowling', 'right author name');

my $borrower_options = $form->field('borrower')->options;
is( $borrower_options->[1]->{label}, 'John Doe <john@gmail.com>', 'right borrower name');

# This is munging up the equivalent of param data from a form
my $params = {
    'title' => 'How to Test Perl Form Processors',
    'authors' => [5],
    'genres' => [2, 4],
    'format'       => 2,
    'isbn'   => '123-02345-0502-2' ,
    'publisher' => 'EreWhon Publishing',
    'user_updated' => 1,
    'borrower' => '',
    'pages' => '',
    'year' => '',
};

ok( $form->process( model => $model, params => $params ), 'Good data' );

my $book = $form->model;
END { $book->delete };

ok ($book, 'get book object from form');

is_deeply( $form->fif, $params, 'fif correct' );
$params->{$_} = undef for qw/ year pages borrower/;
is_deeply( $form->values, $params, 'values correct' );

my $num_genres = $book->genres->count;
is( $num_genres, 2, 'multiple select list updated ok');

is( $form->field('format')->value, 2, 'get value for format' );

$params->{genres} = 2;
ok( $form->process( model => $book, params => $params), 'handle one value for multiple select' );
is_deeply( $form->field('genres')->value, [2], 'right value for genres' );

$params->{authors} = [];
$params->{genres} = [2,4];
$form->process( model => $book, params => $params);

is( $form->field('authors')->filled_from, 'params', 'authors filled from params' );
is_deeply( $form->field('authors')->value, [], 'authors value right in form');

is( $form->field('publisher')->value, 'EreWhon Publishing', 'right publisher');

my $value_hash = { %{$params},
                   authors => [],
                   year => undef,
                   pages => undef,
                   borrower => undef,
                 };
delete $value_hash->{submit};
is_deeply( $form->values, $value_hash, 'get right values from form');

my $bad_1 = {
    notitle => 'not req',
    silly_field   => 4,
};

ok( !$form->process( model => $book, params => $bad_1 ), 'bad 1' );

$form = BookDB::Form::Book->new(model => $book, schema => $schema);
ok( $form, 'create form from db object');

my $genres_field = $form->field('genres');
is_deeply( sort $genres_field->value, [2, 4], 'value of multiple field is correct');

my $bad_2 = {
    'title' => "Another Silly Test Book",
    'authors' => [6],
    'year' => '1590',
    'pages' => 'too few',
    'format' => '22',
};

ok( !$form->process( $bad_2 ), 'bad 2');
ok( $form->field('year')->has_errors, 'year has error' );
ok( $form->field('pages')->has_errors, 'pages has error' );
ok( !$form->field('authors')->has_errors, 'author has no error' );
ok( $form->field('format')->has_errors, 'format has error' );

my $values = $form->value;
$values->{year} = 1999;
$values->{pages} = 101;
$values->{format} = 2;
my $validated = $form->check( model => $book, params => $values );
ok( $validated, 'now form validates' );

$form->process( model => $book, params => {} );
is( $book->publisher, 'EreWhon Publishing', 'publisher has not changed');

# test that multiple fields (genres) with value of [] deletes genres
is( $book->genres->count, 2, 'multiple select list updated ok');
$params->{genres} = [];
$form->process( model => $book, params => $params );
is( $book->genres->count, 0, 'multiple select list has no selected options');


done_testing;
