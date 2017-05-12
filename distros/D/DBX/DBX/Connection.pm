package DBX::Connection;

use strict;
use warnings;

use DBI;
use DBX;
use DBX::Recordset;
use DBX::Constants;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(DBX_CURSOR_RANDOM DBX_CURSOR_FORWARD);


our $VERSION = '0.1';

sub new
{
	my ($class, $dbh) = @_;

	bless { dbh => $dbh }, $class;
}

sub query
{
	my ($self, $query, $how, @args) = @_;
	my $sth;
	$how ||= DBX_CURSOR_FORWARD;


	$sth = $self->{dbh}->prepare($query);
	$sth->execute(@args);
	DBX::Recordset->new($self->{dbh}, $sth, $how, $query);
}

1;

__END__

=head1 NAME

DBX::Connection - abstracts a connection to a data source

=head1 SYNOPSIS

  use DBX;

  $conn = DBX->mysql("database=test;host=localhost;", "", "");

  $rs = $conn->query("SELECT * FROM test");

=head1 DESCRIPTION

DBX::Connection currently provides only one method

=over 4

=item query(SQL [, HOW, SQL_PARMS])

C<query> runs SQL on its data source.  If HOW is DBX_CURSOR_FORWARD, the returned recordset will only move forward.
If HOW is DBX_CURSOR_RANDOM, the returned recordset will be navigable in any direction.  However, random-access 
cursors use considerably more memory and processor time than forward-only cursors.

If the SQL statement contains argument placeholders, the DBI will fill them in with SQL_PARMS.

=back

=head1 DEPENDENCIES

Requires L<DBX> and all of its dependencies

=head1 SEE ALSO

L<DBI>, L<DBX>, L<DBX::Recordset>

=head1 AUTHOR

Bill Atkins, E<lt>dbxNOSPAM@batkins.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bill Atkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
