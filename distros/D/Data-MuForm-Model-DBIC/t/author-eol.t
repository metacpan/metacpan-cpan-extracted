
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Data/MuForm/Model/DBIC.pm',
    'lib/Data/MuForm/Role/Model/DBIC.pm',
    't/00create_db.t',
    't/01-app.t',
    't/02-book.t',
    't/03-author.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/db/bookdb.sql',
    't/db_has_many.t',
    't/db_init_obj.t',
    't/db_options.t',
    't/lib/BookDB.pm',
    't/lib/BookDB/Form/Author.pm',
    't/lib/BookDB/Form/AuthorOld.pm',
    't/lib/BookDB/Form/Book.pm',
    't/lib/BookDB/Form/Book2PK.pm',
    't/lib/BookDB/Form/BookHTML.pm',
    't/lib/BookDB/Form/BookM2M.pm',
    't/lib/BookDB/Form/BookView.pm',
    't/lib/BookDB/Form/BookWithOwner.pm',
    't/lib/BookDB/Form/BookWithOwnerAlt.pm',
    't/lib/BookDB/Form/Borrower.pm',
    't/lib/BookDB/Form/BorrowerX.pm',
    't/lib/BookDB/Form/Field/AltText.pm',
    't/lib/BookDB/Form/Field/Book.pm',
    't/lib/BookDB/Form/Role/BookOwner.pm',
    't/lib/BookDB/Form/User.pm',
    't/lib/BookDB/Schema.pm',
    't/lib/BookDB/Schema/Result/Address.pm',
    't/lib/BookDB/Schema/Result/Author.pm',
    't/lib/BookDB/Schema/Result/AuthorBooks.pm',
    't/lib/BookDB/Schema/Result/AuthorOld.pm',
    't/lib/BookDB/Schema/Result/Book.pm',
    't/lib/BookDB/Schema/Result/Book2PK.pm',
    't/lib/BookDB/Schema/Result/BooksGenres.pm',
    't/lib/BookDB/Schema/Result/Borrower.pm',
    't/lib/BookDB/Schema/Result/Country.pm',
    't/lib/BookDB/Schema/Result/Employer.pm',
    't/lib/BookDB/Schema/Result/Format.pm',
    't/lib/BookDB/Schema/Result/Genre.pm',
    't/lib/BookDB/Schema/Result/License.pm',
    't/lib/BookDB/Schema/Result/Options.pm',
    't/lib/BookDB/Schema/Result/User.pm',
    't/lib/BookDB/Schema/Result/UserEmployer.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
