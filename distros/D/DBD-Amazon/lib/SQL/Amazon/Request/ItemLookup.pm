#
#   Copyright (c) 2005, Presicient Corp., USA
#
# Permission is granted to use this software according to the terms of the
# Artistic License, as specified in the Perl README file,
# with the exception that commercial redistribution, either 
# electronic or via physical media, as either a standalone package, 
# or incorporated into a third party product, requires prior 
# written approval of the author.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Presicient Corp. reserves the right to provide support for this software
# to individual sites under a separate (possibly fee-based)
# agreement.
#
#	History:
#
#		2005-Jan-27		D. Arnold
#			Coded.
#
package SQL::Amazon::Request::ItemLookup;

use SQL::Amazon::Request::Request;
use SQL::Amazon::Parser qw(:pred_node_codes);
use Clone qw(clone);
use base qw(SQL::Amazon::Request::Request);

use Data::Dumper;

use strict;

our $errstr;

sub errstr {
	return $errstr
		if $errstr && $errstr ne ''; 

	return shift->{_errstr};
}

sub new {
	my $class = shift;
	my $req_attrs = {};
	my $predicate;
	if ($class eq 'SQL::Amazon::Request::ItemLookup') {
		$errstr = undef;
		$predicate = create_lookup_request($req_attrs, @_);

		return (undef, undef)
			if $errstr;
		return ($predicate, undef)
			unless scalar keys %$req_attrs;
	}
	else {
		$req_attrs = shift;
	}

	my $obj = $class->SUPER::new();
	my %url_params = (
		'Service', 'AWSECommerceService',
		'Operation', 'ItemLookup',
		'SearchIndex', delete $req_attrs->{SearchIndex},
		'ItemPage', 1,
		'ResponseGroup', 'Large');

	$obj->{url_params} = \%url_params;
	$obj->{req_attrs} = $req_attrs;
	return wantarray ? ($predicate, $obj) : $obj;
}
sub create_lookup_request {
	my ($request, $expr, $table, $parser) = @_;
	$request->{SearchIndex} = $table;
	my $conjoins = $expr->[0];
	my @finalcjs = ();
	foreach (@$conjoins) {
		my ($op, $left, $right, $neg) = @$_;
		my ($name, $value);
		if ($op eq 'USER_DEFINED') {

			$name = (ref $left ne 'HASH') ?
				$left->name() : $left->{name};

			push (@finalcjs, $_),
			next
				unless (uc $name eq 'AMZN_IN_ANY');

			if ($name eq 'AMZN_IN_ANY') {
				$op = 'IN';
				$value = (ref $left ne 'HASH') ?
					$left->args()->[0]{value} :
					$left->{value}{value}[0];
			}
		}

		push (@finalcjs, $_),
		next
			if ($neg && ($op eq 'IN'));
		push (@finalcjs, $_),
		next
			if ((ref $right eq 'HASH') && ($right->{type} eq 'column'));

		$name = ((ref $left eq 'HASH') && ($left->{type} eq 'column')) ?
			$left->{value} :
			($op eq 'IN') ? $value : $name;
		$name = uc $name;
		$table = uc $1
			if ($name=~s/^([A-Z]\w*)\.(\w+)/$2/);
		my $aliases = $parser->{struct}{column_aliases};
		$name = $aliases->{$name}
			if $aliases->{$name};
	
		push (@finalcjs, $_),
		next
			unless ($name=~/^[A-Z]\w*$/);
	
		if ($name=~/^ASIN|SKU|UPC|EAN$/) {
			push (@finalcjs, $_),
			next
				if (($op eq '<>') || (($op eq 'IN') && $neg));

			$errstr = "Invalid range predicate for $name.",
			return undef
				if ($op =~/^[<>]/);

			$request->{Key}{Name} = $name;
			$request->{Key}{Value} = ($op eq '=') ? 
				$right :
				clone($_);
		}
		elsif ($name eq 'CONDITION') {
			$errstr = "Unknown column CONDITION for table $table.",
			return undef
				unless (uc $table eq 'OFFERS');

			$errstr = 'Invalid range predicate for Condition.',
			return undef
				 if (($op =~/^[<>]/) || ($op eq 'LIKE') || ($op eq 'CLIKE'));

			$request->{Condition}{Value} = $right;
			$request->{Condition}{Complement} = 
				(($op eq '<>') || (($op eq 'IN') && $neg)) ? 1 : 0;
		}
		elsif ($name eq 'DELIVERYMETHOD') {
			$errstr = 'Invalid range predicate for DeliveryMethod.',
			return undef
				 if (($op =~/^[<>]/) || ($op eq 'LIKE') || ($op eq 'CLIKE'));
			$request->{DeliveryMethod}{Value} = $right;
			$request->{DeliveryMethod}{Complement} = 
				(($op eq '<>') || (($op eq 'IN') && $neg)) ? 1 : 0;
		}
		elsif ($name eq 'ISPUPOSTALCODE') {
			$errstr = 'Invalid predicate: ISPUPOSTALCODE must be exact match.',
			return undef
				unless ($op eq '=');
			$request->{ISPUPostalCode}{Value} = $right;
		}
		elsif ($name eq 'MERCHANTID') {
			$errstr = 'Invalid predicate: MERCHANTID must be exact match.',
			return undef
				unless ($op eq '=');
			$request->{MerchantId} = $right;
		}
		else {
			push (@finalcjs, $_);
		}
	}
	$expr->[0] = \@finalcjs;
	return $expr;
}
sub populate_request {
	my ($obj, $subid, $locale, $stmt, $max_pages, $resp_group) = @_;

	$obj->{url_params}->{ResponseGroup} = $resp_group;
	$obj->{_max_pages} = $max_pages;
	
	return undef
		unless $obj->SUPER::populate_request($subid, $locale, $stmt);
	return $obj 
		unless (ref $obj eq 'SQL::Amazon::Request::ItemLookup');
	
	my $req_attrs = $obj->{req_attrs};
	my $url_params = $obj->{url_params};

	my $keys = $req_attrs->{Key}{Value};
	unless (ref $keys eq 'ARRAY') {
		$url_params->{ItemId} = 
			$stmt->get_row_value($keys, undef, {});
	}
	else {

	warn "Not IN ANY!\n"
		unless (($keys->[0] eq 'USER_DEFINED') &&
			$keys->[1]->isa('SQL::Statement::Util::Function'));

		$url_params->{ItemId} = $stmt->get_row_value($keys->[1], undef, {});
	}

	$url_params->{IdType} = $req_attrs->{Key}{Name};
	delete $url_params->{SearchIndex} 
		if ($req_attrs->{Key}{Name} eq 'ASIN');

	foreach ('Condition', 'DeliveryMethod', 'ISPUPostalCode') {
		$url_params->{$_} = $stmt->get_row_value($req_attrs->{$_}{Value}, undef, {})
			if defined($req_attrs->{$_});
	}

	$url_params->{MerchantId} = defined($req_attrs->{MerchantId}) ?
		$stmt->get_row_value($req_attrs->{MerchantId}, undef, {}) : 'Amazon';

	return $obj;
}
sub has_errors {
	my ($obj, $xml) = @_;
	
	my $reqattrs = $obj->{url_params};
	$obj->{_errstr} = "Amazon ECS request failed: $xml",
	return 1
		unless ref $xml;
	$obj->{_errstr} = 'Amazon ECS request failed: ' . 
		$xml->{Items}{Request}{Errors}{Error}{Message},
	return 1
		if ($xml->{Items}{Request}{Errors} &&
			($xml->{Items}{Request}{Errors}{Error}{Code} ne 
				'AWS.ECommerceService.NoExactMatches'));

	return undef;
}
sub advance_request_page {
	my $obj = shift;

	my $reqattrs = $obj->{url_params}{ItemPage}++;
	return $obj;
}

