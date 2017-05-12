package Database::Wrapper::MySQL;

use strict;
use lib qw(../..);
use base qw(Database::Wrapper);

our $VERSION = "1.04";
#	$Id: MySQL.pm,v 1.3 2005/11/26 00:37:34 incorpoc Exp $

=pod

Override the standard 'GetTableNames' as the MySQL driver
returns field names wrapped in backticks '`'.

=cut

sub GetTableNames($)
	{
	my ($self) = (shift);
	my $raTables = $self->SUPER::GetTableNames();

	# Strip leading and trailing backticks in place
	grep {s/(^\`|\`$)//go} @$raTables;

	return $raTables;
	}

sub GetUserNames
  {
  my $rhConnectionData = Database::Wrapper::_GetConnectionData(\@_);
  return undef
    if(not defined $rhConnectionData);

	my $sDbiConnectionString = Database::Wrapper::_MakeDsn($rhConnectionData->{ConnectionType}, 'mysql', $rhConnectionData->{Host});
  if(not defined $sDbiConnectionString)
    {
    warn($Database::Wrapper::ConnectionError);
    return undef;
    }
  $rhConnectionData->{DbiConnectionString} = $sDbiConnectionString;
  my $dbh = Database::Wrapper::_Connect($rhConnectionData);
  return undef
  	if(not defined $dbh);
	my $sqry = "SELECT * FROM user;";
	my $ra = undef;
	eval
		{
		my $sth = $dbh->prepare($sqry);
		$sth->execute();
		$ra = $sth->fetchall_arrayref({});
    };
	if($@)
		{
		warn("GetUserNames(): $@");
		return undef;
		}
  my $raUsers = [map($_->{User}, @$ra)];
  return $raUsers;  
  }

sub IsSuperUser
  {
  my $rhConnectionData = Database::Wrapper::_GetConnectionData(\@_);
  return undef
    if(not defined $rhConnectionData);

  # There should be a user name left in @_
  my $sUser = shift;
	my $sDbiConnectionString = Database::Wrapper::_MakeDsn($rhConnectionData->{ConnectionType}, 'mysql', $rhConnectionData->{Host});
  if(not defined $sDbiConnectionString)
    {
    warn($Database::Wrapper::ConnectionError);
    return undef;
    }
  $rhConnectionData->{DbiConnectionString} = $sDbiConnectionString;
  my $dbh = Database::Wrapper::_Connect($rhConnectionData);
  return undef
  	if(not defined $dbh);
	my $sqry = "SELECT * FROM user WHERE User = ?;";
	my $ra = undef;
	eval
		{
		my $sth = $dbh->prepare($sqry);
		$sth->execute($sUser);
		$ra = $sth->fetchall_arrayref({});
    };
	if($@)
		{
		warn("IsSuperUser(): $@");
		return undef;
		}
  
  return 0
    if(scalar @$ra == 0);
  my $rhUser = $ra->[0];
  return ($rhUser->{Super_priv} eq 'Y') ? 1 : 0;  
  }

sub DDMMYYYYToMySQL($)
  {
  my ($sISODate)  = (shift);
  
  return undef
    if(not defined $sISODate);
  return undef
    if(ref($sISODate) ne "");
  return undef
    if($sISODate !~ /(\d{1,2})[\/\:](\d{1,2})[\/\:](\d{4})/o);

  my ($nDay, $nMonth, $nYear) = ($1, $2, $3);
  
  return sprintf("%04u-%02u-%02u", $nYear, $nMonth, $nDay);
  }

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2003-2005 by Joe Yates, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.
