use strict;     
use Test::More tests => 11;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');

use_ok('BookShelf::Model::BookShelfDB::Borrower');
use_ok('BookShelf::Model::BookShelfDB::Genre');



my $pkg = "BookShelf::Model::BookShelfDB::Borrower";

is_deeply([ $pkg->list_columns() ], [qw/ name email url /], "Defined columns: list ");
is_deeply([ $pkg->view_columns() ], [qw/ name email url phone /], "Defined columns: view");
is_deeply([ $pkg->edit_columns() ], [qw/ name email url phone /], "Edit (default view) columns: view");
is_deeply([ $pkg->named_columns("list_columns") ], [qw/ name email url /], "Defined columns: list");


$pkg = "BookShelf::Model::BookShelfDB::Genre";
is_deeply([ $pkg->list_columns() ], [qw/ name /], "Default columns: list ");
is_deeply([ $pkg->view_columns() ], [qw/ name /], "Defined columns: view");
is_deeply([ $pkg->edit_columns() ], [qw/ name /], "Defined columns: view");
is_deeply([ $pkg->named_columns("list_columns") ], [qw/ name /], "Defined columns: list");



__END__
