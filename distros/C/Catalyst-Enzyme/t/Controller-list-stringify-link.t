use strict;     
use Test::More tests => 4;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');



my $html;

diag("Check for link on stringify column");
ok($html = get("/borrower/list"), "GET /borrower/list ok");
like($html, qr|/borrower/view/1">In Shelf</a>|si, "  Link to 1 ok");
like($html, qr|/borrower/view/2">Ole Oyvind Hove</a>|si, "  Link to 2 ok");



__END__
