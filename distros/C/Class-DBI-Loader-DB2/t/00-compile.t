use strict;
use Test::More tests => 2;

BEGIN { 
    use_ok 'Class::DBI::Loader';

 SKIP: {
	eval {
	    require Class::DBI::DB2;
	};
	skip "Class::DBI::DB2 not found", 1 if $@;
	use_ok 'Class::DBI::Loader::DB2';
    }

}
