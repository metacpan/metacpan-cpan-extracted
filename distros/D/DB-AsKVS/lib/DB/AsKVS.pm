package DB::AsKVS;
use strict;
use warnings;
use String::CRC32;
use DBI;
use Cache::Memcached::Fast;
#use Data::Dumper::Concise;

our $VERSION = '0.02';

sub new{
	my ($this, $p) = @_;
	my $self = {
		p => $p,
	};
	return bless($self, $this);
}

# for Public Function
sub create{
	my ($self, $rk) = @_;
	for my $h (@{$self->{p}->{rdbms}}){
=pod
		my $dbh = DBI->connect(
			"dbi:" . $_->{driver} . ":dbname=" . $_->{dbname} . ";host=" . $_->{host} . ";port=" . $_->{port},
			$_->{uid},
			$_->{pwd},
			$_->{opt},
		) || die $!;
=cut
		my $dsn = "dbi:" . $h->{driver} . ":" . join(";", map{$_ .= "=" . $h->{$_}; $_} grep{$_ !~ /driver|uid|pwd|opt/;} keys %{$h});
		my $dbh = DBI->connect($dsn, $h->{uid}, $h->{pwd}, $h->{opt}) ||die $!;
		$dbh->do("create table " . $rk . " (k varchar(100), t int, v blob, f boolean, key index_rk_k(k))engine=innoDB");
		$dbh->disconnect;
	}
}

sub put{
	my ($self, $rk, $k, $v) = @_;
	my $rdbms = $self->{p}->{rdbms}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{rdbms}})];
	my $memcached = $self->{p}->{memcached}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{memcached}})];
	my $mem = new Cache::Memcached::Fast({
		servers => [$memcached->{host} . ":" . $memcached->{port}],
	});
	$self->remove($rk,$k);
=pod
	my $dbh = DBI->connect(
		"dbi:" . $rdbms->{driver} . ":dbname=" . $rdbms->{dbname} . ";host=" . $rdbms->{host} . ";port=" . $rdbms->{port},
		$rdbms->{uid},
		$rdbms->{pwd},
		$rdbms->{opt},
	) || die $!;
=cut
	my $dsn = "dbi:" . $rdbms->{driver} . ":" . join(";", map{$_ .= "=" . $rdbms->{$_}; $_} grep{$_ !~ /driver|uid|pwd|opt/;} keys %{$rdbms});
	my $dbh = DBI->connect($dsn, $rdbms->{uid}, $rdbms->{pwd}, $rdbms->{opt}) ||die $!;
	$mem->set($rk . "_" . $k, $v);
	my $sth = $dbh->prepare("insert into $rk(k,t,v,f) values(?,?,?,?)");
	$sth->execute($k, time(), $v, 1);
	$sth->finish;
	$dbh->disconnect;
}

sub get{
	my ($self, $rk, $k) = @_;
	my $rdbms = $self->{p}->{rdbms}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{rdbms}})];
	my $memcached = $self->{p}->{memcached}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{memcached}})];
	my $mem = new Cache::Memcached::Fast({
		servers => [$memcached->{host} . ":" . $memcached->{port}],
	});
	my $d = $mem->get($rk . "_" . $k);
	if(!$d){
=pod
		my $dbh = DBI->connect(
			"dbi:" . $rdbms->{driver} . ":dbname=" . $rdbms->{dbname} .
			";host=" . $rdbms->{host} . ";port=" . $rdbms->{port},
			$rdbms->{uid},
			$rdbms->{pwd},
			$rdbms->{opt},
		) || die $!;
=cut
		my $dsn = "dbi:" . $rdbms->{driver} . ":" . join(";", map{$_ .= "=" . $rdbms->{$_}; $_} grep{$_ !~ /driver|uid|pwd|opt/;} keys %{$rdbms});
		my $dbh = DBI->connect($dsn, $rdbms->{uid}, $rdbms->{pwd}, $rdbms->{opt}) ||die $!;
		my $sth->prepare("select v from $rk where k=? and f=1 order by t desc");
		$sth->execute($k);
		while(my $r = $sth->fetchrow_arrayref){
			my @tmp = map{$_ = $_?$_:'';} @{$r};
			$d = $tmp[0];
			last if($d);
		}
		$mem->set($rk . "_" . $k, $d) if($d);
		$sth->finish;
		$dbh->disconnect;
	}
	return $d;
}

