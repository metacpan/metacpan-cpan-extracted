# $Id: $
package Apache::SdnFw::lib::DB;

use strict;
use Carp;
use Time::HiRes qw(time);
use DBI;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw(
		db_connect db_connect_sybase db_connect_mysql
		db_q db_insert db_update_key db_update_where);

#	if (defined($ENV{MOD_PERL})) {
#		#print STDERR "using Apache::DBI\n";
#		eval "use Apache\:\:DBI";
#		print STDERR $@ if ($@);
#	} else {
#		#print STDERR "using DBI\n";
#		eval "use DBI";
#		print STDERR $@ if ($@);
#	}
}

sub db_connect_sybase {
	my $db_string = shift;
	my $db_user = shift;
	my $db_pass = shift;

	my $dbh = DBI->connect("dbi:Sybase:$db_string",$db_user,$db_pass, { RaiseError => 1, Warn => 0 });
	$dbh->{RaiseError} = 0;

	return $dbh;
}

sub db_connect_mysql {
	my $db_string = shift;
	my $db_user = shift;
	my $db_pass = shift;

	my $dbh = DBI->connect("dbi:mysql:$db_string",$db_user,$db_pass, { RaiseError => 1, Warn => 0 });

	$dbh->{RaiseError} = 0;

	return $dbh;
}

sub db_connect {
	my $db_string = shift;
	my $db_user = shift;

	my $dbh = DBI->connect("dbi:Pg:$db_string",$db_user,undef, { RaiseError => 1, Warn => 0 });
	$dbh->{RaiseError} = 0;

	return $dbh;
}

sub debug_start {
	my $s = shift;
	my $q = shift; #query

	return undef unless($s->{dbdbst});

	my $t = time-$s->{dbdbst};

	my $c = shift; # caller
	my $nt = sprintf "%.4f", $t;
	my @nc = split ' ', $c;

	$s->{dbdbdata} .= "---|$nt|$nc[2]|$nc[0]|";

	return time; # time we started query
}

sub debug_end {
	my $s = shift;
	my $sq = shift; # time query started

	return unless($sq);

	my $cache_used = (shift) ? '*' : '';

	my $t = time-$sq;
	my $nt = sprintf "%.4f", $t;
	$s->{dbdbdata} .= "$nt|$cache_used\t";
}

=head2 db_insert

 $s->db_insert($table,\%data,[$keyfield]);

=cut

sub db_insert {
	my $s = shift;
	my $dbh = $s->{dbh};
	my $table = shift;
	my $data = shift;
	my $keyfield = shift;

	my (@keys,@values,$key,@bind);

	foreach $key (keys %$data) {
		next if ($data->{$key} eq '');
		next if ($data->{$key} eq 'NULL');
		push @keys, qq($key);
		if ($data->{$key} =~ m/^_raw:(.+)$/) {
			push @bind, $1;
			next;
		}
		push @bind, '?';
		push @values, $data->{$key};
	}

	my $columns = join ',', @keys;
	my $bind = join ',', @bind;

	my $query = qq|INSERT INTO $table ($columns) VALUES ($bind)|;
	if ($keyfield) {
		$query .= " RETURNING $keyfield";
	}

	my $st = debug_start($s,$query,(join ' ', caller)); # if (defined($s->{dbdbf}));

	my $sth;
	croak $dbh->errstr."\n$query\n\n" unless($sth = $dbh->prepare($query));
	croak $dbh->errstr."\n$query\n@values\n" unless($sth->execute(@values));

	debug_end($s,$st); # if (defined($s->{dbdbf}));

	if ($keyfield) {
		my $id = ($sth->fetchrow_array)[0];
		$sth->finish;
		return $id;
	} else {
		$sth->finish;
		return '';
	}
}

=head2 db_update_key

 $s->db_update_key($table,$keyfield,$keyid,\%data);

=cut

