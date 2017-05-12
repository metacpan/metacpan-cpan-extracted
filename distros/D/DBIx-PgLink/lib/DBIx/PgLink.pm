package DBIx::PgLink;

use 5.008006;
use strict;
use warnings;
use Exporter;
use DBIx::PgLink::Logger;

our @ISA = qw/Exporter/;

our @EXPORT = qw/named_params/;

our $VERSION = '0.01';

our %connection_by_name;

sub connect {
  my $self = shift;
  my $conn_name = shift;

  trace_msg('INFO', "Using connection $conn_name")
    if trace_level>=2;

  if (exists $connection_by_name{$conn_name}) {
    return $connection_by_name{$conn_name};
  } else {
    require DBIx::PgLink::Connector;
    my $conn = DBIx::PgLink::Connector->new(
      conn_name => $conn_name,
      @_
    );
    $connection_by_name{$conn_name} = $conn;
    return $conn;
  }
}

sub disconnect {
  my ($self, $conn_name) = @_;

  my $data = $main::_SHARED{'dbix_pglink'};
  my $conn = $connection_by_name{$conn_name} or return;
  trace_msg('INFO', "Disconnect from $conn_name")
    if trace_level>=1;
  $conn->adapter->disconnect;
  delete $connection_by_name{$conn_name};
}


sub named_params {
  my $params = shift;
  my $i = 0;
  my %p = map {
    my $v = $params->[$i++];
    defined $v ?  ($_ => $v) : () # skip NULLs
  } @_;
  return \%p;
}

1;


__END__


=head1 NAME

DBIx::PgLink - external database access from PostgreSQL backend using Perl DBI

=head1 SYNOPSIS

For SQL script examples see L<DBIx::PgLink::Manual::Usage>.

I<In PL/PerlU function>

    use DBIx::PgLink;

    $conn = DBIx::PgLink->connect('NORTHWIND');

    $db = $conn->adapter;
    $db->begin_work;
    $st = $db->prepare('SELECT * FROM Orders WHERE OrderID=?');
    $st->execute(42);
    while (@row = $st->fetchrow_array) {
      ...
    }
    $db->commit;

    $conn->builder->build_accessors(
      local_schema  => 'northwind',
      remote_schema => 'dbo',
      remote_object => 'Order%',
    );

    DBIx::PgLink->disconnect('NORTHWIND');

=head1 DESCRIPTION

I<PgLink> is based on I<DBI-Link> project for accessing 
external data sources from PostgreSQL backend.

This module can be used only in untrusted PL/Perl function.

=head2 Differences from I<DBI-Link>

=over

=item *

I<PgLink> is standard Perl module

While I<DBI-Link> store all Perl code in PL/Perl functions,
DBIx-PgLink use Perl infrastructure for installation and testing.

=item *

Extensibility

The main goal is to compose functionality without writing a line of Perl code.

=item *

Flexible data type mapping

=item *

Customizable SQL queries.

=item *

Parametrized queries

Prevent SQL-injection attack.

=item *

Mapping between database accounts

Can connect with different credentials for each PostgreSQL user.

=item *

Additional functionality for DBI

Such as automatic reconnection after network outage,
nested transactions, charset conversion, prepared statement cache management.


=back


=head1 SUBROUTINES

=over

=item connect

    $adapter = connect($conn_name);

Load connection metadata from PostgreSQL and connect to remote datasource.

Returns instance of L<DBIx::PgLink::Connector> object.

Subsequent calls return the same cached object.
Single connection persists while PostgreSQL session live
or until explicit C<disconnect>.

=item disconnect

    disconnect($conn_name);

Close connection to remote database and delete entry from cache.

=item named_params

    my $hashref = named_params(\@_, qw/foo bar/); # { foo=>$_[0], bar=>$_[1] }

Utility subroutine. Converts positional arguments of PL/Perl function (passed in @_) to named parameters.
NULL arguments are ignored.

Exported by default.

=back


=head1 SEE ALSO

L<DBIx::PgLink::Manual::Install>,
L<DBIx::PgLink::Manual::Usage>,
L<DBI>,
L<DBIx::PgLink::Connector>,
L<DBIx::PgLink::Adapter>,
L<DBIx::PgLink::Accessor::Table>,
L<DBIx::PgLink::Local>,
L<http://pgfoundry.org/projects/dbi-link/>

=head1 AUTHOR

Alexey Sharafutdinov E<lt>alexey.s.v.br@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Alexey Sharafutdinov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

DBI-Link project by David Fetter under BSD License.

=cut
