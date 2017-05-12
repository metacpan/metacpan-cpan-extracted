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
package SQL::Amazon::ReqFactory;
use SQL::Amazon::Request::Request;
use SQL::Amazon::Parser;
use SQL::Amazon::Parser qw(:pred_node_codes);

use strict;

our $VERSION = '0.10';

use constant HAS_KEYS => 1;
use constant HAS_MATCHES => 2;
my %is_search_function = qw(
AMZN_MATCH_ANY 1
AMZN_MATCH_ALL 1
AMZN_MATCH_TEXT 1
AMZN_POWER_SEARCH 1
);
my %can_search = qw(
CustomerContent SQL::Amazon::Request::CustomerContentSearch
Item SQL::Amazon::Request::ItemSearch
List SQL::Amazon::Request::ListSearch
SellerListing SQL::Amazon::Request::SellerListingSearch
);

my %can_lookup = qw(
BrowseNode SQL::Amazon::Request::BrowseNodeLookup
CustomerContent SQL::Amazon::Request::CustomerContentLookup
Item SQL::Amazon::Request::ItemLookup
List SQL::Amazon::Request::ListLookup
Seller SQL::Amazon::Request::SellerLookup
SellerListing SQL::Amazon::Request::SellerListingLookup
Transaction SQL::Amazon::Request::TransactionLookup
);

my %can_add = qw(
Cart SQL::Amazon::Request::CartAdd
);

my %can_clear = qw(
Cart SQL::Amazon::Request::CartClear
);

my %can_create = qw(
Cart SQL::Amazon::Request::CartCreate
);

my %can_get = qw(
Cart SQL::Amazon::Request::CartGet
);

my %can_modify = qw(
Cart SQL::Amazon::Request::CartModify
);

our $errstr;
sub errstr { return $errstr; }

sub create_request {
	my ($class, $reqclass, $table, $predicate, $parser) = @_;

	my $command = $parser->{struct}{command};
	$errstr = $command . " unsupported on $table.",
	return (undef, undef)
		unless (
			(($command eq 'CREATE') && $can_create{$reqclass}) ||
			(($command eq 'DELETE') && $can_clear{$reqclass}) ||
			(($command eq 'INSERT') && $can_add{$reqclass}) ||
			(($command eq 'UPDATE') && $can_modify{$reqclass}) ||
			(($command eq 'SELECT') && 
				($can_search{$reqclass} ||
					$can_lookup{$reqclass} ||
					$can_get{$reqclass}))
			);

	$errstr = 'Only SELECT operation supported in this release.',
	return (undef, undef)
		unless ($command eq 'SELECT');

	my $flags = classify_request_type($predicate, 0);

	$errstr = "$table does not support MATCHES predicate.",
	return (undef, undef)
		if (($flags & HAS_MATCHES) && (!$can_search{$reqclass}));
	my $reqobj;	

	$reqclass = (($flags & HAS_MATCHES) || (! ($flags & HAS_KEYS))) ? 
			$can_search{$reqclass} : $can_lookup{$reqclass};

	($predicate, $reqobj) = ${reqclass}->new($predicate, $table, $parser);
	$errstr = ${reqclass}->errstr,
	return (undef, undef)
		unless ($predicate || $reqobj);
	return ($predicate, $reqobj);
}
sub classify_request_type {
	my ($expr, $flags) = @_;

	my $conjoins = $expr->[0];
	foreach (@$conjoins) {

		$flags |= HAS_KEYS,
		next
			if (($_->[SQL_TREE_OP] eq '=') &&
				($_->[SQL_TREE_ARG1]{type} eq 'column') &&
				($_->[SQL_TREE_ARG1]{value}=~
					/^([A-Z_]\w*\.)?(ASIN|UPC|SKU|EAN)$/i) &&
				(! $_->[SQL_TREE_NEG]));

		next unless ($_->[SQL_TREE_OP] eq 'USER_DEFINED');
		my $name;
		$name = (ref $_ ne 'HASH') ?
			$_->[SQL_TREE_ARG1]->name :
			$_->[SQL_TREE_ARG1]{name};

		$flags |= HAS_MATCHES,
		next
			if $is_search_function{$name};
		my $value = (ref $_ ne 'HASH') ?
			$_->[SQL_TREE_ARG1]->args :
			$_->[SQL_TREE_ARG1]{value};

		$flags |= HAS_KEYS
			if (($name eq 'AMZN_IN_ANY') &&
				($value->[0]{value}=~
					/^([A-Z_]\w*\.)?(ASIN|UPC|SKU|EAN)$/i) &&
				(! $_->[SQL_TREE_NEG])
				);
	}
	return $flags;
}
sub cleanup_requests {
	my ($class, $requests) = @_;
	
	my @sorted_reqs = ();
	my @remaining = ();
	foreach (@$requests) {
		push(@sorted_reqs, $_)
			if ($_->[0] eq 'Item');
	}
	foreach (@$requests) {
		push @remaining, $_
			unless (($_->[0] eq 'Item') || 
				(scalar @sorted_reqs));
	}
	push @sorted_reqs, @remaining
		if scalar @remaining;
	return \@sorted_reqs;
}

1;