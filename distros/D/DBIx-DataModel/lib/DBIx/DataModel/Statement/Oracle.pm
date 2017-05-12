#----------------------------------------------------------------------
package DBIx::DataModel::Statement::Oracle;
#----------------------------------------------------------------------
use strict;
use warnings;
no strict 'refs';

use parent      qw/DBIx::DataModel::Statement/;
use mro         qw/c3/;
use DBD::Oracle 1.62 qw/:ora_fetch_orient :ora_exe_modes/;
use Carp;

sub sqlize {
  my ($self, @args) = @_;

  # merge new args into $self->{args}
  $self->refine(@args) if @args;

  # reorganize pagination (code copied from SQL::Abstract::More), in order
  # to capture all cases of limit/offset
  my $page_index = delete $self->{args}{-page_index};
  my $page_size  = delete $self->{args}{-page_size};
  if ($page_index || $page_size) {
    not exists $self->{args}{$_} or croak "-page_size conflicts with $_"
      for qw/-limit -offset/;
    $self->{args}{-limit} = $page_size;
    if ($page_index) {
      $self->{args}{-offset} = ($page_index - 1) * $page_size;
    }
  }

  # remove -limit and -offset from args; they will be handled later in
  # prepare() and execute(), see below
  $self->{_ora_limit}  = delete $self->{args}{-limit};
  $self->{offset}      = delete $self->{args}{-offset};

  # if there is an offset, we must ask for a scrollable statement
  $self->refine(-prepare_attrs => 
                  {ora_exe_mode => OCI_STMT_SCROLLABLE_READONLY})
     if $self->{offset};

  return $self->next::method();
}


# recompute page size/index from limit/offset
sub page_size   { my $self = shift;
                  $self->{_ora_limit}  || POSIX::LONG_MAX            }
sub page_index  { my $self = shift;
                  int(($self->{offset} || 0) / $self->page_size) + 1 }



sub execute {
  my ($self, @args) = @_;
  $self->next::method(@args);

  # go to initial offset, if needed 
  if ($self->{offset}) {
    $self->{sth}->ora_fetch_scroll(OCI_FETCH_ABSOLUTE, $self->{offset});
    $self->{row_num} = $self->{offset};
  }
  return $self;
}

sub next {
  my ($self, $n_rows) = @_;

  # first execute the statement
  $self->execute if $self->{status} < DBIx::DataModel::Statement::EXECUTED;

  # if needed, ajust $n_rows according to requested limit
  $n_rows = $self->{_ora_limit} if defined $self->{_ora_limit};

  # now regular handling can do the rest of the job;
  return $self->next::method($n_rows);
}

1;

__END__

=head1 NAME

DBIx::DataModel::Statement::Oracle - Statement for interacting with DBD::Oracle

=head1 SYNOPSIS

  DBIx::DataModel->Schema("MySchema",
     statement_class => "DBIx::DataModel::Statement::Oracle",
  );

  my $rows = $source->select(
    ...,
    -limit  => 50,
    -offset => 200,
  );

=head1 DESCRIPTION

This subclass redefines some parent methods 
from L<DBIx::DataModel::Statement> in order to take advantage
of L<DBD::Oracle/"Scrollable Cursor Methods">.

This is interesting for applications that need to do pagination
within result sets, because Oracle has no support for LIMIT/OFFSET in SQL.
So here we use some special methods of the Oracle driver to jump
to a specific row within a resultset, and then extract a limited
number of rows.

The API is exactly the same as other, regular DBIx::DataModel implementations.

=head1 AUTHOR

Laurent Dami, E<lt>laurent.dami AT etat  ge  chE<gt>, April 2012.

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
