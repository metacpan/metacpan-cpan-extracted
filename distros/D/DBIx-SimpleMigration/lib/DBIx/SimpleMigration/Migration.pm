package DBIx::SimpleMigration::Migration;

use 5.10.0;
use strict;
use warnings;

use Carp;
use File::Basename;
use SQL::SplitStatement;

our $VERSION = '1.0.2';

sub new {
  my $self = bless {}, shift;

  return unless @_ % 2 == 0;
  my %args = @_;

  croak __PACKAGE__ . '->new: file option missing or does not exist'
    unless ($args{file} && -f $args{file});

  croak __PACKAGE__ . '->new: client missing' unless $args{client};

  $self->{_client} = $args{client};

  ($self->{_key}) = fileparse($args{file});

  my $contents;
  {
    local $/ = undef;
    open FH, '<', $args{file} or croak __PACKAGE__ . '->new: Error opening file: ' . $!;
    $contents = <FH>;
    close FH;
  }

  my $splitter = SQL::SplitStatement->new;
  my @statements = $splitter->split($contents);

  $self->{_statements} = \@statements;

  return $self;
}

sub apply {
  my ($self) = @_;

  say 'Applying ' . $self->{_key};

  if (!$self->{_client}->_lock_migrations_table) {
    die 'Error acquiring table lock';
  }

  eval {
    foreach my $query (@{$self->{_statements}}) {
      $self->{_client}->{dbh}->do($query)
    }
  };

  if ($@) {
    $self->{_client}->{dbh}->rollback or croak __PACKAGE__ . '->apply: Error rolling back transaction: ' . $self->{_client}->{dbh}->errstr;
    croak __PACKAGE__ . '->apply: Error applying changeset';
  }

  if (!$self->{_client}->_insert_migration($self->{_key})) {
    $self->{_client}->{dbh}->rollback;
    croak;
  }

  $self->{_client}->{dbh}->commit;
}

1;

__END__
=encoding utf-8
=head1 NAME

DBIx::SimpleMigration::Migration

=head1 DESCRIPTION

This handles loading the SQL file for the migration, parses it with L<SQL::SplitStatement> and then uses L<DBIx::SimpleMigration::Client> to apply it to the cloned L<DBI> handle.

This tries to be as safe as possible, see DBIx::SimpleMigration::Client for more documentation.

=cut
