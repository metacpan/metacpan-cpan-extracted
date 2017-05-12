use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

my @methods = qw(
    _columns_index_for
    _compat_table
    _match_constraint
    _normalize_rel_arg
    _schemas_eq
    _table_indexes_info
);

my @accessors = qw(
    _rel_constraint
    _rel_exclude
);

my @classes = qw(
    DBIx::Class::Schema::Loader
    DBIx::Class::Schema::Loader::Base
    DBIx::Class::Schema::Loader::DBI
    DBIx::Class::Schema::Loader::DBI::ADO
    DBIx::Class::Schema::Loader::DBI::DB2
    DBIx::Class::Schema::Loader::DBI::Firebird
    DBIx::Class::Schema::Loader::DBI::Informix
    DBIx::Class::Schema::Loader::DBI::InterBase
    DBIx::Class::Schema::Loader::DBI::MSSQL
    DBIx::Class::Schema::Loader::DBI::mysql
    DBIx::Class::Schema::Loader::DBI::ODBC
    DBIx::Class::Schema::Loader::DBI::Oracle
    DBIx::Class::Schema::Loader::DBI::Pg
    DBIx::Class::Schema::Loader::DBI::SQLAnywhere
    DBIx::Class::Schema::Loader::DBI::SQLite
    DBIx::Class::Schema::Loader::DBI::Sybase
);

require DBIx::Class::Schema::Loader::DBI::RelPatterns;

can_ok('DBIx::Class::Schema::Loader::DBI::RelPatterns', @methods, @accessors);

foreach my $class (@classes) {
    eval "require $class; 1" or next;
    my $duplicates = 0;
    foreach my $method (@methods, @accessors) {
        next unless $class->can($method);
        $duplicates++;
        if ($ENV{SCHEMA_LOADER_TESTS_RELPATCOMPAT}) {
            fail("method should not exist: $class\::$method");
        } else {
            diag("duplicated method does actually exist: $class\::$method");
        }
    }
    if (!$duplicates || $ENV{SCHEMA_LOADER_TESTS_RELPATCOMPAT}) {
        is($duplicates, 0, "no duplicated methods in $class");
    }
}

my $relpat_base = 'DBIx::Class::Schema::Loader::DBI';
my $relpat_isa  = \@DBIx::Class::Schema::Loader::DBI::RelPatterns::ISA;

foreach my $method (@methods) {
    if ($relpat_base->can($method)) {
        diag("duplicated method does actually exist: $relpat_base\::$method");
        next;
    }
    
    my @tests = (
        "exception thrown when loader class method $method is duplicated" =>
            [ undef, \&throws_ok, qr/$method .* has super-method/ ],
        "override switch suppresses the exception for $method" =>
            [ {_relpat_override => 1}, \&lives_ok ],
        "inherit switch suppresses the exception and triggers $method inheritance" =>
            [ {_relpat_inherit => 1}, \&throws_ok, qr/I was inherited/ ],
    );
    
    while (@tests) {
        my $test_name = shift @tests;
        my ($options, $lives_or_throws, @args) = @{ shift @tests };
        $options ||= {};
        push @args, $test_name;
        $lives_or_throws->(sub {
            # to trigger the "security blanket" checks
            shift @$relpat_isa if @$relpat_isa && $relpat_isa->[0] ne $relpat_base;
            no strict 'refs';
            local *{"$relpat_base\::$method"} = sub {die "I was inherited\n"};
            make_schema(%$options,
                loader_class => 1,
                quiet => 0,
                warnings_exist => [
                    '/Multiple columns in .* quuxs .* for foos\.quuxid/',
                    '/Multiple tables .* for foos\.quuxid/',
                ],
                rel_constraint => [
                    # everything at once
                    qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
                    # nonsense, but should involve all possible methods
                    'foos.quuxid' => {tab=>qr/^(.*)s$/},
                ],
            );
        }, @args);
    }
}

done_testing();
