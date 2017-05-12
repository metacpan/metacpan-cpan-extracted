use strict;     
use Test::More tests => 7;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');

my $html;


diag("Check that AsForm works with related tables");
ok($html = get("/book/add"), "/book/add ok");
like($html, qr/In Shelf/s, "  Got Borrower name");

ok($html = get("/book/view/1"), "/book/view/1 ok");
like($html, qr/In Shelf/s, "  Got Borrower name");

ok($html = get("/book/edit/1"), "/book/edit/1 ok");
like($html, qr/In Shelf/s, "  Got Borrower name");




__END__
