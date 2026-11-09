package DBIO::MySQL::Storage::Async::Binary;
# ABSTRACT: A bind value of a binary column on its way through the future_io transport

use strict;
use warnings;

our $VERSION = '0.900004';

use overload
  '""'     => sub { $_[0][0] },
  fallback => 1;



sub new {
  my ($class, $value) = @_;
  return bless [ $value ], $class;
}


sub value { $_[0][0] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Storage::Async::Binary - A bind value of a binary column on its way through the future_io transport

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Core hands the runner of an asynchronous statement bare bind values, and the
column a value is bound for is not among them. The C<future_io> transport of
this driver keeps one fact of the column: whether it is binary. A value of a
C<BLOB>, C<BINARY> or C<VARBINARY> column travels as an object of this class so
that L<DBIO::MySQL::Storage::Async/_bind_and_execute> binds it as C<SQL_BINARY>,
as the synchronous storage does. The object stringifies as the
value, which is what a trace line shows.

=head1 METHODS

=head2 new

  my $bind = DBIO::MySQL::Storage::Async::Binary->new($bytes);

=head2 value

The bytes.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
