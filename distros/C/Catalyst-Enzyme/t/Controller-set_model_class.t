use strict;     
use Test::More tests => 4;
use Test::Exception;

use lib "t";
use TestAppSetup;
use_ok('Catalyst::Test', 'BookShelf');


my $html;




diag("Forward from Controller to another Controller");
ok($html = get("/format/add_genre"), "/format/add_genre ok");
like($html, qr/Add a new Genre/s, "  found title");

diag("Test controller_namespace");
like($html, qr|/genre/do_add|s, "  form action points to correct do_add");








__END__
