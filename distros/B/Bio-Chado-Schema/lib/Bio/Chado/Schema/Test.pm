package Bio::Chado::Schema::Test;
BEGIN {
  $Bio::Chado::Schema::Test::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Test::VERSION = '0.20000';
}
use strict;
use warnings;
use Carp::Clan qr/^Bio::Chado::Schema/;
use Bio::Chado::Schema;

=head1 NAME

Bio::Chado::Schema::Test - Library to be used by Bio::Chado::Schema test scripts.

=head1 SYNOPSIS

  use lib qw(t/lib);
  use Bio::Chado::Schema::Test;
  use Test::More;

  my $schema = Bio::Chado::Schema::Test->init_schema();

=head1 DESCRIPTION

This module provides the basic utilities to write tests against Bio::Chado::Schema.

=head1 METHODS

=head2 init_schema

  my $schema = Bio::Chado::Schema::Test->init_schema(
    deploy            => 1,
    populate          => 1,
    storage_type      => '::DBI::Replicated',
    storage_type_args => {
      balancer_type=>'DBIx::Class::Storage::DBI::Replicated::Balancer::Random'
    },
  );

This method removes the test SQLite database in t/var/BCS.db
and then creates a new, empty database.

This method will call deploy_schema() by default, unless the
deploy flag is set to 0.

This method will call populate_schema() if the populate argument
is set to a true value.

=cut

=head2 has_custom_dsn

Returns true if the BCS_TEST_DSN environment variable is set.

=cut

sub has_custom_dsn {
    return $ENV{"BCS_TEST_DSN"} ? 1 : 0;
}

sub _sqlite_dbfilename {
    return "t/var/BCS.db";
}

sub _sqlite_dbname {
    my $self = shift;
    my %args = @_;
    return $self->_sqlite_dbfilename; # if $args{sqlite_use_file} or $ENV{"BCS_SQLITE_USE_FILE"};
    return ":memory:";
}

sub _database {
    my $self = shift;
    my %args = @_;
    my $db_file = $self->_sqlite_dbname(%args);

    #warn "Removing $db_file";
    #unlink($db_file) if -e $db_file;
    #unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn    = $ENV{"BCS_TEST_DSN"} || "dbi:SQLite:${db_file}";
    my $dbuser = $ENV{"BCS_TEST_DBUSER"} || '';
    my $dbpass = $ENV{"BCS_TEST_DBPASS"} || '';

    my @connect_info = ($dsn, $dbuser, $dbpass, { AutoCommit => 1, %args });

    return @connect_info;
}

sub init_schema {
    my $self = shift;
    my %args = @_;
    my $should_deploy = $ENV{"BCS_TEST_DSN"} ? 0 : 1 ;

    my $schema;

    if ($args{compose_connection}) {
      $schema = Bio::Chado::Schema->compose_connection(
                  'Bio::Chado::Schema::Test', $self->_database(%args)
                );
    } else {
      $schema = Bio::Chado::Schema->compose_namespace('Bio::Chado::Schema::Test');
    }

    if ($args{storage_type}) {
      $schema->storage_type($args{storage_type});
    }

    $schema = $schema->connect($self->_database(%args));
    $schema->storage->on_connect_do(['PRAGMA synchronous = OFF']) unless $self->has_custom_dsn;

    unless ( -e _sqlite_dbfilename() ) {
        __PACKAGE__->deploy_schema( $schema, $args{deploy_args} ) if $should_deploy;
        __PACKAGE__->populate_schema( $schema ) if $args{populate};
    }
    return $schema;
}

=head2 deploy_schema

  Bio::Chado::Schema::Test->deploy_schema( $schema );

This method does one of two things to the schema.  It can either call
the experimental $schema->deploy() if the BCSTEST_SQLT_DEPLOY environment
variable is set, otherwise the default is to read in the t/lib/sqlite.sql
file and execute the SQL within. Either way you end up with a fresh set
of tables for testing.

=cut

sub deploy_schema {
    my $self = shift;
    my $schema = shift;
    my $args = shift || {};

    $schema->deploy($args);
    return;
}

=head2 populate_schema

  Bio::Chado::Schema::Test->populate_schema( $schema );

After you deploy your schema you can use this method to populate
the tables with test data.

=cut

sub populate_schema {
    my $self = shift;
    my $schema = shift;

#    $schema->populate('Genre', [
#      [qw/genreid name/],
#      [qw/1        emo/],
#    ]);

}

1;
