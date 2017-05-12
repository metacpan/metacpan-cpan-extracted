=pod

=head4 Help Request

Interface to retrieve Help content.

=over 4

=item Category

=back

=cut

package SQL::Amazon::Request::Help;

use SQL::Amazon::Request::Request;
use base qw(SQL::Amazon::Request::Request);

use strict;

sub new {
	my ($class, $subid, $req_attrs, $params, $store) = @_;
	my $obj = $class->SUPER::new('us');
	my %url_params = (
		'Service', 'AWSECommerceService',
		'SubscriptionId', $subid,
		'Operation', 'ItemLookup',
		'SearchIndex', $req_attrs->{SearchIndex},
		'ItemPage', 1,
		'ResponseGroup', 'Large');
	foreach (keys %$req_attrs) {
		next if ($_ eq 'SearchIndex');
		$url_params{ItemId} = ($req_attrs->{$_}{Operator} eq '=') ?
			$req_attrs->{$_}{Value} :
			join(',', @{$req_attrs->{$_}{Value}}),
		$url_params{IdType} = $req_attrs->{$_}{Name},
		next
			if ($_ eq 'Key');

		$url_params{$_} = $req_attrs->{$_}
			if (($_ eq 'Condition') || ($_ eq 'DeliveryMethod') ||
				($_ eq 'ISPUPostalCode'));
	}
	$url_params{MerchantId} = $req_attrs->{MerchantId} ||= 'Amazon';
	return $obj->{_errstr}
		unless $obj->SUPER::send_request(\%$url_params, $store);

	return $obj;
}
sub has_errors {
	my ($obj, $xml, $reqattrs) = @_;
	$obj->{_errstr} = 'Amazon ECS request failed: ' . 
		$xml->{Items}{Request}{Errors}{Error}{Message},
	return 1
		if $xml->{Items}{Request}{Errors}{Error};

	return undef;
}

sub more_results {
	my ($obj, $xml, $reqattrs) = @_;
	my $pages = $xml->{Items}{TotalPages};
	return ($reqattrs->{ItemPage} < $pages) ?
		++$reqattrs->{ItemPage} : undef;
}
1;

