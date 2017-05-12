use strict;
use Test::More tests => 3;

BEGIN {
    use_ok 'DBIx::Class::Loader';
  SKIP: {
        use_ok 'DBIx::Class::Loader::mysql';
    }
  SKIP: {
        use_ok 'DBIx::Class::Loader::Pg';
    }
}
