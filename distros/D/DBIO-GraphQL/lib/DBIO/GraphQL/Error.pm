package DBIO::GraphQL::Error;
# ABSTRACT: Client errors of DBIO::GraphQL and the error envelope around resolvers
use strict;
use warnings;

our $VERSION = '0.900004';

use Scalar::Util ();
use GraphQL::Error;
use DBIO::Exception::Server;

use base 'Exporter';
our @EXPORT_OK = qw(client_error);

use overload
  '""'     => sub { $_[0]{message} },
  'bool'   => sub { 1 },
  fallback => 1;

# Two kinds of failure leave a resolver:
#
#   * a client error: DBIO::GraphQL itself words it for the client
#     (validation, bounds, authorization). It is an object of this class and
#     reaches the client as it is.
#   * anything else (a database refusal, a Perl error): never worded for the
#     client. The envelope classifies a database refusal by its SQLSTATE and
#     answers everything else with "internal error" and a correlation id; the
#     original goes to the on_error hook only.

my %CLASSIFIED = (
  '23505' => [ UNIQUE_VIOLATION      => 'unique constraint violated'      ],
  '23503' => [ FOREIGN_KEY_VIOLATION => 'foreign key constraint violated' ],
  '23502' => [ NOT_NULL_VIOLATION    => 'not null constraint violated'    ],
  '23514' => [ CHECK_VIOLATION       => 'check constraint violated'       ],
);

my $counter = 0;


sub client_error {
  (my $message = join '', @_) =~ s/\n+\z//;
  return bless { message => $message }, __PACKAGE__;
}


sub message { $_[0]{message} }


sub guard {
  my ($class, $resolve, $on_error) = @_;
  return sub {
    my @args = @_;
    my @ret;
    my $want = wantarray;
    my $ok = eval {
      if ($want) { @ret = $resolve->(@args) }
      else       { $ret[0] = $resolve->(@args) }
      1;
    };
    return $want ? @ret : $ret[0] if $ok;
    die $class->_envelope($@, $on_error);
  };
}

sub _envelope {
  my ($class, $error, $on_error) = @_;
  return $error if Scalar::Util::blessed($error)
    && ($error->isa(__PACKAGE__) || $error->isa('GraphQL::Error'));

  if (Scalar::Util::blessed($error) && $error->isa('DBIO::Exception::Server')) {
    my $hit = $CLASSIFIED{ $error->sqlstate // '' };
    return GraphQL::Error->new(
      message    => $hit->[1],
      extensions => { code => $hit->[0] },
    ) if $hit;
  }

  my $id = sprintf '%x-%x-%x-%06x', time, $$, ++$counter, int rand 0xffffff;
  if ($on_error) {
    eval { $on_error->($error, $id); 1 }
      or warn "DBIO::GraphQL: on_error hook failed (correlation id $id)\n";
  }
  else {
    warn "DBIO::GraphQL: internal error, correlation id $id: $error\n";
  }
  return GraphQL::Error->new(
    message    => 'internal error',
    extensions => { code => 'INTERNAL_ERROR', correlation_id => $id },
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::GraphQL::Error - Client errors of DBIO::GraphQL and the error envelope around resolvers

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 client_error

  die client_error("page 'take' must be >= 1");

Builds a client error to die with: the message reaches the client unchanged.
It names keys, columns and options, never values. A trailing newline is dropped.

=head2 message

The text of the client error.

=head2 guard

  my $resolve = DBIO::GraphQL::Error->guard($resolve, $on_error);

Wraps a resolver in the error envelope. A client error passes through as it
is. A C<DBIO::Exception::Server> whose SQLSTATE is C<23505>, C<23503>,
C<23502> or C<23514> becomes C<UNIQUE_VIOLATION>, C<FOREIGN_KEY_VIOLATION>,
C<NOT_NULL_VIOLATION> or C<CHECK_VIOLATION> in C<extensions.code>, with a
fixed message. Everything else becomes C<INTERNAL_ERROR>, message
C<internal error>, with a C<extensions.correlation_id>; the exception and the
id go to the C<$on_error> code reference, or without one to C<warn>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
