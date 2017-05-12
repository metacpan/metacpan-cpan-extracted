package Database::Wrapper::SQLite;

use strict;
use lib qw(../..);
use base qw(Database::Wrapper);

our $VERSION = "1.04";
#	$Id: SQLite.pm,v 1.2 2005/11/26 00:37:34 incorpoc Exp $

sub GetTableNames($)
	{
	my ($self) = (shift);

  my $sth = undef;
	eval
		{
		$sth = $self->{dbh}->prepare(qq(select tbl_name from sqlite_master;));
		$sth->execute();
		};
	if($@)
		{
		return undef;
		}

	my $raaTables = $sth->fetchall_arrayref();

  my $raTables = [];
	foreach my $raTable (@$raaTables)
    {
    push @$raTables, $raTable->[0];
    }

	return $raTables;
	}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2003-2005 by Joe Yates, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
