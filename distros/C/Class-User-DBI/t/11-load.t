## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use_ok('Class::User::DBI::DB'            )     || print "Bail out!\n";
    use_ok('Class::User::DBI'                )     || print "Bail out!\n";
    use_ok('Class::User::DBI::Roles'         )     || print "Bail out!\n";
    use_ok('Class::User::DBI::Privileges'    )     || print "Bail out!\n";
    use_ok('Class::User::DBI::Domains'       )     || print "Bail out!\n";
    use_ok('Class::User::DBI::RolePrivileges')     || print "Bail out!\n";
    use_ok('Class::User::DBI::UserDomains'   )     || print "Bail out!\n";
}

diag("Testing Class::User::DBI $Class::User::DBI::VERSION, Perl $], $^X");
