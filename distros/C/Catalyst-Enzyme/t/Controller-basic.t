use strict;     
use Test::More tests => 16;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');


my $html;
my @column_names;
my $res;


diag("Redirect/forward from / to /book/list");
$res = request("/");
ok($res->is_redirect, "Redirect ok");
is($res->header("Location"), "/book", "Redirect to /book");



diag("Check column existance and naming (/book/list)");
ok($html = get("/book/list"), "GET /book/list ok");
@column_names = qw/
                   Borrower Author Genre Format Borrowed Title ISBN
                   Publisher Year Pages
                   /;
for my $name (@column_names) {
    like($html, qr/Borrower/, "Colname ($name) ok");
}



diag("Check column existance and naming (/genre/list)");
ok($html = get("/genre/list"), "GET /genre/list ok");
@column_names = qw/ Name /;
for my $name (@column_names) {
    like($html, qr/Borrower/, "Colname ($name) ok");
}




__END__
