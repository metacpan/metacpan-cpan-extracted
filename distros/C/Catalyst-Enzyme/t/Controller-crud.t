use strict;     
use Test::More tests => 22;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');


my $html;
my $res;
my $item_name = "test_" . int(rand(10_000));
my $item_id;




#todo: view

#todo: view missing id


diag("Test C add");
ok($html = get("/format/list"), "/format/list ok");
isnt($html, qr/$item_name/, "  Doesn't contain item_name");


diag("Simple add");
ok($res = request("/format/do_add?name=$item_name"), "/format/add");
ok($res->is_redirect, "Redirect ok");
ok($res->header("Location") =~ m|format/view/(\d+)|, "Redirected to view/id");
ok($item_id = $1, " got id");
diag("Got id ($item_id)");

diag("View");
ok($html = get("/format/view/$item_id"), "/format/view/id");
like($html, qr|<span class="item_data">\s*$item_name\s*</span>|si, " contains name");



diag("Fail add due to unique constraint");
ok($res = request("/format/do_add?name=$item_name"), "/format/add");
ok(!$res->is_redirect, " Not redirect");
like($res->content, qr|<div class="message">Could not create record</div>|s, " Page contains message");
like($res->content, qr|<div class="error">|s, " Page contains some error");

like($res->content, qr|<input name="name" type="text" value="$item_name">|s, " Page contains refilled input");



#todo: edit

#todo: do_edit

#todo: do_edit missing




diag("Simple delete");

ok($html = get("/format/delete/$item_id"), "/format_delete");
like($html, qr|Delete Format|s, " Page contains title");
like($html, qr|<input type="submit" value="Delete"/>|s, " Page contains delete button");

ok($res = request("/format/do_delete/$item_id"), "/format/destroy");
ok($res->is_redirect, "Redirect ok");
like($res->header("Location"), qr|/format/list|s, "Redirected to list");

diag("View");
ok($html = get("/format/view"), "/format/view/id");
unlike($html, qr|$item_name|, " doesn't contains name");


#todo: delete missing id





__END__