sub db_update_key {
	my $s = shift;
	my $dbh = $s->{dbh};
	my $table = shift;
	my $keyfield = shift; # can be item_id or item_id:location_id
	my $keyid = shift; # can be 1235 or 1234:7890
	my $data = shift;

	my (@keys,@values);

	my @keyfields;
	foreach my $kf (split ':', $keyfield) {
		push @keyfields, "$kf=?";
	}

	foreach my $key (keys %$data) {
		if ($data->{$key} eq '' || $data->{$key} eq 'NULL') {
			push @keys, qq($key=NULL);
			next;
		}
		if ($data->{$key} =~ /^_raw:(.+)$/) {
			push @keys, qq($key=$1);
			next;
		}
		push @keys, qq($key=?);
		push @values, $data->{$key};
	}
	
	my $columns = join ',', @keys;
	push @values, (split ':', $keyid);

	my $where = join ' AND ', @keyfields;
	my $query = qq|UPDATE $table SET $columns WHERE $where|;

	my $st = debug_start($s,$query,(join ' ', caller)); # if (defined($s->{dbdbf}));

	my $sth;
	croak $dbh->errstr."\n$query\n\n" unless($sth = $dbh->prepare($query));
	croak $dbh->errstr."\n$query\n\n" unless($sth->execute(@values));
	$sth->finish;

	debug_end($s,$st); # if (defined($s->{dbdbf}));
}

=head2 db_update_where

 $s->db_update_where($table,$where,\%data);

=cut

sub db_update_where {
	my $s = shift;
	my $dbh = $s->{dbh};
	my $table = shift;
	my $where = shift;
	my $data = shift;

	my (@keys,@values);

	foreach my $key (keys %$data) {
		if ($data->{$key} eq '' || $data->{$key} eq 'NULL') {
			push @keys, qq($key=NULL);
			next;
		}
		if ($data->{$key} =~ /^_raw:(.+)$/) {
			push @keys, qq($key=$1);
			next;
		}
		push @keys, qq($key=?);
		push @values, $data->{$key};
	}
	
	my $columns = join ',', @keys;

	my $query = qq|UPDATE $table SET $columns WHERE $where|;

	my $st = debug_start($s,$query,(join ' ', caller)); # if (defined($s->{dbdbf}));

	my $sth;
	croak $dbh->errstr."\n$query\n\n" unless($sth = $dbh->prepare($query));
	croak $dbh->errstr."\n$query\n\n" unless($sth->execute(@values));
	$sth->finish;

	debug_end($s,$st); # if (defined($s->{dbdbf}));
}

=head2 db_q

 $s->db_q($query,[$t],[%args]);

Runs given $query and optionally returns data in structure defined by $t.

Values of $t: (scalar,hash,array,keyval,hashhash,arrayhash,importfile,csv)

=cut