sub more_results {
	my ($obj, $xml) = @_;

	my $reqattrs = $obj->{url_params};
	my $pages = $xml->{Items}{TotalPages} || 1;

	$obj->{_warnmsg} = 
"Maximum result pages exceeded; returning $reqattrs->{ItemPage} pages of  $pages available.",
	return undef
		if ($reqattrs->{ItemPage} >= $obj->{_max_pages});

	return ($reqattrs->{ItemPage} < $pages) ?
		++$reqattrs->{ItemPage} : undef;
}
sub process_results {
	my ($obj, $xml, $store, $reqids) = @_;
	if (defined($xml->{Items}{TotalResults})) {
		return undef 
			unless $xml->{Items}{TotalResults};
		$obj->{_total_results} = $xml->{Items}{TotalResults};
		$obj->{_total_pages} = $xml->{Items}{TotalPages};
	}
	else {
		$obj->{_total_results} = 1;
		$obj->{_total_pages} = 1;
	}
	my $offerstbl = $store->get_table('Offers');
	my $offercols = $offerstbl->col_nums;

	my $listmaniatbl = $store->get_table('ListManiaLists');
	my $editrvwtbl = $store->get_table('EditorialReviews');
	my $custrvwtbl = $store->get_table('CustomerReviews');
	my $similartbl = $store->get_table('SimilarProducts');
	my $browsetbl = $store->get_table('BrowseNodes');
	my ($reqtype, $resptype) = $obj->isa('SQL::Amazon::Request::ItemSearch') ?
		('ItemSearchRequest', 'ItemSearchResponse') : 
		('ItemLookupRequest', 'ItemLookupResponse');
	my $search_index = $xml->{Items}{Request}{$reqtype}{SearchIndex} ||
		'Books';

	my $reqid = $xml->{OperationRequest}{RequestId};
	my $table = $store->get_table($search_index);
	$obj->add_to_cache($reqid, 
		($obj->{_total_pages} == $obj->{url_params}{ItemPage}));
	my $items = (ref $xml->{Items}{Item} eq 'ARRAY') ?
		$xml->{Items}{Item} :
		[ $xml->{Items}{Item} ];

	foreach my $item (@$items) {
		my $asin = $item->{ASIN};
		$table->insert($item, $asin, $reqid);
		my $attrs;
		if ($item->{Offers} && $item->{Offers}{Offer}) {
			$attrs = $item->{Offers}{Offer};
			if (ref $attrs eq 'ARRAY') {
				$offerstbl->insert($_, $asin, $reqid)
					foreach (@$attrs);
			}
			else {
				$offerstbl->insert($attrs, $asin, $reqid);
			}
		}
		$attrs = $item->{CustomerReviews};
		if ($attrs) {
			if (ref $attrs->{Review} eq 'ARRAY') {
				$attrs = $attrs->{Review};
				$_->{ASIN} = $asin,
				$_->{ReviewDate} = $_->{Date},
				delete $_->{Date},
				$custrvwtbl->insert($_, $reqid)
					foreach (@$attrs);
			}
			else {
				$attrs->{Review}{ReviewDate} = $attrs->{Review}{Date};
				delete $attrs->{Review}{Date};
				$attrs->{Review}{ASIN} = $asin;
				$custrvwtbl->insert($attrs->{Review}, $reqid);
			}
		}
		$attrs = $item->{EditorialReviews};
		if ($attrs) {
			if (ref $attrs->{EditorialReview} eq 'ARRAY') {
				$attrs = $attrs->{EditorialReview};
				$_->{ASIN} = $asin,
				$editrvwtbl->insert($_, $reqid)
					foreach (@$attrs);
			}
			else {
				$attrs->{EditorialReview}{ASIN} = $asin;
				$editrvwtbl->insert($attrs->{EditorialReview}, $reqid);
			}
		}
		$attrs = $item->{ListmaniaLists};
		if ($attrs) {
			if (ref $attrs->{ListManiaList} eq 'ARRAY') {
				$attrs = $attrs->{ListManiaList};
				$_->{ASIN} = $asin,
				$listmaniatbl->insert($_, $reqid)
					foreach (@$attrs);
			}
			else {
				$attrs->{ListManiaLists}{ASIN} = $asin;
				$listmaniatbl->insert($attrs->{ListManiaList}, $reqid);
			}
		}
		$attrs = $item->{SimilarProducts};
		if ($attrs) {
			if (ref $attrs->{SimilarProduct} eq 'ARRAY') {
				$attrs = $attrs->{SimilarProduct};
				$_->{SimilarASIN} = $_->{ASIN},
				$_->{ASIN} = $asin,
				$similartbl->insert($_, $reqid)
					foreach (@$attrs);
			}
			else {
				$attrs->{SimilarProduct}{SimilarASIN} = 
					$attrs->{SimilarProduct}{ASIN};
				$attrs->{SimilarProduct}{ASIN} = $asin;
 				$similartbl->insert($attrs->{SimilarProduct}, $reqid);
			}
		}
		$attrs = $item->{BrowseNodes};
		if ($attrs) {
			if (ref $attrs->{BrowseNode} eq 'ARRAY') {
				$attrs = $attrs->{BrowseNode}[0];
				while ($attrs) {
					$attrs = $attrs->{Ancestors}{BrowseNode};
					$browsetbl->insert({
						ASIN => $asin, 
						Name => $attrs->{Name},
						BrowseNodeId => $attrs->{BrowseNodeId}
						}, $reqid);
					$attrs = $attrs->{Ancestors};
				}
			}
			else {
				$attrs = $attrs->{BrowseNode};
				while ($attrs) {
					$browsetbl->insert({
						ASIN => $asin, 
						Name => $attrs->{Name},
						BrowseNodeId => $attrs->{BrowseNodeId}
						}, $reqid);
					$attrs = $attrs->{Ancestors}{BrowseNode};
				}
			}
		}
	}
	$reqids->{$reqid} = 1;
	return $obj->more_results($xml);
}

1;
