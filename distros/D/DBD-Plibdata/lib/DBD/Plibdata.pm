package DBD::Plibdata;

use strict;
our ($VERSION, $drh, $P_OK, $P_PASW, $P_UNAM, $P_ERR, $P_EXE, $P_FTCH, $P_EACK, $T_CHAR, $T_INT, $T_DATE, $T_FLOT);

$VERSION = "0.05";
$P_OK   = 0x00000000;
$P_EXE  = 0x00000015;
$P_FTCH = 0x00000017;
$P_EACK = 0x0000002c;
$P_PASW = 0x00002329;
$P_UNAM = 0x0000232a;
$P_ERR  = 0xffffffff;
$T_CHAR	= "01";
$T_INT	= "04";
$T_FLOT	= "08";
$T_DATE	= "09";

$drh = undef;

sub driver
{
	return $drh if $drh;      # already created - return same one
	my ($class, $attr) = @_;
	$class .= "::dr";
	# not a 'my' since we use it above to prevent multiple drivers
	$drh = DBI::_new_drh($class, {
		'Name'        => 'Plibdata',
		'Version'     => $VERSION,
		'Attribution' => 'DBD::Plibdata by Stephen Olander-Waters',
		})
	or return undef;
	return $drh;
}

sub CLONE
{
	undef $drh;
}



package DBD::Plibdata::dr;

$DBD::Plibdata::dr::imp_data_size = 0;

sub connect
{
	my ($drh, $dr_dsn, $user, $auth, $attr) = @_;

	my $driver_prefix = "plb_"; # the assigned prefix for this driver

	# Process attributes from the DSN; we assume ODBC syntax
	# here, that is, the DSN looks like var1=val1;...;varN=valN
	foreach my $var ( split /;/, $dr_dsn )
	{
		my ($attr_name, $attr_value) = split '=', $var, 2;
		return $drh->set_err(1, "Can't parse DSN part '$var'")
			unless defined $attr_value;
		# add driver prefix to attribute name if it doesn't have it already
		$attr_name = $driver_prefix.$attr_name
			unless $attr_name =~ /^$driver_prefix/o;

		# Store attribute into %$attr, replacing any existing value.
		# The DBI will STORE() these into $dbh after we've connected
		$attr->{$attr_name} = $attr_value;
	}

	# Get the attributes we'll use to connect.
	# We use delete here because these no need to STORE them

	my $host = delete $attr->{plb_host} 
		or return $drh->set_err(1, "No hostname/IP given in DSN '$dr_dsn'");
	my $port = delete $attr->{plb_port}
		or return $drh->set_err(1, "No TCP port given in DSN '$dr_dsn'");

	# create a 'blank' dbh (call superclass constructor)
	my ($outer, $dbh) = DBI::_new_dbh($drh, { Name => $dr_dsn });

	if (exists $attr->{'plb_RowsPerPacket'})
	{
		$dbh->STORE('plb_RowsPerPacket',$attr->{'plb_RowsPerPacket'})
			or return $drh->set_err(1, $!);
	}
	else
	{
		$dbh->STORE('plb_RowsPerPacket', 40) or return $drh->set_err(1, $!);
	}

	$dbh->STORE('plb_pktcnt', 0) or return $drh->set_err(1, $!);

	DBD::Plibdata::db::_login($dbh, $host, $port, $user, $auth)
		or return $drh->set_err(1, "Can't connect to $dr_dsn: ...");

	$dbh->STORE('Active', 1 );

	return $outer;
}

sub data_sources
{
	return undef;
}


package DBD::Plibdata::db;

$DBD::Plibdata::db::imp_data_size = 0;

use IO::Socket::INET;
use Digest::MD5 qw/md5_hex/;

sub commit
{
	return _commroll(shift(), 'COMMIT');
}
sub rollback
{
	return _commroll(shift(), 'ROLLBACK');
}

