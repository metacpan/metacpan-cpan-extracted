# $Id: $
package Apache::SdnFw::object::dbdb;

use strict;
use XML::Dumper;
use Carp;

sub config {
	my $s = shift;

	return {
		public => 1,
		functions => {
			list => 'List',
			},
		};
}

sub list {
	my $s = shift;

	$s->{nomenu} = 1;
#	$s->{content_type} = 'text/plain';

	my $sock = IO::Socket::INET->new(
		PeerAddr => '127.0.0.1',
		PeerPort => 11272,
		Proto => 'tcp'
		) || croak "Nothing running on that socket: $!";

	my $raw = <$sock>;
	$sock->close;

	my $dump = new XML::Dumper;
	my $xml = $dump->xml2pl($raw);

#	$s->{content} = "<pre>".Data::Dumper->Dump([\$xml])."</pre>";

	my %hash;

	foreach my $t (qw(page code)) {
		foreach my $k (qw(count avg)) {
			@{$hash{$t}{$k}} = (sort { 
				$xml->{$t}{$b}{$k} <=> $xml->{$t}{$a}{$k} 
				} (keys %{$xml->{$t}})
				);
		}
	}

#	$s->{content} .= "<pre>".Data::Dumper->Dump([\%hash])."</pre>";
	
	$s->tt('dbdb/list.tt', { $s => $s, hash => \%hash, xml => $xml });
}

1;
