use strict;     
use Test::More tests => 17;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');



my $html;

diag("Check for links to related tables - list");
ok($html = get("/book/list"), "GET /book/list ok");
like($html, qr|/genre/view/5">Fantasy</a>|si, "  Link genre");
like($html, qr|/genre/view/3">Mystery</a>|si, "  Link genre");

like($html, qr|/borrower/view/1">In Shelf</a>|si, "  Link borrower");
like($html, qr|/borrower/view/2">Ole Oyvind Hove</a>|si, "  Link borrower");



diag("Check for links to related tables - view");
ok($html = get("/book/view/1"), "GET /book/view/1 ok");

like($html, qr|/genre/list">Genre</a>|si, "  Link genre list");
like($html, qr|/genre/view/5">Fantasy</a>|si, "  Link genre view");

like($html, qr|/borrower/list">Borrower</a>|si, "  Link borrower list");
like($html, qr|/borrower/view/1">In Shelf</a>|si, "  Link borrower view");

like($html, qr|/format/list">Format</a>|si, "  Link format list");
like($html, qr|/format/view/1">Paperback</a>|si, "  Link format view");



diag("Check for links to related tables - edit");
ok($html = get("/book/edit/1"), "GET /book/edit/1 ok");

like($html, qr|/genre/list">Genre</a>|si, "  Link genre list");

like($html, qr|/borrower/list">Borrower</a>|si, "  Link borrower list");

like($html, qr|/format/list">Format</a>|si, "  Link format list");




__END__