sub db_q {
	my $s = shift;
	my $query = shift;
	my $t = shift || '';
	my %args = @_;

	my $dbh = $s->{dbh};

	if ($args{c} && defined($s->{memd})) {
		if ($t eq 'scalar') {
			my $return;
			if ($s->getkey($args{c},\$return,$t)) {
				return $return;
			}
		} elsif ($t =~ m/^(hash|hashhash|keyval)$/) {
			my %return;
			if ($s->getkey($args{c},\%return,$t)) {
				return %return;
			}
		} elsif ($t =~ m/^(arrayhash|array)$/) {
			my @return;
			if ($s->getkey($args{c},\@return,$t)) {
				return @return;
			}
		}
	}

	my $v = $args{v} if ($args{v});

	my $st = debug_start($s,$query,(join ' ', caller)); # if (defined($s->{dbdbf}));

	my $sth;
	croak $dbh->errstr."\n$query\n\n" unless($sth = $dbh->prepare($query));
	croak $dbh->errstr."\n$query\n\n" unless($sth->execute(@{$v}));

	debug_end($s,$st); # if (defined($s->{dbdbf}));

	# how do we want the returned data?
	if ($t eq 'hash') {
		my %return;
		my $hash = $sth->fetchrow_hashref;
		foreach my $k (keys %{$hash}) {
			$return{$k} = $hash->{$k};
		}
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},\%return,$args{cache_for});
		}
		return %return;
	} elsif ($t eq 'array') {
		my @return;
		while (my @row = $sth->fetchrow_array ) {
			push @return, $row[0];
		}
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},\@return,$args{cache_for});
		}
		return @return;
	} elsif ($t eq 'hashhash') {
		croak "undefined key field k in args" unless($args{k});
		my %return;
		while (my $hash = $sth->fetchrow_hashref ) {
			foreach my $k (keys %{$hash}) {
				$return{$hash->{$args{k}}}{$k} = $hash->{$k};
			}
		}
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},\%return,$args{cache_for});
		}
		return %return;
	} elsif ($t eq 'scalar') {
		my $return = ($sth->fetchrow_array)[0];
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},$return,$args{cache_for});
		}
		return $return;
	} elsif ($t eq 'keyval') {
		my %return;
		while (my @row = $sth->fetchrow_array ) {
			$return{$row[0]} = $row[1];
		}
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},\%return,$args{cache_for});
		}
		return %return;
	} elsif ($t eq 'arrayhash') {
		my @return;
		while (my $hash = $sth->fetchrow_hashref ) {
			push @return, { %{$hash} };
		}
		$sth->finish;
		if (defined($s->{memd}) && $args{c}) {
			$s->setkey($args{c},\@return,$args{cache_for});
		}
		return @return;
	} elsif ($t eq 'importfile') {
		my $cols = $sth->{NAME};
		croak "undefined file field f in args" unless($args{f});
		croak "undefined table import name t in args" unless($args{t});
		my %lookup;
		my $n = length @{$cols};
		for my $i ( 0 .. $n+1 ) {
			$lookup{$cols->[$i]} = $i;
		}
		#croak "test".Data::Dumper->Dump([\%lookup]);
		open F, ">$args{f}";
		print F "COPY $args{t} (".(join ',', @{$cols}).") FROM STDIN;\n";
		while (my @row = $sth->fetchrow_array) {
			for my $i ( 0 .. $#row ) {
				$row[$i] = '\N' if ($row[$i] eq '' || $row[$i] eq undef);
				$row[$i] =~ s/\t//g;
				$row[$i] =~ s/\r/\\r/g;
				$row[$i] =~ s/\n/\\n/g;
			}

			if ($args{forceid}) {
				my $sn = $lookup{$args{forceid}};
				unless($row[$sn] =~ m/^\d+$/) {
					#print "invalid $row[$sn]\n";
					next;
				}
			}

			if ($args{splitid}) {
				my $sn = $lookup{$args{splitid}};
				my $list = $row[$sn];
				#print "Checking $list\n";
				foreach my $value (split /,\s*/, $list) {
					#print "value $value\n";
					next unless($value);
					($row[$sn] = $value) =~ s/\s//g;
					print F (join "\t", @row)."\n";
				}
			} else {
				print F (join "\t", @row)."\n";
			}
		}
		print F "\\.\n";
		$sth->finish;
		close F;
	} elsif ($t eq 'csv' || $t eq 'text') {
		my $cols = $sth->{NAME};
		#croak "<pre>".Data::Dumper->Dump([$cols])."</pre>";
		croak "undefined file field f in args" unless($args{f});
		#croak "undefined header field h in args" unless($args{h});
		my %restrict;
		if (defined($args{restrict_columns})) {
			my $tmp;
			for my $i ( 0 .. $#{$cols} ) {
				unless (defined($args{restrict_columns}{$cols->[$i]})) {
					push @{$tmp}, $cols->[$i];
				} else {
					$restrict{$i} = 1;
				}
			}
			$cols = $tmp;
		}

		open F, ">$args{f}";

		# add some common stuff so we have to do less further on in the code
		$s->{r}{file_path} = $args{f};
		$s->{r}{filename} = $args{filename} || 'exportfile.csv';
		$s->{content_type} = 'text/plain' if ($t eq 'text');
		$s->{content_type} = 'application/csv' if ($t eq 'csv');
		print F '"'.(join '","', @{$cols}).'"'."\n";
		while (my @row = $sth->fetchrow_array ) {
			my @out;
			for my $i ( 0 .. $#row ) {
				if (defined($restrict{$i})) {
					next;
				}
				$row[$i] =~ s/"/""/g;
				push @out, $row[$i];
			}
			print F '"'.(join '","', @out).'"'."\n";
		}
		$sth->finish;
		close F;
		return;

	} elsif ($t) {
		croak "Unknown data return type t [$t]";
	}
}

1;