sub _commroll
{
	my ($dbh, $mode) = @_;
	my ($err);

	if ($dbh->FETCH('AutoCommit'))
	{
		warn(lc($mode), " ineffective with AutoCommit")
			if $dbh->FETCH('Warn');
		return undef;
	}

	_send_or_err($dbh, "$mode work;");
	$err = _send_or_err($dbh, 'BEGIN work;');

	$dbh->STORE('Executed', 0);
	return $dbh->set_err(1, $err) if $err;

	## support for DBI's begin_work()
	if ($dbh->FETCH('BegunWork'))
	{
		$dbh->STORE('BegunWork', 0);
		$dbh->STORE('AutoCommit', 1);
	}
	return 1;
}

sub disconnect
{
	my ($dbh) = @_;
	my $sock = $dbh->FETCH('plb_sock');
	$sock->shutdown(2);
	$dbh->STORE('plb_pktcnt', 0 );
	$dbh->STORE('Active', 0 );
	return 1;
}

sub _login
{
	my ($dbh, $host, $port, $user, $auth) = @_;
	my ($pkt, $cmd, $len, $data, $salt);

	$dbh->STORE('plb_sock', 
			IO::Socket::INET->new(
			PeerAddr => $host, 
			PeerPort => $port,
			Proto => 'tcp'
			)
	);

	DBD::Plibdata::db::_send_packet($dbh, $P_UNAM, $user);

	($pkt, $cmd, $len, $data) = DBD::Plibdata::db::_recv_packet($dbh);

	if ($data eq '*' || $cmd ne $P_OK)
	{
		return undef;
	}

	($salt) = $data =~ /^(\w\w)/;
	DBD::Plibdata::db::_send_packet($dbh, $P_PASW, md5_hex(crypt($auth, $salt) . $data ));

	($pkt, $cmd, $len, $data) = DBD::Plibdata::db::_recv_packet($dbh);
	
	if ($data eq 'Login OK')
	{
		return 1;
	}

	return undef;
}

