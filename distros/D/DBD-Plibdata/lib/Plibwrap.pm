package Plibwrap;

use strict;
use DBI 1.43;
use vars qw/@ISA/;
@ISA = qw/DBI/;

our ($VERSION, $RET_OK, $RET_ERR, $RET_EOD);

$VERSION = "0.05";

$RET_OK  =  0;
$RET_ERR = -1;
$RET_EOD = -2;

*Plibdata::RET_OK = \$RET_OK;
*Plibdata::RET_ERR = \$RET_ERR;
*Plibdata::RET_EOD = \$RET_EOD;

package Plibwrap::db;

use vars qw/@ISA/;
@ISA = qw/DBI::db/;

sub STORE
{
	my ($dbh, $attr, $val) = @_;
	## 'Row' for Plibwrap
	if (grep /^$attr$/, qw/Row plb_sthdl plb_is_select/) 
	{
		$dbh->{$attr} = $val;
		return 1;
	}
	# pass up unknowns to DBI to handle for us
	$dbh->SUPER::STORE($attr, $val);
}

sub FETCH
{
	my ($dbh, $attr) = @_;

	if (grep /^$attr$/, qw/Row plb_sthdl plb_is_select/) 
	{
		return $dbh->{$attr};
	}

	# pass up unknowns to DBI to handle for us
	$dbh->SUPER::FETCH($attr);
}

sub SQLExecSQL
{
	my ($dbh, $sql) = @_;
	my ($rv,$sth);

	$sth = $dbh->prepare($sql) or return $RET_ERR;
	$dbh->STORE('plb_sthdl', $sth);

	$rv  = $sth->execute or return $dbh->FETCH('plb_err_stat');

	if ($sql =~ /^\s*select/i)
	{
		$dbh->STORE('plb_is_select', 1);
	}

	return $rv;
}

sub SQLFetch
{
	my ($dbh) = @_;
	return unless $dbh->FETCH('plb_is_select');
	my $sth = $dbh->FETCH('plb_sthdl');

	my $ar = $sth->fetchrow_arrayref;

	if (!defined $ar && $dbh->err) 
	{
		return $RET_ERR;
	}
	elsif (!defined $ar)
	{
		return $RET_EOD;
	}

	my $row = new Plibwrap::Row($ar, $sth->{NAME_lc});
	$dbh->STORE('Row', $row);
	return $RET_OK if $ar;

	return $RET_ERR;
}

sub SQLClose
{
	my ($dbh) = @_;
	$dbh->disconnect;
	return $RET_OK;
}

sub GetError
{
	my ($dbh) = @_;
	return $dbh->errstr;
}

package Plibwrap::st;

use vars qw/@ISA/;
@ISA = qw/DBI::st/;


package Plibwrap::Row;

sub new
{
	my ($class,$ar,$cols) = @_;
	my $self = {};
	$self = bless $self, $class;
	$self->{RowRef} = $ar;
	$self->{ColRef} = $cols;
	return $self;
}

sub GetCharValue
{
	my ($self, $fld) = @_;
	my ($n, $cols, $val);

	$cols = $self->{ColRef};

	for ($n = 0; $n < scalar @$cols; $n++)
	{
		if (@$cols[$n] eq $fld)
		{
			return @{$self->{'RowRef'}}[$n];
		}
	}
	return undef;
}
*GetDoubleValue = \&GetCharValue;
*GetLongValue = \&GetCharValue;
*GetIntValue = \&GetCharValue;
*GetFloatValue = \&GetCharValue;

1;
__END__

=pod

=head1 NAME

Plibwrap - module which wraps DBD::Plibdata to emulate Plibdata

=head1 SYNOPSIS

 use strict;
 use Plibwrap;
 my $db1 = Plibwrap->connect("dbi:Informix:cars", 
                     $USERNAME, $PASSWORD, {PrintError => 0});

 my $dbh = Plibwrap->connect("dbi:Plibdata:host=$HOSTNAME;port=$PORT", 
                     $USERNAME, $PASSWORD, {PrintError => 0});

 my ($status,$err);
 my $sql = 'SELECT tabname, tabid FROM systables';

 if (($status = $dbh->SQLExecSQL($sql)) < 0)
 {
   $err = $dbh->GetError();
   die "$err\n";
 }
 else
 {
   while ( ($status = $dbh->SQLFetch()) == $Plibdata::RET_OK)
   {
     $tabname = $dbh->{Row}->GetCharValue('tabname');
     $tabid = $dbh->{Row}->GetCharValue('tabid');
     print "ID: $tabid\t\tName: $tabname\n";
   }
 }

 $sql = "SELECT fullname FROM id_rec WHERE id = 1";
 my ($name) = $dbh->selectrow_array($sql);
 

=head1 DESCRIPTION

A lot of code, Jenzabar and local, relies on Plibdata's interface -- especially the Row object. The goal of Plibwrap is to emulate the most used client functionality in Plibdata.

As Plibwrap wraps DBD::Plibdata, you can use the database handle like any other DBI handle.

=head1 UNSUPPORTED

 . Server functionality
 . Anything not used in the standard CX code
 
=head1 AUTHOR

Stephen Olander-Waters < stephenw AT stedwards.edu >

=head1 LICENSE

Copyright (c) 2005-2007 by Stephen Olander-Waters, all rights reserved.

You may freely distribute and/or modify this module under the terms of either
the GNU General Public License (GPL) or the Artistic License, as specified in
the Perl README file.

No Jenzabar code or intellectual property was used or misappropriated in the
making of this module.

=head1 SEE ALSO

L<DBD::Plibdata>, L<DBI>, L<DBD::Informix>

=cut
