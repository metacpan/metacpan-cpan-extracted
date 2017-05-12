package Role::PostgreSQL;

use Class::Load qw(try_load_class);

use Test::Roo::Role;
with 'Role::Database';

sub BUILD {
    my $self = shift;

    foreach my $module (qw/DateTime::Format::Pg DBD::Pg Test::PostgreSQL/) {
        try_load_class($module) or plan skip_all => "$module required";
    }

    eval { $self->database }
      or plan skip_all => "Init database failed: $@";
}

sub _build_database {
    my $self = shift;
    no warnings 'once'; # prevent: "Test::PostgreSQL::errstr" used only once
    my $pgsql = Test::PostgreSQL->new(
        initdb_args
          => $Test::PostgreSQL::Defaults{initdb_args}
             . ' --encoding=utf8 --no-locale'
    ) or die $Test::PostgreSQL::errstr;
    return $pgsql;
}

sub _build_dbd_version {
    return "DBD::Pg $DBD::Pg::VERSION Test::PostgreSQL $Test::PostgreSQL::VERSION";
}

sub connect_info {
    my $self = shift;
    return ( $self->database->dsn, undef, undef,
        {
            on_connect_do  => 'SET client_min_messages=WARNING;',
            pg_enable_utf8 => 1,
            quote_names    => 1,
        }
    );
}

sub _build_database_info {
    my $self = shift;
    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            @{ $dbh->selectrow_arrayref(q| SELECT version() |) }[0];
        }
    );
}

1;
