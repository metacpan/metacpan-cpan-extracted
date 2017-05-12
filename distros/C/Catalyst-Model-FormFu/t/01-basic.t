use strict;
use warnings;

use rlib;
use Test::Most;
use Catalyst::Test 'FormFu';

my ($res, $c) = ctx_request('/book?title=Test');

my $formfu = $c->model('FormFu');

isa_ok($formfu, 'HTML::FormFu::Library');

my $book = $formfu->form('book');
my $author = $formfu->form('author');
my ($raw_book, $raw_author) = $formfu->raw_form(qw(book author));

isa_ok ( $book, 'HTML::FormFu' );
isa_ok ( $author, 'HTML::FormFu' );
isa_ok ( $raw_book, 'HTML::FormFu' );
isa_ok ( $raw_author, 'HTML::FormFu' );

ok ($book->submitted, 'book form is submitted');
ok (!$author->submitted, 'author form is not submitted');

ok ($book->submitted_and_valid, 'book form is submitted and valid');

is($book->param_value('title'), 'Test', 'book form is not processed');
is($raw_book->param_value('title'), undef, 'raw book form is not processed');

done_testing;
