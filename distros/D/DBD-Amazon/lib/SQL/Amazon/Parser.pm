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
package SQL::Amazon::Parser;

use Exporter;
use SQL::Parser;
use Data::Dumper 'Dumper';
use Clone qw(clone);
use DBI;

BEGIN {

our @ISA = qw(Exporter SQL::Parser);

use constant SQL_TREE_OP => 0;
use constant SQL_TREE_ARG1 => 1;
use constant SQL_TREE_ARG2 => 2;
use constant SQL_TREE_NEG => 3;
use constant SQL_TREE_TABLES => 4;

use constant SQL_TREE_TYPE => 0;
use constant SQL_TREE_VALUE => 1;

use constant SQL_PRED_CONJOIN => 0;
use constant SQL_PRED_TABLES => 1;

our @EXPORT    = ();		   
our @EXPORT_OK = ();

our %EXPORT_TAGS = (
	pred_node_codes => [
	qw/SQL_TREE_OP SQL_TREE_ARG1 SQL_TREE_ARG2 SQL_TREE_NEG/
	]
);

Exporter::export_tags(keys %EXPORT_TAGS);

};

use SQL::Amazon::StorageEngine;
use SQL::Amazon::ReqFactory;

use strict;

our $VERSION = '0.10';
my %neg_ops = (
'<', '>=',
'>', '<=',
'=', '<>',
'<>', '=',
'<=', '>',
'>=', '<'
);
my %transpose_ops = (
'<', '>',
'>', '<',
'=', '=',
'<>', '<>',
'<=', '>=',
'>=', '<='
);