sub get_multi{
	my ($self, $rk, $k) = @_;
	my $d;
	for my $h (@{$self->{p}->{rdbms}}){
=pod
		my $dbh = DBI->connect(
			"dbi:" . $_->{driver} . ":dbname=" . $_->{dbname} . ";host=" . $_->{host} . ";port=" . $_->{port},
			$_->{uid},
			$_->{pwd},
			$_->{opt},
		) || die $!;
=cut
		my $dsn = "dbi:" . $h->{driver} . ":" . join(";", map{$_ .= "=" . $h->{$_}; $_} grep{$_ !~ /driver|uid|pwd|opt/;} keys %{$h});
		my $dbh = DBI->connect($dsn, $h->{uid}, $h->{pwd}, $h->{opt}) ||die $!;
		my $sth = $dbh->prepare("select * from $rk where k like ? and f=1");
		$sth->execute($k . '%');
		while(my $r = $sth->fetchrow_arrayref){
			my @tmp = map{$_ = $_?$_:''} @{$r};
			$d->{$rk . "_" . $tmp[0]} = $tmp[2];
		}
		$sth->finish;
		$dbh->disconnect;
	}
	return $d;
}

sub remove{
	my ($self, $rk, $k) = @_;
	my $rdbms = $self->{p}->{rdbms}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{rdbms}})];
	my $memcached = $self->{p}->{memcached}->[crc32($rk . "_" . $k)%scalar(@{$self->{p}->{memcached}})];
	my $mem = new Cache::Memcached::Fast({
		servers => [$memcached->{host} . ":" . $memcached->{port}],
	});
	$mem->delete($rk . "_" . $k) if($mem->get($rk . "_" . $k));
=pod
	my $dbh = DBI->connect(
		"dbi:" . $rdbms->{driver} . ":dbname=" . $rdbms->{dbname} . ";host=" . $rdbms->{host} . ";port=" . $rdbms->{port},
		$rdbms->{uid},
		$rdbms->{pwd},
		$rdbms->{opt},
	) || die $!;
=cut
	my $dsn = "dbi:" . $rdbms->{driver} . ":" . join(";", map{$_ .= "=" . $rdbms->{$_}; $_} grep{$_ !~ /driver|uid|pwd|opt/;} keys %{$rdbms});
	my $dbh = DBI->connect($dsn, $rdbms->{uid}, $rdbms->{pwd}, $rdbms->{opt}) ||die $!;
	my $sth = $dbh->prepare("update $rk set f=0 where k=?");
	$sth->execute($k);
	$sth->finish;
	$dbh->disconnect;
}

1;

=head1 NAME

DB::AsKVS - This module is using RDBMS as KVS.

=head1 SYNOPSIS

 #!/usr/bin/perl
 use strict;
 use warnings;
 use DB::AsKVS;

 my $param = {
   rdbms => [
      {
         driver => 'mysql',
         dbname => 'demo',
         host => 'localhost',
         port => 3306,
         uid => 'root',
         pwd => 'password',
         opt => {},
      },
   ],
   memcached => [
      {
         host => 'localhost',
         port => 11211,
      },
   ], 
 };
 my $db = new DB::AsKVS($param);
 $db->create("RowKey");
 $db->put("RowKey", "Key", "Value");
 print $db->get("RowKey", "Key");

=head1 DISCRIPTION

The DB::AsKVS module can use RDBMS as KVS.
To use this module, You will be able to design architecture for scale out.

=head1 Usage
 
Constructor

 my $db = new DB::AsKVS($param);
 * $param is parameter of RDBMS and Memcached.
   Please show SYNOPSIS section.

Methods

 $db->create("RowKey");
 Create the RowKey.

 $db->put("RowKey", "Key", "Value");
 insert data.

 my $return_vaule = $db->get("RowKey", "Key");
 This method pick up the data for matching "RowKey" and "Key".
 $return_value is scalar value.

 my $return_value = $db->get_multi("RowKey", "Part of Key value");
 This method pick up the data for matching "RowKey" and "Key".
 $return_value is hash reference of Key and Value.

 $db->remove("RowKey", "Key");
 This method is deleteing data for matching "RowKey" and "Key".

=head1 Copyright

Kazunori Minoda (C)2013

=cut

