package DBX;

use DBI;
use DBX::Connection;
use DBX::Recordset;
use DBX::Constants;

use strict;
use warnings;

our $VERSION = '0.1';

sub AUTOLOAD
{
	our $AUTOLOAD;
	my $driver = (split /::/, $AUTOLOAD)[-1];
	my $class = shift;
	my $source = shift;

	DBX::Connection->new(DBI->connect("dbi:$driver:$source", @_));
}

1;
__END__

=head1 NAME

DBX - Perl extension to simplify and enhance the DBI with minimal overhead

=head1 SYNOPSIS

  use DBX;

  $conn = DBX->mysql("database=test;host=localhost;", "", "");

  $rs = $conn->query("SELECT * FROM test");

  while($rs)
  {
	print $rs->field("client") . "\n";
	$rs->field("client", "test");
	$rs->move_next;
  }

=head1 ABSTRACT

  Abstracts the DBI by providing easy-to-use wrappers.

=head1 DESCRIPTION

The DBX family of modules provides a layer of abstraction over the DBI.  The DBX provides a simple
cursor system, and a simple field retrieval and updating system.

The DBX module exports no subroutines.  To connect to a data source, use the following code:

  use DBX;
  my $conn = DBX->mysql("database=test;host=localhost;", "", "");

Simply replace C<mysql> with the name of the DBD driver you want to use.  You should not include "dbi:mysql:" 
in the connection string; DBX specifies this automatically.

In the above code, $conn is a L<DBX::Connection> object, which can be used to issue queries on the data source.
DBX queries are handled by L<DBX::Recordset>.

=head1 DEPENDENCIES

Requires the L<DBI> module and appropriate DBD drivers.

=head1 TODO

=over 1

=item Random-access cursors

=item C<delete> and C<add> functions

=item Better error-handling

=item Query caching

=back

=head1 SEE ALSO

L<DBI>, L<DBX::Recordset>, L<DBX::Connection>

=head1 AUTHOR

Bill Atkins, E<lt>dbxNOSPAM@batkins.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bill Atkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
