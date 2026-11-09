package DBIO::MSSQL::Storage::StopAtFirstError;
# ABSTRACT: A statement handle whose execute_for_fetch stops at the first failing tuple

use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();

our $AUTOLOAD;


sub new {
  my ($class, $sth) = @_;
  return bless { sth => $sth }, $class;
}


sub execute_for_fetch {
  my ($self, $fetch_tuple, $tuple_status, @rest) = @_;

  $tuple_status = [] unless $tuple_status;

  return $self->{sth}->execute_for_fetch(
    sub {
      return undef if @$tuple_status and ref $tuple_status->[-1];
      return $fetch_tuple->();
    },
    $tuple_status,
    @rest,
  );
}

sub can {
  my ($self, $method) = @_;
  return $self->SUPER::can($method) || ( ref $self && $self->{sth}->can($method) );
}

sub DESTROY { }

sub AUTOLOAD {
  my $self = shift;
  ( my $method = $AUTOLOAD ) =~ s/.*:://;
  return $self->{sth}->$method(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Storage::StopAtFirstError - A statement handle whose execute_for_fetch stops at the first failing tuple

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The statement handle L<DBIO::MSSQL::Storage/_dbh_execute_for_fetch> hands to
core's void-context C<populate>. It is a thin wrapper that passes every method
on to the real handle and changes one thing: C<execute_for_fetch> stops after
the first tuple that failed.

DBI's C<execute_for_fetch> executes B<every> tuple, whatever became of the one
before, and reports the failures in the tuple status. SQL Server rolls the
whole transaction back on some statement errors (Msg 8114, a bound value that
cannot be converted: C<@@TRANCOUNT> goes from 1 to 0 on the failing
statement), so the tuples after the failing one run with no transaction, in
autocommit, and are B<committed>, while the ones before it went with the
transaction. A C<populate> that threw then left some of its rows, the ones
after the bad one. Stopping at the first failure leaves nothing of
the data set behind.

=head1 METHODS

=head2 execute_for_fetch

As DBI's, except that C<$fetch_tuple> is not called again once the last
entry of the tuple status is an error (an array reference).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
