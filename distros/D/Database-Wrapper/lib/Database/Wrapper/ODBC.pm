package Database::Wrapper::ODBC;

use strict;
use lib qw(../..);
use base qw(Database::Wrapper);

our $VERSION = "1.04";
#	$Id: ODBC.pm,v 1.3 2005/11/26 00:37:34 incorpoc Exp $

=pod

Override the standard 'GetTableNames' as the Access driver
returns field names wrapped in backticks '`' preceded by the path, e.g.:

  `C:\Temp\Foo`.`MSysAccessObjects`

=cut

sub GetTableNames($)
	{
	my ($self) = (shift);
	my $raTables = $self->SUPER::GetTableNames();

	grep {s/^\`[^\`]+\`\.//o} @$raTables;
	# Strip leading and trailing backticks in place
	grep {s/(^\`|\`$)//go} @$raTables;

	return $raTables;
	}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2003-2005 by Joe Yates, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
