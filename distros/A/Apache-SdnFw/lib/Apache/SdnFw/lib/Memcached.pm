# $Id: $
package Apache::SdnFw::lib::Memcached;

use strict;
use Carp;
use Cache::Memcached;

BEGIN {
	use Exporter;
	our @ISA = qw(Exporter);
	our @EXPORT = qw(
		get_memd setkey getkey);
}

sub get_memd {
	my $s = shift;

	my $memd = new Cache::Memcached { servers => [ '127.0.0.1:11211' ] };

	$s->{memd} = $memd if (defined($memd));
}

sub setkey {
	my $s = shift;
	my $key = shift;
	my $data = shift;
	my $cache_for = shift;

	return 0 unless($s->{memd});
	return 0 unless($key);

	if (!defined $data) { $data = "\0u";
	} elsif (ref $data eq 'ARRAY') { $data = "\0a" unless(defined(@$data));
	} elsif (ref $data eq 'HASH') { $data = "\0h" unless(defined(%$data));
	} elsif (ref $data eq 'SCALAR') { $data = "\0s" unless(defined($$data)); }

#	print STDERR "setting $key to $data\n";
	return $s->{memd}->set("$s->{ubase}$key",$data,$cache_for);
}

sub getkey {
	my $s = shift;
	my $key = shift;
	my $data = shift;
	my $t = shift; # what data type do we want back?

	return 0 unless($s->{memd});
	return 0 unless($key);
#	print STDERR "checking for $key\n";
	my $mdata = $s->{memd}->get("$s->{ubase}$key");
	return 0 unless($mdata);
#	print STDERR "found $key\n";

	unless(ref $mdata) {
		if ($mdata eq "\0u") { $mdata = undef;
		} elsif ($mdata eq "\0a") { $mdata = [];
		} elsif ($mdata eq "\0h") { $mdata = {};
		} elsif ($mdata eq "\0s") { $mdata = undef; }
	}

#	print STDERR Data::Dumper->Dump([$mdata])."\n";
	# make sure we are sending back the data that they want
	# in the right format
	if ($t eq 'scalar' && ref $mdata eq 'SCALAR') {
		$data = $$mdata;
		return 1;
	} elsif ($t =~ m/^(hash|hashhash|keyval)$/ && ref $mdata eq 'HASH') {
		foreach my $key (keys %{$mdata}) {
			$data->{$key} = $mdata->{$key};
		}
		return 1;
	} elsif ($t =~ m/^(arrayhash|array)$/ && ref $mdata eq 'ARRAY') {
		foreach my $ref (@{$mdata}) {
			push @{$data}, $ref;
		}
		return 1;
	} else {
		return 0;
	}
}

1;
