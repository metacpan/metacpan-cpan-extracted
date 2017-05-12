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

package SQL::Amazon::Request::ItemSearch;

use SQL::Amazon::Request::ItemLookup;
use SQL::Amazon::Parser qw(:pred_node_codes);
use base qw(SQL::Amazon::Request::ItemLookup);

use strict;
my %is_power_col = (
'TITLE', [ 'title', 1 ],
'SUBJECT', [ 'subject', undef ],
'AUTHORS', [ 'author', 1 ],
'PUBLISHER', [ 'publisher', 1 ],
'LANGUAGE', [ 'language', undef ],
);
my %is_search_col = (
'TITLE', [ 'Title', '*', 1 ],
'AUTHORS', [ 'Author', 'Books', 1 ],
'PUBLISHER', [ 'Publisher', 'Books', 1 ],
'ARTIST', [ 'Artist', '*', 1 ],
'ACTOR', [ 'Actor', '*', 1 ],
'DIRECTOR', [ 'Director', '*', 1 ],
'MANUFACTURER', [ 'Manufacturer', '*', 1 ],
'MUSICLABEL', [ 'MusicLabel', '*', 1 ],
'COMPOSER', [ 'Composer', '*', 1 ],
'BRAND', [ 'Brand', '*', 1 ],
'CONDUCTOR', [ 'Conductor', '*', 1 ],
'ORCHESTRA', [ 'Orchestra', '*', 1 ],
'CITY', [ 'City', 'Restruants', 1 ],
'CUISINE', [ 'Cuisine', 'Restruants', 1 ],
'NEIGHBORHOOD', [ 'Neighborhood', 'Restruants', 1 ],
'MERCHANTID', [ 'MerchantID', 'Offers', undef ],
'CONDITION', [ 'Condition', 'Offers', undef ],
'DELIVERYMETHOD', [ 'DeliveryMethod', 'Offers', undef ],
);
my %can_power_search = qw(
BOOKS 1
);
my %is_amzn_function = qw(
AMZN_POWER_SEARCH 1
AMZN_IN_ANY 1
AMZN_MATCH_ANY 1
AMZN_MATCH_ALL 1
AMZN_MATCH_TEXT 1
);

our $errstr;

sub errstr {
	return $errstr
		if $errstr && $errstr ne ''; 

	return shift->{_errstr};
}

sub new {
	my $class = shift;
	my $req_attrs = {
		Power => {
			Explicit => [],
			Keywords => [],
			title	=> undef,
			subject	=> [],
			author	=> [],
			publisher	=> undef,
			language	=> undef
		},
		Keywords => [],
	};
	$errstr = undef;
	my $predicate = create_search_request($req_attrs, @_);

	return (undef, undef)
		if $errstr;
	return ($predicate, undef)
		unless scalar keys %$req_attrs;

	my $obj = $class->SUPER::new($req_attrs);

	$obj->{url_params}{Operation} = 'ItemSearch';
	$obj->{req_attrs} = $req_attrs;
	return ($predicate, $obj);
}

