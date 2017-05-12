# vi:filetype=

use t::DBQuery;

plan tests => 2 * blocks();

#no_diff();

run_tests();

__DATA__

=== TEST: DBQuery connect 
--- connect
--- args: 
--- db_user: root
--- db_pass: 
--- db_name: test
--- db_sock: /var/lib/mysql/mysql.sock
--- err
Can't find the module DBQuery or can't connect database, maybe dbuser and dbpass not match.
--- out
--- status: 1



