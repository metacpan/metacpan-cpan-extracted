use 5.012;
use XS::Install;

write_makefile(
    NAME          => "DBIx::Class::DynamicSubclass",
    PREREQ_PM     => {
        'DBIx::Class' => 0.07003,
    },
    TEST_REQUIRES => {
        'DBD::SQLite' => 1.13,
        'SQL::Translator' => 0.08
    },
);

