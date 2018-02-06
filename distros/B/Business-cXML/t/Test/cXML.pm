use 5.014;
use strict;
use warnings;

package Test::cXML;
use base 'Exporter';

use Clone qw(clone);

our @EXPORT_OK = qw(comparable);

# Resets/removes dynamic things from cXML documents hashes (or nodes, which
# are converted to hashes), transmission objects, etc.
sub comparable {
	my ($hash) = @_;
	$hash = $hash->toHash if ref($hash) =~ /^XML::LibXML::/;
	if (ref($hash) eq 'Business::cXML::Transmission') {
		# CAUTION: This XML reset makes the object UNUSABLE for further processing!
		$hash->{xml_doc}     = undef;
		$hash->{xml_root}    = undef;
		$hash->{_xml_payload} = undef;
		$hash->{_timestamp}   = 'timestamp';
		$hash->{epoch}       = 'epoch';
		$hash->{hostname}    = 'hostname';
		$hash->{randint}     = 'randint';
		$hash->{pid}         = 'pid';
		$hash->{_id}          = 'id';
	} elsif (ref($hash) eq 'HASH') {

		# cXML attributes to remove
		delete $hash->{__attributes}{timestamp} if exists $hash->{__attributes}{timestamp};
		delete $hash->{__attributes}{payloadID} if exists $hash->{__attributes}{payloadID};

		# Header/Sender/UserAgent will differ
		delete $hash->{Header}->[0]->{Sender}->[0]->{UserAgent}
			if exists $hash->{Header}
			&& exists $hash->{Header}->[0]->{Sender}
			&& exists $hash->{Header}->[0]->{Sender}->[0]->{UserAgent}
		;

		# ProfileResponse attribute to remove, Transaction[] to sort
		if (exists $hash->{Response}->[0]->{ProfileResponse}) {
			my $res = $hash->{Response}->[0]->{ProfileResponse}->[0];
			return $hash unless defined $res;

			delete $res->{__attributes}{effectiveDate};
			$res->{Transaction} = [
				sort { $a->{__attributes}{requestName} cmp $b->{__attributes}{requestName} } @{ $res->{Transaction} }
			];
		};

	};
	return $hash;
}

1;
