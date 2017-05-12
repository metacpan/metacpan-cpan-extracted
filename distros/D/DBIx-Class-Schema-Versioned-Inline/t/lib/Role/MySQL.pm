package Role::MySQL;

use Class::Load qw(try_load_class);

use Test::Roo::Role;
with 'Role::Database';

sub BUILD {
    my $self = shift;

    foreach my $module (qw/DateTime::Format::MySQL DBD::mysql Test::mysqld/) {
        try_load_class($module) or plan skip_all => "$module required";
    }

    eval { $self->database }
      or plan skip_all => "Init database failed: $@";
}

sub _build_database {
    my $self = shift;
    no warnings 'once';    # prevent: "Test::mysqld::errstr" used only once
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'character-set-server' => 'utf8',
            'collation-server'     => 'utf8_unicode_ci',
            'skip-networking'      => '',
        }
    ) or die $Test::mysqld::errstr;
    return $mysqld;
}

sub _build_dbd_version {
    my $self = shift;
    return
        "DBD::mysql $DBD::mysql::VERSION Test::mysqld "
      . "$Test::mysqld::VERSION mysql_clientversion "
      . $self->schema->storage->dbh->{mysql_clientversion};
}

sub connect_info {
    my $self = shift;
    return ( $self->database->dsn( dbname => 'test' ), undef, undef,
        {
            mysql_enable_utf8 => 1,
            on_connect_call   => 'set_strict_mode',
            quote_names       => 1,
        }
    );
}

sub _build_database_info {
    my $self = shift;
    $self->schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $variables = $dbh->selectall_arrayref(q(SHOW VARIABLES));
            my @info = map { $_->[0] =~ s/_server//; "$_->[0]=$_->[1]" } grep {
                $_->[0] =~ /^(version|character_set_server|collation_server)/
                  && $_->[0] !~ /compile/
            } @$variables;
            return join( " ", @info );
        }
    );
}

1;
