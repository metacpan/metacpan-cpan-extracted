package DB::SQL::Migrations;

use 5.010000;
use Mojo::Base -base;
use File::Basename;
use DBIx::MultiStatementDo;
use File::Slurp;

our $VERSION = '0.07';

has [qw( dbh migrations_directory  )];
has schema_migrations_table => sub { 'schema_migrations' };
has schema_migrations_name_field => sub { 'name' };
has schema_migrations_date_field => sub { 'date_applied' };

has _applied_migrations => sub {
  my $self = shift;
  my %applied_migrations;

  my $sth = $self->dbh->prepare("SELECT " .$self->schema_migrations_name_field . ", ". $self->schema_migrations_date_field ." FROM ". $self->schema_migrations_table );
  $sth->execute();
  $sth->bind_columns( \my ( $name, $date_applied ) );
  while ( $sth->fetch() ) {
      $applied_migrations{$name} = $date_applied;
  }
  $sth->finish;

  return \%applied_migrations;
};

sub _pending_migrations {
  my $self = shift;
  my @pending_migrations;

  foreach my $migration_file( $self->_migration_files_in_order ) {
    my $migration_key = $self->_migration_key($migration_file);
    push @pending_migrations, $migration_file unless exists $self->_applied_migrations->{$migration_key};
  }

  foreach my $pending_migration(@pending_migrations) {
    print "$pending_migration is pending\n";
  }

  return @pending_migrations;
}

sub apply {
  my $self = shift;

  my @pending_migrations = $self->_pending_migrations;

  if(scalar(@pending_migrations)) {

    foreach my $migration(@pending_migrations) {
      $self->_apply_migration($migration);
    }
  }
  else {
    print "Up to date\n";
  }   
}

sub _apply_migration {
  my $self = shift;
  my $file_name = shift;

  my $sql = read_file($file_name);
  my $batch = DBIx::MultiStatementDo->new(
      dbh      => $self->dbh,
      rollback => 0
  );
  $batch->dbh->{AutoCommit} = 0;
  $batch->dbh->{RaiseError} = 1;

  eval {
    $batch->do( $sql );
    $batch->dbh->commit;
    1
  } or do { 
    print "$@ \n";
    eval { $batch->dbh->rollback };
    print "Failed to apply migration: $file_name\n";

    die "Exiting due to failed migrations \n";
  };

  $self->_insert_into_schema_migrations($file_name);     

  print "Applied migration $file_name \n";
}

sub _insert_into_schema_migrations {
  my $self = shift;
  my $migration = shift;
  my $migration_key = $self->_migration_key($migration);

  $self->dbh->do("INSERT INTO ". $self->schema_migrations_table ." (". $self->schema_migrations_name_field .", ". $self->schema_migrations_date_field .") VALUES (?,NOW())", undef, $migration_key );
  $self->dbh->commit;
}

sub _migration_files_in_order {
  my $self = shift;
  my $dir = $self->migrations_directory;

  return sort <$dir/*.sql>;
}

sub create_migrations_table {
  my $self = shift;
  my $table_name = $self->schema_migrations_table;
  my $name_field = $self->schema_migrations_name_field;
  my $date_field = $self->schema_migrations_date_field;

  my $sql = "CREATE TABLE IF NOT EXISTS $table_name (
                $name_field varchar(255) NOT NULL PRIMARY KEY,
                $date_field datetime NOT NULL
             );   
  ";

  $self->dbh->do($sql);
}

sub _migration_key {
  my $self = shift;
  my $migration_file = shift;

  #Use filename for the key
  my($filename, $directories, $suffix) = fileparse($migration_file);
  return $filename;
}

1;
__END__

=head1 NAME

DB::SQL::Migrations - apply database migrations via scripts in a directory

=head1 SYNOPSIS

  use DB::SQL::Migrations;
  my $migrator = DB::SQL::Migrations->new( dbh => $some_db_handle,
                                           migrations => $some_path,                                        
   )

  $migrator->create_migrations_table(); #creates schema table if it doesn't exist
  $migrator->apply(); 

=head1 DESCRIPTION

Run a number of small SQL scripts

=head1 REPOSITORY

L<https://github.com/jontaylor/DB-SQL-Migrations>

=head1 AUTHOR

Adam Omielan, E<lt>adam@assure24.comE<gt>
Jonathan Taylor, E<lt>jon@stackhaus.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jonathan Taylor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
