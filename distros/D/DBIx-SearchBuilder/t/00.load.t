use Test::More tests => 12;

BEGIN { use_ok("DBIx::SearchBuilder"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::Informix"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::mysql"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::mysqlPP"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::ODBC"); }

BEGIN {
    SKIP: {
        skip "DBD::Oracle is not installed", 1
          unless eval { require DBD::Oracle };
        use_ok("DBIx::SearchBuilder::Handle::Oracle");
    }
}
BEGIN { use_ok("DBIx::SearchBuilder::Handle::Pg"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::Sybase"); }
BEGIN { use_ok("DBIx::SearchBuilder::Handle::SQLite"); }
BEGIN { use_ok("DBIx::SearchBuilder::Record"); }
BEGIN { use_ok("DBIx::SearchBuilder::Record::Cachable"); }

