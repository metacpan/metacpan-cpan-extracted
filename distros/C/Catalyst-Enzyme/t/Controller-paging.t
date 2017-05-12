use strict;     
use Test::More tests => 17;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');


my $html;


diag("Check paging");
ok($html = get("/genre/list"), "/genre/list ok");
is((() = $html =~ m|/genre/edit/\d+|sg) + 0, 3, " Found 3 rows (links to edit)");

is(() = $html =~ m|class="pager_previous"|sg + 0, 1, " Found 1 nonlinked previous");
is((() = $html =~ m|class="pager_current_page"|sg) + 0, 1, " Found 1 current page");
is((() = $html =~ m|class="pager_other_page_link"|sg) + 0, 1, " Found 1 other page");
is((() = $html =~ m|class="pager_next_link"|sg) + 0, 1, " Found 1 linked next");


ok($html = get("/genre/list?page=2"), "/genre/list page 2 ok");
is((() = $html =~ m|/genre/edit/\d+|sg) + 0, 2, " Found 2 rows (links to edit)");

is((() = $html =~ m|class="pager_previous_link"|sg) + 0, 1, " Found 1 linked previous");
is((() = $html =~ m|class="pager_current_page"|sg) + 0, 1, " Found 1 current page");
is((() = $html =~ m|class="pager_other_page_link"|sg) + 0, 1, " Found 1 other page");
is((() = $html =~ m|class="pager_next"|sg) + 0, 1, " Found 1 nonlinked next");


ok($html = get("/genre/list?page=3"), "/genre/list page 3 (doesn't exist) ok");
is((() = $html =~ m|/genre/edit/\d+|sg) + 0, 2, " Found 2 rows (links to edit)");

ok($html = get("/genre/list?page=0"), "/genre/list page 0 (doesn't exist) ok");
is((() = $html =~ m|/genre/edit/\d+|sg) + 0, 3, " Found 3 rows (links to edit)");




__END__
