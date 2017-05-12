package Database::Wrapper::Postgres;

use strict;
use lib qw(../..);
use base qw(Database::Wrapper);

our $VERSION = "1.04";
#	$Id: Postgres.pm,v 1.3 2005/11/26 00:37:34 incorpoc Exp $

=pod

Filter out all but tables

=cut

sub GetTableNames($)
	{
	my ($self) = (shift);

  my $raAllSchemas = [$self->{dbh}->tables('', '', '', 'TABLE')];
  ## If it starts with 'public.', we want it
  my $raTables = [grep {$_ = (/^public\./o)? $' : undef} @$raAllSchemas];
	# Remove quotes
	$raTables = [grep {s/\"//go; 1;} @$raTables];

	return $raTables;
	}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2003-2005 by Joe Yates, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
