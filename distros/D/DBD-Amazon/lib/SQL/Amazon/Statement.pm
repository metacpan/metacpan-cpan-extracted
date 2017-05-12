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
package SQL::Amazon::Statement;

use SQL::Statement;
use base qw(SQL::Statement);
use DBI;
use SQL::Amazon::Tables::Table;

use SQL::Amazon::Parser qw(:pred_node_codes);

use strict;
our $VERSION = '0.10';

our $engine;

use constant SQL_S2POPS_STR => 0;
use constant SQL_S2POPS_NUM => 1;
our %s2pops = (
'LIKE', 	['LIKE', 'LIKE'],
'CLIKE',	['CLIKE', 'CLIKE'],
'RLIKE',	['RLIKE', 'RLIKE'],
'<',		['lt', '<'],
'>',		['gt', '>'],
'>=',		['ge', '>='],
'<=',		['le', '<='],
'=',		['eq', '=='],
'<>',		['ne', '!='],
);

our %reqlookup = (
	'ItemLookup', 'SQL::Amazon::Request::ItemLookup',
	'ItemSearch', 'SQL::Amazon::Request::ItemSearch',
);


*is_number = *DBI::looks_like_number;

sub new {
	my $class = shift;
	my ($sql, $parser, $amzn_engine, $flags) = @_;
	$engine = ($amzn_engine && 
		ref $amzn_engine &&
		(ref $amzn_engine eq 'SQL::Amazon::StorageEngine')) ? 
		$amzn_engine : 
		SQL::Amazon::StorageEngine->new()
		unless $engine;

	my $obj = $class->SUPER::new($sql, $parser, $flags);
	return undef 
		unless $obj;

	return $obj;
}
sub open_tables {
    my ($obj, $handle, $createMode, $lockMode) = @_;
	delete $obj->{amzn_req_ids};
	my $reqary = $obj->{amzn_requests};
	return $obj->SUPER::open_tables($handle, $createMode, $lockMode)
		unless ($reqary && (scalar @$reqary));

	my @requests = ();
	foreach (@$reqary) {
		my $request = $_->populate_request(
			$handle->{Database}{USER}, 
			$handle->{Database}{amzn_locale},
			$obj, 
			$handle->{amzn_max_pages},
			$handle->{amzn_resp_group}	
			);
		next unless $request;
		my $dup = undef;
		foreach (@requests) {
			$dup = 1,
			last
				if $request->equals($_);
		}
		push @requests, $request
			unless $dup;
	}
	my $reqtime = 0;
	my $reqids;

	($obj->{errstr}, $reqids, $reqtime) =
		$engine->send_requests(\@requests);

	return $obj->do_err($obj->{errstr})
		unless defined($reqtime);
	$handle->seterr(0, $obj->{errstr}),
	delete $obj->{errstr}
		if defined($obj->{errstr});

	$obj->{amzn_req_ids} = $reqids;
	return $obj->SUPER::open_tables($handle, $createMode, $lockMode);
}

sub process_predicate {
    my($obj, $pred, $eval, $rowhash) = @_;
    my $predary = $obj->{amzn_predicate};
	foreach my $conjoin (@$predary) {
		next unless ($conjoin && $conjoin->[0] && scalar @{$conjoin->[0]});
		my $match = 1;
		foreach (@{$conjoin->[0]}) {
			$match = 0,
			last
        		unless ($obj->process_AND_predicate($_, $eval, $rowhash) &&
        			(!$_->[SQL_TREE_NEG]));
		}
		return 1 
			if $match;
    }
	return 0;
}

sub process_AND_predicate {
    my($obj, $pred, $eval, $rowhash) = @_;
    
	my $neg = $pred->[SQL_TREE_NEG];
	my $op = $pred->[SQL_TREE_OP];
	my $val1 = defined($pred->[SQL_TREE_ARG1]) ?
		$obj->get_row_value( $pred->[SQL_TREE_ARG1], $eval, $rowhash ) :
		undef;

	return $val1
		if ($op eq 'USER_DEFINED');

	my $val2 = defined($pred->[SQL_TREE_ARG2]) ?
		$obj->get_row_value( $pred->[SQL_TREE_ARG2], $eval, $rowhash ) :
		undef;

	return $neg
		if (($op ne 'IS') && (!defined($val1) || !defined($val2)));
	return defined($val1) ? $neg : !$neg
		if ($op eq 'IS');

	$op = ( is_number($val1) and is_number($val2) ) ?
		$s2pops{$op}->[SQL_S2POPS_NUM] : 
		$s2pops{$op}->[SQL_S2POPS_STR];

	if (ref $eval !~ /TempTable/) {
		my($table) = $eval->table($obj->tables(0)->name());
		if ($op eq '=' and !$neg and $table->can('fetch_one_row')){
			my $key_col = $table->fetch_one_row(1,1);

			$obj->{fetched_from_key} = 1,
			$obj->{fetched_value} = $table->fetch_one_row(0, $val2),
			return 1
				if ($pred->[SQL_TREE_ARG1]->{value} =~ /^$key_col$/i);
		}
	}
	return $obj->is_matched($val1, $op, $val2) ? !$neg : $neg;
}
sub open_table ($$$$$) {
    my($obj, $handle, $tname, $createMode, $lockMode) = @_;

    return $engine->get_result_set($tname, $obj->{amzn_req_ids}, $createMode);
}

1;
