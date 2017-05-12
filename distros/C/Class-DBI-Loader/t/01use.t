use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'Class::DBI::Loader';
  SKIP: {
        eval { require Class::DBI::mysql; };
        skip "Class::DBI::mysql not found", 1 if $@;
        use_ok 'Class::DBI::Loader::mysql';
    }
  SKIP: {
        eval { require Class::DBI::Pg; };
        skip "Class::DBI::Pg not found", 1 if $@;
        use_ok 'Class::DBI::Loader::Pg';
    }
}
