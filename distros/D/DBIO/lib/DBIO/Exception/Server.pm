package DBIO::Exception::Server;
# ABSTRACT: A refusal by the database server, with its SQLSTATE

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Exception';


my @FIELDS = qw(sqlstate constraint table detail context);

sub new {
  my ($class, %args) = @_;

  my $message = delete $args{message};
  # a false error is no error to a Future (Future.pm refuses one) and to the
  # `if ($@)` checks around core's evals: the text must be true
  DBIO::Exception->throw(
    'DBIO::Exception::Server->new needs a message: the text it stringifies to'
  ) unless defined $message && length $message && $message;

  my %self = map { $_ => delete $args{$_} } @FIELDS;
  DBIO::Exception->throw(
    'DBIO::Exception::Server->new: unknown argument(s) '
    . join(', ', sort keys %args)
  ) if %args;

  return bless { msg => $message, %self }, ref($class) || $class;
}


sub throw {
  my $class = shift;
  die $class->new(@_);
}


sub sqlstate   { $_[0]{sqlstate} }
sub constraint { $_[0]{constraint} }
sub table      { $_[0]{table} }
sub detail     { $_[0]{detail} }
sub context    { $_[0]{context} }


sub with_context {
  my ($self, $context, $message) = @_;

  DBIO::Exception->throw(
    'DBIO::Exception::Server->with_context needs a context: BEGIN, COMMIT or ROLLBACK'
  ) unless defined $context && length $context;

  my %copy = %$self;
  if (defined $message) {
    DBIO::Exception->throw(
      'DBIO::Exception::Server->with_context: the message must be true'
    ) unless length $message && $message;
    $copy{msg} = $message;
  }
  $copy{context} = $context;

  return bless \%copy, ref $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Exception::Server - A refusal by the database server, with its SQLSTATE

=head1 VERSION

version 0.900005

=head1 DESCRIPTION

The error an async transport fails a Future with when the B<server> refused a
statement: a unique violation, a deadlock, a serialization failure, a
cancelled statement. It is a L<DBIO::Exception> that also carries what the
server said in machine-readable form, so a caller tells C<40001>, C<40P01>,
C<23505> and C<57014> apart without parsing text -- text that depends on the
server's C<lc_messages>.

It stringifies to the message it was built with, exactly the text the Future
failed with before a transport made these objects, and compares as that
string: C<< $@ =~ /.../ >>, C<eq> and C<like> keep working.

  my $f = $storage->insert_async($source, \%row);
  $f->catch(sub {
    my ($error) = @_;
    if (Scalar::Util::blessed($error)
        && $error->isa('DBIO::Exception::Server')
        && ($error->sqlstate // '') eq '23505') {
      ...
    }
  });

Core hands such an object on unchanged -- the one the transport failed with,
not a copy -- through C<txn_do_async> and C<pipeline>
(L<DBIO::Future/WHAT A TRANSPORT FAILS WITH>, ADR 0062). Where core puts text
in front of it -- a failed C<BEGIN>, C<COMMIT> or C<ROLLBACK> of a transaction
-- the caller gets a derived copy of the same class and fields with
L</context> set, stringifying with that prefix.

The synchronous path raises it too: a statement the DBI handle refused is a
C<DBIO::Exception::Server> from L<DBIO::Storage::DBI>, its text the decorated
C<DBI Exception: ...> it always was, its C<sqlstate> the handle's C<state>.
Every field is C<undef> where the handle gave none.

=head1 METHODS

=head2 new

  my $error = DBIO::Exception::Server->new(
    message    => qq{ERROR:  duplicate key value ...\n},
    sqlstate   => '23505',
    constraint => 'artist_name_key',
    table      => 'artist',
    detail     => 'Key (name)=(Duplicate) already exists.',
  );

C<message> is required and is the text the object stringifies to; core does
not add to it (no caller, no newline). The other fields (C<context> too, which
core sets on a derived copy -- see L</with_context>) are optional and
C<undef> when the server did not report them. Unknown arguments are refused.

=head2 throw

  DBIO::Exception::Server->throw(message => ..., sqlstate => ...);

C<new> and C<die>, for code that raises it synchronously. Takes the arguments
of L</new>; unlike L<DBIO::Exception/throw> it does not decorate the message
with the caller.

=head2 sqlstate

The five-character SQLSTATE the server reported (C<23505>), or C<undef>.

=head2 constraint

The name of the constraint the statement violated, or C<undef>.

=head2 table

The name of the table the error concerns, or C<undef>.

=head2 detail

The server's detail line (PostgreSQL C<DETAIL>), or C<undef>.

=head2 context

What core was doing when it prefixed the message: C<BEGIN>, C<COMMIT> or
C<ROLLBACK> for the failure of that step of a transaction, or C<undef> -- the
object is the one the server's refusal made, with no step of core's in front of
it. It is set on the derived copy core hands the caller, never on the object a
transport failed with.

=head2 with_context

  my $copy = $error->with_context('COMMIT', "COMMIT failed: $error");

A derived copy: same class (a subclass stays itself), C<sqlstate>,
C<constraint>, C<table> and C<detail> unchanged, C<context> set, and -- when
C<$message> is given -- the text it stringifies to replaced. The original is not
touched. Throws a L<DBIO::Exception> for an empty context or a false message.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