sub new {
	my ($class, $flags) = @_;
	
	my $obj = $class->SUPER::new('Amazon', $flags);
	return undef unless $obj;
	$obj->LOAD('LOAD SQL::Amazon::Functions');
	return $obj;
}
sub get_in {
	my ($obj, $str) = @_;

    my $in_inside_parens = 0;

	my $strpos = 0;
	my $replpos = 0;
    while ($str =~ /\G(.+?)\b(NOT\s+)?IN \((.+)$/igcs ) {
        my ($col, $contents);
        my $front = $1;
        my $back  = $3;
        my $not = $2 ? 1 : 0;
        $strpos = $-[3];
        $replpos = $-[1];
		my $pos = ($front=~/^.+\b(AND|NOT|OR)\b(.+)$/igcs) ? $-[2] : 0;
		pos($front) = $pos; 
		$in_inside_parens += ($1 eq '(') ? 1 : -1
			while ($front=~/\G.*?([\(\)])/gcs);

		$obj->{struct}{errstr} = "Unmatched right parentheses during IN processing!",
		return undef
			if ($in_inside_parens < 0);
		pos($front) = $pos;
		$in_inside_parens--,
		$pos = $+[0]
			while ($in_inside_parens && ($front=~/\G.*?\(/gcs));
		$col = substr($front, $pos);
		$replpos += $pos;
		my $funcstr = ($not ? ' AMZN_NOT_IN_ANY (' : ' AMZN_IN_ANY (') . 
			$col . ', ';

		substr($str, $replpos, $strpos - $replpos) = $funcstr;
		pos($str) = $replpos + length($funcstr);
    }

	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	$str =~ s/\(\s+/(/;
	$str =~ s/\s+\)/)/;

	return $str;
}
sub transform_syntax {
	my ($obj, $str) = @_;

	my $repl;
   	while ($str =~/\bMATCHES(\s+(ANY|ALL|TEXT))?\s*\(/i ) {
		$repl = $2 ? 'AMZN_MATCH_' . uc $2 . '(' : 'AMZN_MATCH_ANY(';
		$str=~s/\bMATCHES(\s+(ANY|ALL|TEXT))?\s*\(/$repl/i;
	}
	$str=~s/\bPOWER_SEARCH(\s*\()/AMZN_POWER_SEARCH$1/g;
    return $str;
}
sub arrayify {
	my $tree = shift;

	return (defined($tree) && ($tree ne '')) ?
		((ref $tree ne 'HASH') || (! $tree->{op})) ?
		clone($tree) :
		[ $tree->{op},
			arrayify($tree->{arg1}),
			arrayify($tree->{arg2}),
			$tree->{neg} ] :
		undef;
}

sub hashify {
	my $tree = shift;
	
	return (ref $tree eq 'ARRAY') ?
		{
			op => $tree->[SQL_TREE_OP],
			arg1 => $tree->[SQL_TREE_ARG1],
			arg2 => $tree->[SQL_TREE_ARG2],
			neg => $tree->[SQL_TREE_NEG],
		} : $tree;
}

sub decomment {
	my $sql = shift;
	my $out = '';
	my $spos = 0;
	while ($sql=~/\G.*?(['"]|\/\*|--)/gcs) {
		if ($1 eq "'") {
			return ''
				unless ($sql=~/\G.*?'/gcs);
		}
		elsif ($1 eq '"') {
			return ''
				unless ($sql=~/\G.*?"/gcs);
		}
		elsif ($1 eq '/*') {
			$out .= substr($sql, $spos, $-[1] - $spos) . ' ';
			return ''
				unless ($sql=~/\G.*?\*\//gcs);
			$spos = pos($sql);
		}
		elsif ($1 eq '--') {
			$out .= substr($sql, $spos, $-[1] - $spos);
			return $out
				unless ($sql=~/\G.*?([\r\n])/gcs);
			$spos = pos($sql) - 1;
		}
	}
	$out .= substr($sql, $spos);
	return $out;
}

sub parse {
	my ($obj, $sql) = @_;

	DBI->trace_msg("[SQL::Amazon::Parser::parse] Parsing query\n$sql", 3)
		if $ENV{DBD_AMZN_DEBUG};
	$sql = decomment($sql);
	return undef
		unless $obj->SUPER::parse($sql);
	my $predary = $obj->{struct}{where_clause} ?
		dnf_flatten(
			dnf_recurse(
				dnf_negate(
					arrayify($obj->{struct}{where_clause}))), []) :
		[ ];
	$obj->{struct}{amzn_predicate} = $predary,
	$obj->{struct}{amzn_requests} = [],
	return $obj
		if ($obj->{struct}{table_names} &&
			($#{$obj->{struct}{table_names}} == 0) &&
			(uc $obj->{struct}{table_names}[0] eq 'SYSSCHEMA'));

	my $cachecnt = 0;
	$cachecnt += (/^CACHED/i) ? 1 : 0
		foreach (@{$obj->{struct}{table_names}});
	$obj->{struct}{amzn_predicate} = $predary,
	$obj->{struct}{amzn_requests} = [],
	return $obj
		if ($cachecnt == scalar @{$obj->{struct}{table_names}});
	$cachecnt = 0;
	my @amznreqs = ();
	my @finalpreds = ();
	my $reqobj;
	my $single_table = $obj->{struct}{table_names}[0];
	foreach my $pred (@$predary) {
		my ($table, $reqclass);
		my $requests = [];
		$pred->[SQL_PRED_TABLES] = { $single_table => 1}
			unless ($pred->[SQL_PRED_TABLES] &&
				keys %{$pred->[SQL_PRED_TABLES]});

		my $cached = 1;

		foreach (keys %{$pred->[SQL_PRED_TABLES]}) {
			($table, $reqclass) = 
				SQL::Amazon::StorageEngine::has_table($_);
			$obj->{struct}{errstr} = "Unknown table $_.",
			return undef
				unless $table;

			next if /^CACHED/i;

			$cached = undef;
			next unless $reqclass;
			push @$requests, [ $reqclass, $table ]
				unless ($table=~/^CACHED/i);
		}

		if ($cached) {
			$cachecnt++;
			push @finalpreds, $pred
				if $pred;
			next;
		}

		$pred->[SQL_PRED_TABLES] = 
			SQL::Amazon::ReqFactory->cleanup_requests($requests);
		$obj->{struct}{errstr} = SQL::Amazon::ReqFactory->errstr,
		return undef
			unless (scalar @{$pred->[SQL_PRED_TABLES]});
		$obj->{struct}{errstr} = 
			'Invalid predicate: insufficient qualifiers to issue service request.',
		return undef
			unless scalar @$requests;
		foreach (@$requests) {
			($pred, $reqobj) =
				SQL::Amazon::ReqFactory->create_request(
					$_->[0], $_->[1], $pred, $obj);
			$obj->{struct}{errstr} = SQL::Amazon::ReqFactory->errstr,
			return undef
				unless (defined($pred) || defined($reqobj));

			push @finalpreds, $pred
				if $pred;
			push @amznreqs, $reqobj
				if $reqobj;
		}
	}

	$obj->{struct}{errstr} = 
		'Invalid predicate: insufficient qualifiers to issue service request.',
	return undef
		unless (scalar @amznreqs || 
			($cachecnt == scalar @$predary));
	$obj->{struct}{amzn_predicate} = \@finalpreds;
	$obj->{struct}{amzn_requests} = \@amznreqs;
	return $obj;
}

sub negate_node {
	my $node = shift;
	$node->[SQL_TREE_OP] = $neg_ops{$node->[SQL_TREE_OP]},
	delete $node->[SQL_TREE_NEG],
	return $node
		if $neg_ops{$node->[SQL_TREE_OP]};
	$node->[SQL_TREE_NEG] = (! $node->[SQL_TREE_NEG]);
	return $node;
}
sub dnf_negate {
	my $node = shift;
	
	if ($node->[SQL_TREE_NEG]) {
		if (($node->[SQL_TREE_OP] eq 'AND') || 
			($node->[SQL_TREE_OP] eq 'OR')) {
			$node->[SQL_TREE_OP] = ($node->[SQL_TREE_OP] eq 'AND') ? 'OR' : 'AND';
			negate_node($node->[SQL_TREE_ARG1]);
			negate_node($node->[SQL_TREE_ARG2]);
		}
		else {
			negate_node($node);
		}
	}
	dnf_negate($node->[SQL_TREE_ARG1]),
	dnf_negate($node->[SQL_TREE_ARG2])
		if (($node->[SQL_TREE_OP] eq 'AND') || 
			($node->[SQL_TREE_OP] eq 'OR'));
	$node;
}
sub dnf_find_tables {
	my ($node, $tables) = @_;

	return undef 
		unless ((ref $node eq 'HASH') &&
			($node->{type} ne 'null'));

	if ($node->{type} eq 'column') {
		$tables->{uc $1} = 1
			if ($node->{value}=~/^([A-Z]\w*)\..+$/i);
		return $tables;
	}
	elsif ($node->{value} eq 'multiple values') {
	}
	return undef;
}
sub dnf_recurse {
	my ($node, $optimize) = shift;
	return $node
		if ($optimize && 
			($node->[SQL_TREE_ARG1][SQL_TREE_OP] ne 'OR') && 
			($node->[SQL_TREE_ARG2][SQL_TREE_OP] ne 'OR'));
	if (($node->[SQL_TREE_OP] ne 'OR') && 
		($node->[SQL_TREE_OP] ne 'AND')) {
		return $node
			if $node->[SQL_TREE_TABLES];

		my $tables = {};
		if (dnf_find_tables($node->[SQL_TREE_ARG1], $tables)) {
			$node->[SQL_TREE_TABLES] = $tables
				unless ($node->[SQL_TREE_ARG2] &&
					dnf_find_tables($node->[SQL_TREE_ARG2], $tables));
			return $node;
		}

		$node->[SQL_TREE_TABLES] = $tables
			if ($node->[SQL_TREE_ARG2] &&
				dnf_find_tables($node->[SQL_TREE_ARG2], $tables));
		return $node;
	}
	dnf_recurse($node->[SQL_TREE_ARG1], $optimize);
	dnf_recurse($node->[SQL_TREE_ARG2], $optimize);
	my ($temp, $newnode);
	if ($node->[SQL_TREE_OP] eq 'AND') {

		if ($node->[SQL_TREE_ARG1][SQL_TREE_OP] eq 'OR') {
			$temp = $node->[SQL_TREE_ARG1][SQL_TREE_ARG2];
			$node->[SQL_TREE_ARG1][SQL_TREE_ARG2] = clone($node->[SQL_TREE_ARG2]);
			$node->[SQL_TREE_ARG1][SQL_TREE_OP] = 'AND';
			$newnode = [ 'AND', $temp, $node->[SQL_TREE_ARG2] ];
			$node->[SQL_TREE_OP] = 'OR';
			$node->[SQL_TREE_ARG2] = $newnode;
			dnf_recurse($node->[SQL_TREE_ARG1], 1);
			dnf_recurse($node->[SQL_TREE_ARG2], 1);
		}
		elsif ($node->[SQL_TREE_ARG2][SQL_TREE_OP] eq 'OR') {
			$temp = $node->[SQL_TREE_ARG2][SQL_TREE_ARG2];
			$node->[SQL_TREE_ARG2][SQL_TREE_ARG2] = clone($node->[SQL_TREE_ARG1]);
			$node->[SQL_TREE_ARG2][SQL_TREE_OP] = 'AND';
			$newnode = [ 'AND', $node->[SQL_TREE_ARG1], $temp ];
			$node->[SQL_TREE_OP] = 'OR';
			$node->[SQL_TREE_ARG1] = $newnode;
			dnf_recurse($node->[SQL_TREE_ARG1], 1);
			dnf_recurse($node->[SQL_TREE_ARG2], 1);
		}
	}
	return $node;
}
sub dnf_flatten {
	my ($tree, $dnfary) = @_;
	dnf_flatten($tree->[SQL_TREE_ARG1], $dnfary),
	dnf_flatten($tree->[SQL_TREE_ARG2], $dnfary),
	$tree->[SQL_TREE_ARG1] = undef,
	$tree->[SQL_TREE_ARG2] = undef,
	return $dnfary
		if ($tree->[SQL_TREE_OP] eq 'OR');
	my $conjoins = [];
	my $tables = {};
	dnf_flatten_ANDs($tree, $conjoins, $tables);
	push(@$dnfary, [ $conjoins, $tables ]);
	return $dnfary;
}
sub dnf_flatten_ANDs {
	my ($tree, $conjoins, $tables) = @_;
	dnf_flatten_ANDs($tree->[SQL_TREE_ARG1], $conjoins, $tables),
	dnf_flatten_ANDs($tree->[SQL_TREE_ARG2], $conjoins, $tables),
	$tree->[SQL_TREE_ARG1] = undef,
	$tree->[SQL_TREE_ARG2] = undef,
	return $conjoins
		if ($tree->[SQL_TREE_OP] eq 'AND');
	my $t;
	$t = $tree->[SQL_TREE_ARG1],
	$tree->[SQL_TREE_ARG1] = $tree->[SQL_TREE_ARG2],
	$tree->[SQL_TREE_ARG2] = $t,
	$tree->[SQL_TREE_OP] = $transpose_ops{$tree->[SQL_TREE_OP]}
		if ($transpose_ops{$tree->[SQL_TREE_OP]} &&
			((ref $tree->[SQL_TREE_ARG1] ne 'HASH') || 
				($tree->[SQL_TREE_ARG1]{type} ne 'column')) &&
			(ref $tree->[SQL_TREE_ARG2] eq 'HASH') &&
			($tree->[SQL_TREE_ARG2]{type} eq 'column'));

	$tables->{$_} = 1,
	$tree->[SQL_TREE_TABLES] = undef	
		foreach (keys %{$tree->[SQL_TREE_TABLES]});
	push(@$conjoins, $tree);
	return $conjoins;
}
sub dnf_test {
	my $tree = shift;
	print print_node($tree), "\n";
	dnf_negate($tree);
	dnf_recurse($tree);
	print print_node($tree), "\n";

	return $tree;
}

sub print_node {
	my $tree = shift;
	
	return (($tree->[SQL_TREE_OP] eq 'AND') || ($tree->[SQL_TREE_OP] eq 'OR')) ?
		'(' . $tree->[SQL_TREE_ARG1]->print_node .  ') ' .
			$tree->[SQL_TREE_OP] . ' (' . 
			$tree->[SQL_TREE_ARG2]->print_node . ')' :
		'(' . $tree->[SQL_TREE_ARG1] . ' ' . $tree->[SQL_TREE_OP] . ' ' . 
			$tree->[SQL_TREE_ARG2] . ')';
}


1;