sub create_search_request {
	my ($request, $expr, $table, $parser) = @_;
	$request->{SearchIndex} = $table;
	my $conjoins = $expr->[0];
	my @finalcjs = ();
	foreach (@$conjoins) {
		my ($op, $left, $right, $neg) =  @$_;
		$table = uc $table;
		my ($name, $value);
		if ($op eq 'USER_DEFINED') {

			$name = (ref $left ne 'HASH') ?
				$left->name() : $left->{name};

			push (@finalcjs, $_),
			next
				unless $is_amzn_function{uc $name};

			if ($name eq 'AMZN_IN_ANY') {
				$op = 'IN';
				$value = (ref $left ne 'HASH') ?
					$left->args()->{value}[0] :
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
			unless ($name=~/^[A-Z]\w*$/i);
		$name = 'ASIN' if ($name eq 'ISBN');

		if ($name eq 'ASIN') {
			push (@finalcjs, $_),
			next
				unless ($table eq 'BOOKS');

			push (@finalcjs, $_),
			next
				if ($op eq '<>');
			$request->{Power}{ASIN} = $right,
			next
				if ($op eq '=');

			push (@finalcjs, $_);
		}
		elsif ($can_power_search{$table} && $is_power_col{$name}) {
			push (@finalcjs, $_),
			next
				if ($op eq '<>');
		
			$errstr = "Invalid range predicate for $name.",
			return undef
				if ($op =~/^[<>]/);

			if (($op eq 'LIKE') || ($op eq 'CLIKE')) {
				push (@finalcjs, $_),
				next
					if $neg;

				unless (defined($request->{Power}{$is_power_col{$name}[0]}) &&
					ref $request->{Power}{$is_power_col{$name}[0]}) {
					$request->{Power}{$is_power_col{$name}[0]} = $right;
				}
				else {
					push @{$request->{Power}{$is_power_col{$name}[0]}}, $right;
				}
				push (@finalcjs, $_)
					if $is_power_col{$name}[1];
			}
			elsif ($is_search_col{$name}) {
				$request->{$is_search_col{$name}[0]} = $right;
				push (@finalcjs, $_)
					if $is_search_col{$name}[2];
			}
			else {
				push (@finalcjs, $_);
			}
		}
		elsif ($name=~/^AMZN_MATCH_(ANY|ALL|TEXT)$/) {
			if ($name eq 'AMZN_MATCH_ANY') {
				$errstr = "Invalid MATCHES predicate for $table table.",
				return undef
					unless ($table eq 'BOOKS');
				push @{$request->{Power}{Keywords}}, $left->args();
			}
			elsif ($name eq 'AMZN_MATCH_ALL') {
				push @{$request->{Keywords}}, $left->args();
			}
			elsif ($name eq 'AMZN_MATCH_TEXT') {
				$request->{TextStream} = $left->args();
			}
		}
		elsif ($name=~/^AMZN_POWER_SEARCH$/) {
			$errstr = "Invalid POWER_SEARCH predicate for $table table.",
			return undef
				unless ($table eq 'BOOKS');
			push @{$request->{Power}{Explicit}}, $left->args();
		}
		elsif ($name eq 'AUDIENCERATING') {
			$request->{AudienceRating}{Values} = $right;
			$request->{AudienceRating}{Operator} = 
				(($op eq 'IN') && $neg) ? 'NOT IN' : $op;
			push (@finalcjs, $_);
		}
		elsif ($name eq 'LISTPRICEAMT') {
			$errstr = 'Invalid predicate: ListPriceAmt not valid with IN/LIKE/CLIKE.',
			return undef
				if (($op eq 'IN') || ($op eq 'LIKE') || ($op eq 'CLIKE'));

			push (@finalcjs, $_),
			next
				if (($op eq '=') || ($op eq '<>'));

			$request->{MaximumPrice} = $right
				if (($op eq '<') || ($op eq '<='));

			$request->{MinimumPrice} = $right
				if (($op eq '>') || ($op eq '>='));
		}
		elsif ($is_search_col{$name}) {
			$errstr = "Unknown column $name for table $table.",
			return undef
				unless (($is_search_col{$name}[1] eq '*') ||
					(uc $is_search_col{$name}[1] eq $table));

			push (@finalcjs, $_),
			next
				if (($op eq '<>') ||
					($op eq 'LIKE') || ($op eq 'CLIKE') ||
					($op eq 'IN'));

			$errstr = "Invalid range expression for $name.",
			return undef
				unless ($op eq '=');

			$request->{$is_search_col{$name}[0]} = $right;
			push (@finalcjs, $_)
				if $is_search_col{$name}[2];
		}
		else {
			push (@finalcjs, $_);
		}
	}
	$expr->[0] = \@finalcjs;
	return $expr;
}
sub create_power_search {
	my ($obj, $stmt) = @_;
	
	$obj->{_errstr} = undef;
	my $power = $obj->{req_attrs}->{Power};
	my $pwrstr = '';
	my $val;
	my @pwrparms = ();
	foreach my $expl (@{$power->{Explicit}}) {
		if (ref $expl eq 'ARRAY') {
			foreach (@$expl) {
				$val = $stmt->get_row_value($_, undef, {});
				push @pwrparms, $val
					if defined($val);
			}
		}
		else {
			$val = $stmt->get_row_value($expl, undef, {});
			push @pwrparms, $val
				if defined($val);
		}
	}
	$pwrstr = '(' . join(') and (', @pwrparms) . ')'
		if scalar @pwrparms;
	@pwrparms = ();
	foreach my $keys (@{$power->{Keywords}}) {
		if (ref $keys eq 'ARRAY') {
			foreach (@$keys) {
				$val = $stmt->get_row_value($_, undef, {});
				push @pwrparms, $val
					if defined($val);
			}
		}
		else {
			$val = $stmt->get_row_value($keys, undef, {});
			push @pwrparms, $val
				if defined($val);
		}
	}
	$pwrstr .= (($pwrstr ne '') ? ' and (keywords: ("' : '(keywords: ("') .
		join('" or "', @pwrparms) . '"))'
		if scalar @pwrparms;
	@pwrparms = ();
	foreach (keys %$power) {
		next if (($_ eq 'Explicit') || ($_ eq 'Keywords'));

		if (ref $power->{$_} eq 'HASH') {
			$val = $stmt->get_row_value($power->{$_}, undef, {});
			next unless defined($val);
			$val=~s/%%/\0/g;
			next if (substr($val,0, 1) eq '%');
			$val=~s/^(.+?)%/$1\*/;
			$val=~s/\0/%/g;
			push @pwrparms, (lc $_) . ': "' . $val . '"'; 
		}
		elsif (ref $power->{$_} eq 'ARRAY') {
			my @vals = ();
			foreach my $pwr (@{$power->{$_}}) {
				my $val = $stmt->get_row_value($pwr, undef, {});
				next unless defined($val);
				$val=~s/%%/\0/g;
				next if (substr($val,0, 1) eq '%');
				$val=~s/^(.+?)%/$1\*/;
				$val=~s/\0/%/g;
				push @vals, $val;
			}
			push @pwrparms, (lc $_) . ': ("'. 
				join('" and "', @vals) . '")'
				if scalar @vals;
		}
	}

	$pwrstr .= (($pwrstr ne '') ? ' and (' : '(') .
		join(') and (', @pwrparms) . ')'
		if scalar @pwrparms;

	$obj->{url_params}{Power} = ($pwrstr eq '') ? undef : $pwrstr;
	
	return $obj;
}

sub populate_request {
	my $obj = shift;
	my ($subid, $locale, $stmt, $max_pages, $resp_group) = @_;

	my $val;
	my $req_attrs = $obj->{req_attrs};
	my $url_params = $obj->{url_params};
	
	$url_params->{ResponseGroup} = $resp_group;
	$obj->{_max_pages} = $max_pages;
	return undef
		if ($req_attrs->{Power} && (! $obj->create_power_search($stmt)));
	foreach (keys %$req_attrs) {
		next if ($_ eq 'Power');

		if ($_ ne 'Keywords') {
			$url_params->{$_} = 
				$stmt->get_row_value(
				(ref $req_attrs->{$_} eq 'ARRAY' ? 
					$req_attrs->{$_}[0] :
					$req_attrs->{$_}), undef, {}),
			next;
		}
		my $keywords = '';
		foreach my $key (@{$req_attrs->{$_}}) {
			$keywords .= $stmt->get_row_value($key, undef, {}),
			next
				unless (ref $key eq 'ARRAY');

			foreach my $keyword (@$key) {
				my $val = $stmt->get_row_value($keyword, undef, {});
				$keywords .= "$val " if defined($val);
			}
		}
		$url_params->{$_} = ($keywords eq '') ? undef : $keywords;
	}
	foreach ('MaximumPrice', 'MinimumPrice') {
		$url_params->{$_} = int($url_params->{$_} * 100)
			if defined($url_params->{$_});
	}
	return $obj->SUPER::populate_request(@_);
}

1;