sub prepare
{
	my ($dbh, $statement, @attribs) = @_;

	# create a 'blank' sth
	my ($outer, $sth) = DBI::_new_sth($dbh, { Statement => $statement });

	$sth->STORE('NUM_OF_PARAMS', ($statement =~ tr/?//));

	$sth->{plb_params} = [];

	return $outer;
}

sub STORE
{
	my ($dbh, $attr, $val) = @_;
	my ($err);

	if ($attr eq 'AutoCommit' && $val)
	{
		## not calling commit() cause we don't want BEGIN
		$err = _send_or_err($dbh, 'COMMIT work;') 
			if defined $dbh->FETCH('AutoCommit') && $dbh->FETCH('AutoCommit') == 0;

		$dbh->STORE('Executed', 0);

		return $dbh->set_err(1, $err) if $err;

		## support for DBI's begin_work()
		if ($dbh->FETCH('BegunWork'))
		{
			$dbh->STORE('BegunWork', 0);
		}

		$dbh->{$attr} = $val;
		return 1;
	}
	elsif ($attr eq 'AutoCommit' && !$val)
	{
		if (defined $dbh->FETCH('AutoCommit')
			&& $dbh->FETCH('AutoCommit') == 0)
		{
			$dbh->STORE('BegunWork', 0);
			$dbh->commit;
		}
		else
		{
			$err = _send_or_err($dbh, 'BEGIN work;');
		}

		$dbh->STORE('Executed', 0);

		return $dbh->set_err(1, $err) if $err;

		$dbh->{$attr} = $val;
		return 1;
	}
	elsif ($attr eq 'plb_RowsPerPacket')
	{
		unless (defined $val)
		{
			$err = "$attr is not defined.";
		}
		elsif ($val > 255)
		{
			$err = "$attr is too big.";
		}
		elsif ($val < 1)
		{
			$err = "$attr is too small.";
		}

		return $dbh->set_err(1, $err . " Valid range: 1-255") 
			if $err;

		$dbh->{$attr} = $val;
		return 1;
	}
	elsif ($attr =~ m/^plb_/) 
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
	if ($attr eq 'AutoCommit' || $attr =~ m/^plb_/) 
	{
		return $dbh->{$attr};
	}

	# pass up unknowns to DBI to handle for us
	$dbh->SUPER::FETCH($attr);
}

sub _send_or_err
{
	my ($dbh, $sql) = @_;
	my ($pkt, $cmd, $len, $data, $out, $err);

	DBD::Plibdata::db::_send_packet($dbh, $P_EXE, $sql);
	($pkt, $cmd, $len, $data) = _recv_packet($dbh);
	if ($cmd == $P_ERR)
	{
		$err = $data || 'Error in SQL statement';
		$out = pack('C*',0x00,0x00,0x00,0x0b,0x00,0x00,0x00,0x00);
		_send_packet($dbh, $P_EACK, $out);
		($pkt, $cmd, $len, $data) = _recv_packet($dbh);
	}
	return $err;
}

sub _send_packet
{
	my ($self, $cmd, $data) = @_;
	my $sock = $self->{plb_sock};
	my ($out);

	$out  = sprintf("%08x%08x%08x", 
	        $self->FETCH('plb_pktcnt'), $cmd, length($data));
	$out .= $data;

	## DEBUG
	#warn "SEND: $out\n";
	$sock->send($out);
	$self->STORE('plb_pktcnt', $self->FETCH('plb_pktcnt') + 1);
	return 1;
}

sub _recv_packet
{
	my $self = shift;
	my ($pkt,$cmd,$len,$data, $buf, $n);
	my $sock = $self->{plb_sock};

	$sock->recv($pkt, 8);
	$sock->recv($cmd, 8);
	$sock->recv($len, 8);

	$n = hex($len);
	$data = '';

	while ($n != 0)
	{
		$sock->recv($buf, $n);
		$data .= $buf;
		$n -= length($buf);
	};

	$self->STORE('plb_pktcnt', $self->FETCH('plb_pktcnt') + 1);
	## DEBUG
	#warn "RECV: $pkt $cmd $len $data  |", unpack('H*', $data), "\n";

	$cmd = hex($cmd);
	$self->STORE('plb_recv_stat',sprintf('%d',$cmd));
	return($pkt,$cmd,$len,$data);
}

sub DESTROY {
	my $dbh = shift;
	if ($dbh->FETCH('Active'))
	{
		$dbh->rollback unless $dbh->{AutoCommit};
		$dbh->disconnect;
	}
	undef;
}


package DBD::Plibdata::st;

$DBD::Plibdata::st::imp_data_size = 0;

sub STORE
{
	my ($sth, $attr, $val) = @_;
	if ($attr eq 'NAME' || $attr =~ m/^plb_/) 
	{
		$sth->{$attr} = $val;
		return 1;
	}
	# pass up unknowns to DBI to handle for us
	$sth->SUPER::STORE($attr, $val);
}

sub FETCH
{
	my ($sth, $attr) = @_;
	if ($attr =~ m/^plb_/) 
	{
		return $sth->{$attr};
	}
	# pass up unknowns to DBI to handle for us
	$sth->SUPER::FETCH($attr);
}


sub bind_param
{
	my ($sth, $pNum, $val, $attr) = @_;
	my $type = (ref $attr) ? $attr->{TYPE} : $attr;
	if ($type) 
	{
		my $dbh = $sth->{Database};
		$val = $dbh->quote($sth, $type);
	}
	my $params = $sth->{plb_params};
	$params->[$pNum-1] = $val;
	1;
}

sub execute
{
	my ($sth, @bind_values) = @_;
	my ($pkt, $cmd, $len, $data, $out, $err, $a, $cols, $n, $cnam, $chr, 
	$ctyp, $csiz);

	my $dbh = $sth->{Database};

	# start of by finishing any previous execution if still active
	$sth->finish if $sth->FETCH('Active');

	my $params = (@bind_values) ?  \@bind_values : $sth->{plb_params};
	my $numParam = $sth->FETCH('NUM_OF_PARAMS');
	return $sth->set_err(1, "Wrong number of parameters")
		if @$params != $numParam;
	my $statement = $sth->{'Statement'};
	for (my $i = 0;  $i < $numParam;  $i++) {
		$statement =~ s/\?/$params->[$i]/; # XXX doesn't deal with quoting etc!
	}

	DBD::Plibdata::db::_send_packet($dbh, $P_EXE, $statement);
	($pkt, $cmd, $len, $data) = DBD::Plibdata::db::_recv_packet($dbh);
	
	if ($cmd > 0x7fffffff)
	{
		$dbh->STORE('plb_err_stat',$dbh->FETCH('plb_recv_stat'));

		$err = $data || 'Error in SQL statement';
		$out = pack('C*',0x00,0x00,0x00,0x0b,0x00,0x00,0x00,0x00);
		DBD::Plibdata::db::_send_packet($dbh, $P_EACK, $out);
		($pkt, $cmd, $len, $data) = DBD::Plibdata::db::_recv_packet($dbh);
		$sth->STORE('Active', 0);
		$sth->finish;
		return $sth->set_err(1, $err);
	}

	if ($statement !~ /select/i)
	{
		$sth->{'plb_rows'} = $data || "0e0"; # number of rows
		$sth->STORE('Active', 1);
		return $sth->FETCH('plb_rows');
	}

	$cols = unpack('N', substr($data, 0, 4));
	$a = [];
	$n = 4;

	for (1 .. $cols)
	{
		$cnam = $chr = '';

		do {
			$cnam .= $chr;
			$chr = substr($data, $n , 1);
			$n++;
		} until ($chr eq '=');

		$ctyp = unpack('H8', substr($data, $n, 4));
		$n += 4;

		$ctyp = substr($ctyp, 6, 2);

		unless ($ctyp eq $T_INT || $ctyp eq $T_CHAR 
		 || $ctyp eq $T_FLOT || $ctyp eq $T_DATE)
		{
			return $sth->set_err(1,  "DBD::Plibdata doesn't understand var type: $ctyp \n");
		}

		$csiz = unpack('N', substr($data, $n, 4));
		$n += 4;

		$a->[$_ - 1] = $cnam;
	}

	$sth->STORE('plb_rowcache', []);
	$sth->STORE('NAME', $a);
	$sth->STORE('NUM_OF_FIELDS', $cols);
	$sth->STORE('Active', 1);
	"0e0";
}

sub fetchrow_arrayref
{
	my ($sth) = @_;
	my ($pkt, $cmd, $len, $data, $out, $row, $ar);

	$ar = shift @{$sth->FETCH('plb_rowcache')};
	return $sth->_set_fbav($ar) if (defined $ar);

	if ($sth->FETCH('plb_lastpkt'))
	{
		$sth->STORE('Active', 0);
		return undef;
	}

	return $sth->set_err(1, "Sth not active") unless $sth->FETCH('Active');
	my $dbh = $sth->{Database};

	$out = pack('C*',0x00,0x00,0x00,0x01);
	$out .= 'request=';
	$out .= pack('C*',0x04,0x00,0x00,0x00,0x04,0x00,0x00,0x00,
			$dbh->FETCH('plb_RowsPerPacket'));

	DBD::Plibdata::db::_send_packet($dbh, $P_FTCH, $out);
	($pkt, $cmd, $len, $data) = DBD::Plibdata::db::_recv_packet($dbh);

	if ($cmd == $P_ERR)
	{
		return $sth->set_err(1,  $data);
	}
	elsif ($cmd < $dbh->FETCH('plb_RowsPerPacket'))
	{
		$sth->STORE('plb_lastpkt', 1);
	}

	$row = DBD::Plibdata::st::_parse_input($sth, $data, $cmd);

	return $sth->_set_fbav($row) if $row;

	$sth->STORE('Active', 0);
	return undef;
}
*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref

sub _parse_input
{
	my ($sth, $in, $rows) = @_;
	my ($hex, $fields, $n, $type, $len, $str, $sign, $exp, $mant, $cnt);

	return undef unless $in;

	$hex = unpack('H*', $in);

	for (1 .. $rows)
	{
		my $ar = [];

		$fields = hex(substr($hex, 0, 8, ''));
		if ($fields != @{$sth->FETCH('NAME')})
		{
			$sth->set_err(1, "Number of fetched columns does not match");
		}
	
		for $n (0 .. $fields - 1)
		{
			$type = substr($hex, 0, 2, '');

			if ($type eq $T_INT)
			{
				substr($hex, 0, 8, ''); # rm 0...4
				$ar->[$n] = hex(substr($hex, 0, 8, ''));
				$ar->[$n] = "\0" if $ar->[$n] == 2147483648;
			}
			elsif ($type eq $T_FLOT)
			{
				substr($hex, 0, 8, ''); # rm 0...8
				$str	= unpack('B64', pack('H16', substr($hex, 0, 16, '')));
				$sign	= substr($str, 0, 1);
				$exp	= substr($str, 1, 11);
				$mant	= '1' . substr($str, 12, 52);
	
				if ($exp eq '11111111111')
				{
					$ar->[$n] = "\0";
				}
				elsif ($exp eq '11111111110')
				{
					$ar->[$n] = 1;
				}
				elsif ($exp eq '00000000000')
				{
					$ar->[$n] = 0;
				}
				else
				{
					$exp = unpack('n', pack('B16', "00000$exp")) - 1023;
					$str = 0.0;
					$cnt = 1;
					for (split(//, $mant))
					{
						$cnt--;
						next unless $_ == 1;
						$str += 2**$cnt;
					}
	
					$ar->[$n] = $str * 2**$exp;
					$ar->[$n] = -$ar->[$n] if $sign == 1;
				}
			}
			elsif ($type eq $T_CHAR || $type eq $T_DATE)
			{
				$len = hex(substr($hex, 0, 8, ''));
				$ar->[$n] = pack('H*', substr($hex, 0, $len * 2, ''));
			}
			else
			{
				$sth->set_err(1, "DBD::Plibdata doesn't understand var type: $type \n");
			}
		}

		push @{$sth->FETCH('plb_rowcache')}, $ar;
	}

	return shift @{$sth->FETCH('plb_rowcache')};
}

sub rows 
{
	my $sth = shift;
	return $sth->FETCH('plb_rows');
}

sub finish
{ 
	my ($sth) = @_;
	my $ar = $sth->FETCH('plb_rowcache');
	@$ar = () if defined $ar;
	$sth->STORE('Active', 0);
}

sub DESTROY 
{
	my $sth = shift;
	$sth->finish if $sth->FETCH('Active');
}

1;
__END__

=pod

=head1 NAME

DBD::Plibdata - a DBI driver for Jenzabar's Plibdata/cisaps access method for CX systems

=head1 SYNOPSIS

 use strict;
 use DBI;
 my $dbh = DBI->connect("dbi:Plibdata:host=$HOSTNAME;port=$PORT", 
                     $USERNAME, $PASSWORD, {PrintError => 0});
 my $sql = "SELECT fullname FROM id_rec WHERE id = 1";
 my ($name) = $dbh->selectrow_array($sql);
 
 $sql =<<EOT;
 SELECT txt
 FROM runace_aps 
 WHERE ace = '/opt/carsi/install/arc/hr/acereport.arc'
 AND params = '';
 EOT
 my ($acetxt) = $dbh->selectrow_array($sql);

=head1 DESCRIPTION

Jenzabar's Plibdata provides access to many appservers including ACE reports via
runace_aps. It also supports rudimentary SQL statements.

=head2 Parameters for DBI->connect()

* host. Required. Hostname of Plibdata/cisaps server.

* port. Required. Service name in /etc/services or port number.

=head2 Database Handle Attributes

* plb_RowsPerPacket. Range: 1 - 255. Default: 40. This is the number of rows the server will return in one fetch.  Although performance on multiple row queries can increase by setting this higher than the default, keep in mind that since the client caches every received row, memory usage will grow proportionally.

=head1 UNSUPPORTED

 . SQL is not parsed except for bind variable markers (question marks). 
 . Blank passwords
 . Aggregate functions
 . Calls to stored procedures
 . CREATE, DROP, SELECT INTO, etc.
 . SERIAL8, INT8, BYTE, BLOB/CLOB probably don't work
 
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

L<DBI>, L<DBD::Informix>, L<DBI::DBD>, L<IO::Socket::INET>, L<Digest::MD5>

=cut
