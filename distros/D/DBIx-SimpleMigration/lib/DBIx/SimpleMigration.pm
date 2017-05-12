package DBIx::SimpleMigration;

use 5.10.0;
use strict;
use warnings;

use Carp;
use File::Basename;

use DBIx::SimpleMigration::Client;
use DBIx::SimpleMigration::Migration;

our $VERSION = '1.0.2';

sub new {
  my $self = bless {}, shift;
  return unless @_ % 2 == 0;
  my %args = @_;

  croak __PACKAGE__ . '->new: dbh option missing or not a DBI object'
    unless ($args{dbh} && ref($args{dbh}) eq 'DBI::db');

  croak __PACKAGE__ . '->new: source dir missing or does not exist'
    unless ($args{source} && -d $args{source});

  $self->{_source} = $args{source};

  my %options = (
    migrations_table => 'migrations',
    migrations_schema => 'simplemigration',
  );

  if ($args{options}) {
    # http://stackoverflow.com/questions/350018/how-can-i-combine-hashes-in-perl
    @options{keys %{$args{options}}} = values %{$args{options}};
  }
  $self->{_options} = \%options;

  my $class = 'DBIx::SimpleMigration::Client::' . $args{dbh}->{Driver}->{Name};
  eval "require $class; $class->import";
  if ($@) {
    $class = 'DBIx::SimpleMigration::Client';
  }

  $self->{_client} = $class->new(
    dbh => $args{dbh}->clone({
      AutoCommit => 0,
      RaiseError => 1
    }), # new handle with AutoCommit off
    options => \%options
  );

  return $self;
}

sub apply {
  my ($self) = @_;

  if (!$self->{_client}->_migrations_table_exists) {
    $self->{_client}->_create_migrations_table;
  }

  my $dir = $self->{_source};
  my @files = sort <$dir/*.sql>;

  my $applied_migrations = $self->{_client}->_applied_migrations;

  foreach my $file (@files) {
    my ($filename) = fileparse($file);
    next if exists $applied_migrations->{$filename};

    my $migration = DBIx::SimpleMigration::Migration->new(
      client => $self->{_client},
      file => $file
    );

    $migration->apply;
  }

  $self->{_client}->{dbh}->disconnect if $self->{_client}->{dbh};
}

1;

__END__
=encoding utf-8
=head1 NAME

DBIx::SimpleMigration - extremely simple DBI migrations

=head1 DESCRIPTION

This is a very simple module to simplify schema updates in a larger application. This will scan a directory of SQL files and execute them on a supplied L<DBI> handle. Files are executed in order and inside transactions for safety. The module will create a table to track progress so new releases can add migrations as a SQL file and this will only deploy what is required.

=head3 Wait! Is this the right tool?

Be sure this is the right tool for you. This is incredibly simple and doesn't have any verification or rollback capabilities. Before you use this, look at L<App::Sqitch|http://sqitch.org> or L<DBIx::Class::Migration> as they're probably better choices.

=head1 SYNOPSIS

  use DBI;
  use DBIx::SimpleMigration;

  my $dbh = DBI->connect(...);
  my $migration = DBIx::SimpleMigration->new(
    source => './sql/',
    dbh => $dbh
  );

  eval { $migration->apply };
  if ($@) {
    # some error happened
  }

DBIx::SimpleMigration will die on error so if that's unacceptable for your use case, make sure to wrap in an C<eval>.

=head1 CONTRIBUTING

I primarily use PostgreSQL so that's the driver getting the most attention. Happy to take suggestions but if you're using another DBI driver and want locking or better support, feel free to create a ::Client::$driver package and send over a PR.

=head1 SUPPORT

Questions, bugs, feedback are all welcome. Just create an issue under this project.

=head1 AUTHOR

Cameron Daniel E<lt>cam.daniel@gmail.comE<gt>

=cut
