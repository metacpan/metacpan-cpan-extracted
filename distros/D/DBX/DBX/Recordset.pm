package DBX::Recordset;

use DBI;
use DBX::Constants;

use overload "0+" => \&as_num;

use strict;
use warnings;

our $VERSION = '0.1';

sub new
{
	my ($class, $dbh, $sth, $how, $query) = @_;
	my ($table) = ($query =~ / from (.*)/i);
	my $self = { sth => $sth, how => $how, table => $table, dbh => $dbh };

	bless $self, $class;
	$self->fetch;
	return $self;
}

sub move_first
{
	my ($self) = @_;
	$self->clear;
	die "Selected cursor cannot move_first" if $self->{how} !=  DBX_CURSOR_RANDOM;
}

sub move_last
{
	my ($self) = @_;
	$self->clear;
	die "Selected cursor cannot move_last" if $self->{how} !=  DBX_CURSOR_RANDOM;
}

sub move_next
{
	my ($self) = @_;

	$self->update;
	$self->fetch;
}

sub fetch
{
	my ($self) = @_;
	$self->clear;
	$self->{cur_rec} = $self->{sth}->fetchrow_hashref;

	if(!$self->{cur_rec})
	{
		$self->{eof} = 1;
	}
}

sub move_prev
{
	my ($self) = @_;
	$self->clear;
	die "Selected cursor cannot move_prev" if $self->{how} !=  DBX_CURSOR_RANDOM;
}

sub eof
{
	my ($self) = @_;
	$self->{eof};
}

sub clear
{
	my ($self) = @_;

	$self->{dirty} = 0;
	$self->{changed} = {};
}

sub field
{
	my ($self, $field, $value) = @_;
	if(not defined $value)
	{
		my $value = $self->{cur_rec}->{$field};
		die "No such field" unless $value;
		return $value;
	}
	else
	{
		$self->{dirty} = 1;
		$self->{changed}->{$field} = $value;
		return $value;
	}
}

sub as_num
{
	my ($self) = @_;

	return !$self->{eof};
}

sub update
{
	my ($self) = @_;
	return unless $self->{dirty};

	my %changed = %{$self->{changed}};
	my %old = %{$self->{cur_rec}};

	my $sql = "UPDATE $self->{table} SET ";

	for(keys(%changed))
	{
		$sql .= "$_ = '$changed{$_}', ";
	}

	$sql =~ s/, $//;
	$sql .= "WHERE ";

	for(keys(%old))
	{
		$sql .= "$_ = '$old{$_}' AND ";
	}

	$sql =~ s/ AND $/\;/;

	$self->{dbh}->do($sql) or die $!;
}

1;

__END__

=head1 NAME

DBX::Recordset - abstracts a DBX query result

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

=head1 DESCRIPTION

DBX::Recordset is the heart of the DBX and provides most of its additional functionality.  Recordsets are 
returned by the query method of a L<DBX::Connection> object.

Recordsets support simple forward-only cursors (at the moment) and allow you to easily retrieve and/or modify
fields.

=over 4

=item eof

Returns a value indicating whether or not the recordset has reached its end.  DBX::Recordset overrides the 
numification operator so that C<if($rs)> is equivalent to C<if($rs->eof)>.

=item field(NAME [, VALUE])

The field subroutine will return the value of the field named NAME.  If a second parameter is passed, then 
the field with that name will be set to that value.  Note that changes made with the field function don't take 
effect until update() is called or the cursor moves.

=item move_first

Moves the recordset's cursor to the beginning of the set.  Works only for random-access cursors. 
NOT YET IMPLEMENTED.

=item move_prev

Moves the recordset's cursor to the previous record.  Works only for random-access cursors. 
NOT YET IMPLEMENTED.

=item move_next

Moves the recordset's cursor to the next record.  Works for random-access and forward-only cursors.  If the 
recordset has reached its end, the EOF flag will be set.

=item move_last

Moves the recordset's cursor to the end of the set.  Works only for random-access cursors. 
NOT YET IMPLEMENTED.

=item update

Saves changes to the current record.  C<update> is automatically called when the cursor is moved.

=back

=head1 DEPENDENCIES

Requires L<DBX> and all of its dependencies

=head1 SEE ALSO

L<DBI>, L<DBX>, L<DBX::Connection>

=head1 AUTHOR

Bill Atkins, E<lt>dbxNOSPAM@batkins.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Bill Atkins

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
