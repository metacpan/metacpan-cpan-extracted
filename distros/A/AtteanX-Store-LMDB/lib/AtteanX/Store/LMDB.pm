=head1 NAME

AtteanX::Store::LMDB - LMDB-based RDF store

=head1 VERSION

This document describes AtteanX::Store::LMDB version 0.001

=head1 SYNOPSIS

 use AtteanX::Store::LMDB;

=head1 DESCRIPTION

AtteanX::Store::LMDB provides a persistent quad-store based on LMDB.

=cut

use v5.14;
use warnings;

package AtteanX::Store::LMDB {
our $VERSION	= '0.001';
use Moo;
use Type::Tiny::Role;
use Types::Standard qw(Bool Str InstanceOf HashRef);
use LMDB_File qw(:flags :cursor_op);
use Digest::SHA qw(sha256 sha256_hex);
use Scalar::Util qw(refaddr reftype blessed);
use Math::Cartesian::Product;
use List::Util qw(any all first);
use File::Path qw(make_path);
use DateTime::Format::W3CDTF;
use Devel::Peek;
use Encode qw(encode_utf8 decode_utf8);
use namespace::clean;

with 'Attean::API::QuadStore';
with 'Attean::API::MutableQuadStore';

=head1 METHODS

Beyond the methods documented below, this class inherits methods from the
L<Attean::API::QuadStore> class.

=over 4

=item C<< new () >>

Returns a new LMDB-backed store object.

=cut

has initialize => (is => 'ro', isa => Bool, default => 0);
has filename => (is => 'ro', isa => Str, required => 1);
has env		=> (is => 'rw', isa => InstanceOf['LMDB::Env']);
has indexes	=> (is => 'rw', isa => HashRef, default => sub { +{} });

sub BUILD {
	my $self	= shift;
	my $file	= $self->filename;
	
	unless (-d $file) {
		make_path($file);
	}
	my $env = LMDB::Env->new($file, {
		mapsize => 100 * 1024 * 1024 * 1024, # Plenty space, don't worry
		maxdbs => 20, # Some databases
		mode   => 0640,
	});
	$self->env($env);
	if ($self->initialize) {
		my $txn		= $self->env->BeginTxn();
		my %databases;
		foreach my $name (qw(quads stats fullIndexes term_to_id id_to_term graphs prefixes)) {
			$databases{$name}	= $txn->OpenDB({ dbname => $name, flags => MDB_CREATE });
		}
		
		my $f		= DateTime::Format::W3CDTF->new();
		my $stats	= $databases{'stats'};
		$stats->put("Diomede-Version", '0.0.13');
		$stats->put("Last-Modified", $f->format_datetime(DateTime->now()));
		foreach my $key (qw(next_unassigned_term_id next_unassigned_quad_id)) {
			$stats->put($key, pack('Q>', 1));
		}
		my $indexes	= $databases{'fullIndexes'};
		my %positions = ('s' => 0, 'p' => 1, 'o' => 2, 'g' => 3);
		foreach my $key (qw(spog pogs gops)) {
			my @pos	= map { $positions{$_} } split(//, $key);
			$txn->OpenDB({ dbname => $key, flags => MDB_CREATE });
			$indexes->put($key, pack('Q>4', @pos));
		}
		
		$txn->commit();
	}
	
	my $txn		= $self->env->BeginTxn(MDB_RDONLY);
	my $indexes	= $txn->OpenDB({ dbname => 'fullIndexes' });
	$self->iterate_database($indexes, sub {
		my ($key, $value)	= @_;
		my @order	= unpack('Q>4', $value);
		$self->indexes->{$key}	= \@order;
	});
}

sub iterate_database {
	my $self	= shift;
	my $db		= shift;
	my $handler	= shift;
	my $cursor	= $db->Cursor;
	eval {
		local($LMDB_File::die_on_err)	= 0;
		my ($key, $value);
		unless ($cursor->get($key, $value, MDB_FIRST)) {
			while (1) {
				$handler->($key, $value);
				last if $cursor->get($key, $value, MDB_NEXT);
			}
		}
	};
}

sub iterate_database_range {
	my $self	= shift;
	my $db		= shift;
	my $from	= shift;
	my $to		= shift;
	my $handler	= shift;
	my $cursor	= $db->Cursor;
	eval {
		local($LMDB_File::die_on_err)	= 0;
		my $key	= $from;
		my $value;
		unless ($cursor->get($key, $value, MDB_SET_RANGE)) {
			while (1) {
				use bytes;
				my $c = $key cmp $to;
				last if ($c >= 0);
				$handler->($key, $value);
				last if $cursor->get($key, $value, MDB_NEXT);
			}
		}
	};
}

=item C<< size >>

Returns the number of quads in the store.

=cut

sub size {
	my $self	= shift;
	my $txn		= $self->env->BeginTxn(MDB_RDONLY);
	my $quads	= $txn->OpenDB({ dbname => 'quads', });
	my $stat	= $quads->stat // {};
	return $stat->{'entries'} // 0;
}

=item C<< get_quads ( $subject, $predicate, $object, $graph ) >>

Returns a stream object of all statements matching the specified subject,
predicate, object, and graph. Any of the arguments may be undef to match any value.

=cut

sub get_quads {
	my $self	= shift;
	my $needs_cartesian	= any { ref($_) eq 'ARRAY' } @_;
	if ($needs_cartesian) {
		my @nodes	= map { ref($_) eq 'ARRAY' ? $_ : [$_] } @_;
		my @iters;
		cartesian { push(@iters, $self->_get_quads(@_)) } @nodes;
		if (scalar(@iters) == 1) {
			return shift(@iters);
		} else {
			return Attean::IteratorSequence->new( iterators => \@iters, item_type => 'Attean::API::Quad' );
		}
	} else {
		return $self->_get_quads(@_);
	}
}

sub _encode_term {
	my $self	= shift;
	my $term	= shift;
	my $value	= $term->value;
	if ($term->isa('Attean::IRI')) {
		return encode_utf8('I"' . $value);
	} elsif ($term->isa('Attean::Literal')) {
		if (my $lang = $term->language) {
				return encode_utf8('L' . $lang . '"' . $value);
		} elsif (my $dt = $term->datatype) {
			if ($dt->value eq 'http://www.w3.org/2001/XMLSchema#string') {
				return encode_utf8('S"' . $value);
			} else {
				return encode_utf8('D' . $dt->value . '"' . $value);
			}
		} else {
			return encode_utf8('S"' . $value);
		}
	} elsif ($term->isa('Attean::Blank')) {
		return encode_utf8('B"' . $value);
	}
}

sub _parse_term {
	my $self	= shift;
	my $data	= decode_utf8(shift);
	my $type	= substr($data, 0, 1);
	if ($type eq 'I') {
		my $value	= substr($data, 2);
		return Attean::IRI->new(value => $value);
	} elsif ($type eq 'S') {
		my $value	= substr($data, 2);
		return Attean::Literal->new(value => $value);
	} elsif ($type eq 'L') {
		my $i		= index($data, '"');
		my $lang	= substr($data, 1, $i-1);
		my $value	= substr($data, $i+1);
		return Attean::Literal->new(value => $value, language => $lang);
	} elsif ($type eq 'D') {
		my $i		= index($data, '"');
		my $dt		= substr($data, 1, $i-1);
		my $value	= substr($data, $i+1);
		return Attean::Literal->new(value => $value, datatype => $dt);
	} elsif ($type eq 'i') {
		my $value	= substr($data, 2);
		return Attean::Literal->new(value => $value, datatype => 'http://www.w3.org/2001/XMLSchema#integer');
	} elsif ($type eq 'B') {
		my $value	= substr($data, 2);
		return Attean::Blank->new($value);
	} else {
		Dump($data);
		die "Unrecognized encoded term value";
	}
	return;
}

sub _get_term_id {
	my $self	= shift;
	my $term	= shift;
	my $t2i		= shift;
	my $encoded		= $self->_encode_term($term);
	my $hash		= sha256($encoded);
	my $value		= $t2i->get($hash);
	unless ($value) {
		return;
	}
	my ($id)		= unpack('Q>', $value);
	return $id;
}

sub _get_or_create_term_id {
	my $self	= shift;
	my $term	= shift;
	my $txn		= shift;
	my $stats	= shift;
	my $t2i		= shift;
	my $i2t		= shift;
	my $id		= $self->_get_term_id($term, $t2i);
	if ($id) {
		return $id;
	}
	
	my $next_key	= 'next_unassigned_term_id';
	my ($next)		= unpack('Q>', $stats->get($next_key));
# 	warn "next term id: $next\n";
	my $encoded		= $self->_encode_term($term);
	my $hash		= sha256($encoded);
	my $id_value	= $next++;
	$id				= pack('Q>', $id_value);
	
	$t2i->put($hash, $id);
	$i2t->put($id, $encoded);
	$stats->put($next_key, pack('Q>', $next));
	return $id_value;
}

sub _materialize_quads {
	my $self	= shift;
	my $quadids	= shift;
	my $sub	= sub {
		my $txn		= $self->env->BeginTxn(MDB_RDONLY);
		my $i2t		= $txn->OpenDB({ dbname => 'id_to_term', });
		QUAD: while (my $tids = shift(@$quadids)) {
			my @terms;
			foreach my $tid (@$tids) {
				my $key	= pack('Q>', $tid);
				my $termdata = $i2t->get($key);
				next QUAD unless ($termdata);
				my $term	= $self->_parse_term($termdata);
				next QUAD unless ($term);
				push(@terms, $term);
			}
			if (scalar(@terms) == 4) {
				return Attean::Quad->new(@terms);
			}
		}
		return;
	};
	return Attean::CodeIterator->new( generator => $sub, item_type => 'Attean::API::Quad' );
}

sub _get_all_unordered_quads {
	my $self	= shift;
	my $quads	= shift;
	my ($key, $value);
	my @quadids;
	$self->iterate_database($quads, sub {
		my ($key, $value)	= @_;
		my (@ids)	= unpack('Q>4', $value);
		push(@quadids, \@ids);
	});
	return \@quadids;
}

sub _get_unordered_matching_quads {
	my $self	= shift;
	my $quads	= shift;
	my $bound	= shift;
	my ($key, $value);
	my @quadids;
	$self->iterate_database($quads, sub {
		my ($key, $value)	= @_;
		my (@ids)	= unpack('Q>4', $value);
		foreach my $k (keys %$bound) {
			my $id	= $bound->{$k};
			unless ($id == $ids[$k]) {
				return;
			}
		}
		push(@quadids, \@ids);
	});
	return \@quadids;
}

sub _get_ordered_matching_quads {
	my $self	= shift;
	my $txn		= shift;
	my $bound	= shift;
	my $name	= shift;
	my $lower	= shift;
	my $upper	= shift;
	my $from	= pack('Q>4', @$lower, 0, 0, 0, 0);
	my $to		= pack('Q>4', @$upper, 0, 0, 0, 0);
	my $index	= $txn->OpenDB({ dbname => $name });
	my $order	= $self->indexes->{$name};
	my @quadids;
# 	warn "range query on index $name\n";
	$self->iterate_database_range($index, $from, $to, sub {
		my ($key, $value)	= @_;
		my (@index_ordered_ids)	= unpack('Q>4', $key);
		my @ids;
		foreach my $pos (@$order) {
			$ids[$pos] = shift(@index_ordered_ids);
		}
		foreach my $k (keys %$bound) {
			my $id	= $bound->{$k};
			unless ($id == $ids[$k]) {
				return;
			}
		}
		push(@quadids, \@ids);
	});
	return \@quadids;
}

sub _compute_bound {
	my $self	= shift;
	my @nodes	= @_;
	my $txn		= $nodes[4] // $self->env->BeginTxn(MDB_RDONLY);;
	my $bound	= 0;
	my %bound;
	my $t2i		= $txn->OpenDB({ dbname => 'term_to_id', });
	foreach my $pos (0 .. 3) {
		my $n	= $nodes[ $pos ];
		if (blessed($n)) {
			if ($n->does('Attean::API::Variable')) {
				$n	= undef;
				$nodes[$pos]	= undef;
			} else {
				$bound++;
				my $id			= $self->_get_term_id($n, $t2i);
				unless ($id) {
	# 					warn "No such term in quadstore: " . $n->as_string;
	# 				die "No such term in quadstore: " . $n->as_string; # this spends a lot of time in Carp::Always
					return;
				}
				$bound{ $pos }	= $id;
			}
		}
	}
	return \%bound;
}

sub _get_quads {
	my $self	= shift;
	my @nodes	= @_;
	my $bound_data	= $self->_compute_bound(@nodes);
	unless ($bound_data) {
		# one of the bound terms in the pattern doesn't exist in the database,
		# so no quads will match.
		return Attean::ListIterator->new( values => [], item_type => 'Attean::API::Quad' );
	}
	my %bound	= %$bound_data;
	my $bound	= scalar(@{[keys %bound]});
	
	my $txn		= $self->env->BeginTxn(MDB_RDONLY);
	my $quads	= $txn->OpenDB({ dbname => 'quads', });
	if ($bound == 0) {
		my $quadids	= $self->_get_all_unordered_quads($quads);
		return $self->_materialize_quads($quadids);
	} else {
		if (my $best = $self->_best_index(\%bound, $txn)) {
			my ($index, $score)	= @$best;
			my $order		= $self->indexes->{$index};
			my @positions	= @$order[0..$score-1];
			my @prefix		= map { $bound{$_} } @positions;
			my @lower		= @prefix;
			my @upper		= @prefix;
			$upper[-1]++;
			my $quadids	= $self->_get_ordered_matching_quads($txn, \%bound, $index, \@lower, \@upper);
			return $self->_materialize_quads($quadids);
		}
		my $quadids	= $self->_get_unordered_matching_quads($quads, \%bound);
		return $self->_materialize_quads($quadids);
	}
}

sub _best_index {
	my $self	= shift;
	my $bound	= shift;
	my $txn		= shift;
	my @scores;
	while (my ($name, $order) = each %{ $self->indexes }) {
		my $score	= 0;
		foreach my $pos (@$order) {
			if (exists $bound->{$pos}) {
				$score++;
			} else {
				last
			}
		}
		push(@scores, [$name, $score]);
	}
     
	@scores	= sort { $b->[1] <=> $a->[1] } @scores;
	return shift(@scores);
}

=item C<< get_graphs >>

Returns an iterator over the Attean::API::Term objects comprising
the set of graphs of the stored quads.

=cut

sub get_graphs {
	my $self	= shift;
	my $txn		= $self->env->BeginTxn(MDB_RDONLY);
	my $graphs	= $txn->OpenDB({ dbname => 'graphs', });
	my $i2t		= $txn->OpenDB({ dbname => 'id_to_term', });
	my ($key, $value);
	my @graph_ids;
	$self->iterate_database($graphs, sub {
		my ($key, $value)	= @_;
		my ($gid)	= unpack('Q>', $key);
		push(@graph_ids, $gid);
	});
	
	my $sub	= sub {
		my $txn		= $self->env->BeginTxn(MDB_RDONLY);
		my $i2t		= $txn->OpenDB({ dbname => 'id_to_term', });
		GRAPH: while (my $gid = shift(@graph_ids)) {
			my $key	= pack('Q>', $gid);
			my $termdata = $i2t->get($key);
			next QUAD unless ($termdata);
			my $term	= $self->_parse_term($termdata);
			next GRAPH unless ($term);
			return $term;
		}
		return;
	};
	return Attean::CodeIterator->new( generator => $sub, item_type => 'Attean::API::Term' );
}

sub _exists_with_txn {
	my $self	= shift;
	my $txn		= shift;
	my $qp		= shift;
	
	my $exists	= $self->_get_quads($qp->values);
	if (my $q = $exists->next) {
		return 1;
	}
	return 0;
}

sub _exists {
	my $self	= shift;
	my $qp		= shift;
	
	my $exists	= $self->get_quads($qp->values);
	if (my $q = $exists->next) {
		return 1;
	}
	return 0;
}

=item C<< add_quad ( $quad ) >>

Adds the specified C<$quad> to the underlying model.

=cut
	
	sub add_quad {
		my $self	= shift;
		my $st		= shift;
		
		if ($self->_exists($st)) {
			return;
		}
		
		my $txn		= $self->env->BeginTxn();
		my $stats	= $txn->OpenDB({ dbname => 'stats', });
		my $t2i		= $txn->OpenDB({ dbname => 'term_to_id', });
		my $i2t		= $txn->OpenDB({ dbname => 'id_to_term', });
		my $graphs	= $txn->OpenDB({ dbname => 'graphs', });

		my @ids		= map { $self->_get_or_create_term_id($_, $txn, $stats, $t2i, $i2t) } $st->values;
		if (any { not defined($_) } @ids) {
			return;
		}

		my $next_quad	= 'next_unassigned_quad_id';
		my ($next)		= unpack('Q>', $stats->get($next_quad));
# 		warn "next quad id: $next\n";
		my $qid_value	= $next++;

		my $qid			= pack('Q>', $qid_value);
		my $qids		= pack('Q>4', @ids);
		my $gid			= pack('Q>', $ids[3]);

		my $graphs_dbi	= $txn->open('graphs');
		my $quads_dbi	= $txn->open('quads');
		my $stats_dbi	= $txn->open('stats');
		$txn->put($quads_dbi, $qid, $qids);

		my $graphs_cursor = $graphs->Cursor;
		my $key	= $gid;
		my $empty	= '';
		eval {
			local($LMDB_File::die_on_err)	= 0;
			if (my $err = $graphs_cursor->get($key, $empty, MDB_SET_RANGE)) {
				$graphs_cursor->put($gid, $empty);
			} else {
				if ($key ne $gid) {
					$graphs_cursor->put($gid, $empty);
				}
			}
		};

		$self->_add_quad_to_indexes($qid, \@ids, $txn);
		$txn->put($stats_dbi, $next_quad, pack('Q>', $next));
		$txn->commit();
	}
	
	sub add_quad_with_txn {
		my $self	= shift;
		my $txn		= shift;
		my $st		= shift;
		
		if ($self->_exists_with_txn($txn, $st)) {
			return;
		}
		
		my $stats	= $txn->OpenDB({ dbname => 'stats', });
		my $t2i		= $txn->OpenDB({ dbname => 'term_to_id', });
		my $i2t		= $txn->OpenDB({ dbname => 'id_to_term', });

		my @ids		= map { $self->_get_or_create_term_id($_, $txn, $stats, $t2i, $i2t) } $st->values;
		if (any { not defined($_) } @ids) {
			return;
		}

		my $next_quad	= 'next_unassigned_quad_id';
		my ($next)		= unpack('Q>', $stats->get($next_quad));
# 		warn "next quad id: $next\n";
		my $qid_value	= $next++;

		my $qid			= pack('Q>', $qid_value);
		my $qids		= pack('Q>4', @ids);

		my $quads_dbi	= $txn->open('quads');
		my $stats_dbi	= $txn->open('stats');
		$txn->put($quads_dbi, $qid, $qids);
		$self->_add_quad_to_indexes($qid, \@ids, $txn);
		$txn->put($stats_dbi, $next_quad, pack('Q>', $next));
	}
	
	sub _add_quad_to_indexes {
		my $self	= shift;
		my $qid		= shift;
		my $ids		= shift;
		my @ids		= @$ids;
		my $txn		= shift;
		while (my ($name, $order) = each %{ $self->indexes }) {
			my $index	= $txn->open($name);
			my @index_ordered_ids	= @ids[@$order];
			my $qids	= pack('Q>4', @index_ordered_ids);
			$txn->put($index, $qids, $qid);
		}
	}
	
	sub _remove_quad_to_indexes {
		my $self	= shift;
		my $qid		= shift;
		my $ids		= shift;
		my @ids		= @$ids;
		my $txn		= shift;
		while (my ($name, $order) = each %{ $self->indexes }) {
			my $index	= $txn->OpenDB({ dbname => $name });
			my @index_ordered_ids	= @ids[@$order];
			my $qids		= pack('Q>4', @index_ordered_ids);
			$index->del($qids);
		}
	}

=item C<< remove_quad ( $statement ) >>

Removes the specified C<$statement> from the underlying model.

=cut

	sub remove_quad {
		my $self	= shift;
		my $st		= shift;
		my $txn		= $self->env->BeginTxn();
		my $t2i		= $txn->OpenDB({ dbname => 'term_to_id', });
		my $quads	= $txn->OpenDB({ dbname => 'quads', });
		my $graphs	= $txn->OpenDB({ dbname => 'graphs', });

		my @remove_ids		= map { $self->_get_term_id($_, $t2i) } $st->values;
		unless (scalar(@remove_ids) == 4) {
			return;
		}
		unless (all { defined($_) } @remove_ids) {
			return;
		}

		my $cursor	= $quads->Cursor;
		my ($key, $value);
		eval {
			local($LMDB_File::die_on_err)	= 0;
			unless ($cursor->get($key, $value, MDB_FIRST)) {
				QUAD: while (1) {
					my $qid		= unpack('Q>', $key);
					my (@ids)	= unpack('Q>4', $value);
					if ($ids[0] == $remove_ids[0] and $ids[1] == $remove_ids[1] and $ids[2] == $remove_ids[2] and $ids[3] == $remove_ids[3]) {
						my $g		= $ids[3];
						$self->_remove_quad_to_indexes($qid, \@ids, $txn);
						$cursor->del();
						
						unless ($self->_graph_id_exists_with_txn($txn, $quads, $t2i, $g)) {
							# no more quads with this graph, so delete it from the graphs table
							my $graphs_cursor = $graphs->Cursor;
							my $gid = pack('Q>', $g);
							my $key	= $gid;
							my $empty	= '';
							unless ($graphs_cursor->get($key, $empty, MDB_SET_RANGE)) {
								if ($gid eq $key) {
									$graphs_cursor->del();
								}
							}
						}

						$txn->commit();
						return;
					}
				} continue {
					last if $cursor->get($key, $value, MDB_NEXT);
				}
			}
		};
	}

=item C<< create_graph( $graph ) >>

This is a no-op function for the memory quad-store.

=cut

	sub create_graph {
		# no-op on a quad-store
	}

=item C<< drop_graph( $graph ) >>

Removes all quads with the given C<< $graph >>.

=cut

	sub drop_graph {
		my $self	= shift;
		return $self->clear_graph(@_);
	}

=item C<< clear_graph( $graph ) >>

Removes all quads with the given C<< $graph >>.

=cut

	sub clear_graph {
		my $self	= shift;
		my $graph	= shift;
		my $quads	= $self->get_quads(undef, undef, undef, $graph);
		while (my $q = $quads->next) {
			$self->remove_quad($q);
		}
	}

	sub add_iter {
		my $BULK_LOAD	= 1;

		my $self	= shift;
		my $iter	= shift;
		my $type	= $iter->item_type;
		die "Iterator type $type isn't quads" unless (Role::Tiny::does_role($type, 'Attean::API::Quad'));

		my ($txn, $stats, $t2i, $i2t, $quads_dbi, $stats_dbi, $graphs_dbi);
		if ($BULK_LOAD) {
			$txn		= $self->env->BeginTxn();
			$stats	= $txn->OpenDB({ dbname => 'stats', });
			$t2i		= $txn->OpenDB({ dbname => 'term_to_id', });
			$i2t		= $txn->OpenDB({ dbname => 'id_to_term', });
			$graphs_dbi	= $txn->OpenDB({ dbname => 'graphs', });
			$quads_dbi	= $txn->open('quads');
			$stats_dbi	= $txn->open('stats');
		}

		my $next_quad	= 'next_unassigned_quad_id';
		my ($next)		= unpack('Q>', $stats->get($next_quad));
		my %graphs;
		while (my $q = $iter->next) {
			if ($BULK_LOAD) {
				if ($self->_quad_exists_with_txn($txn, $quads_dbi, $t2i, $q->values)) {
					next;
				}
		
				my @ids		= map { $self->_get_or_create_term_id($_, $txn, $stats, $t2i, $i2t) } $q->values;
				if (any { not defined($_) } @ids) {
					return;
				}

		# 		warn "next quad id: $next\n";
				my $qid_value	= $next++;

				my $qid			= pack('Q>', $qid_value);
				my $qids		= pack('Q>4', @ids);
				my $g			= $ids[3];
				$graphs{$g}		= pack('Q>', $g);

				$txn->put($quads_dbi, $qid, $qids);
				$self->_add_quad_to_indexes($qid, \@ids, $txn);
			} else {
				$self->add_quad($q);
			}
		}
		if ($BULK_LOAD) {
			my $empty	= '';
			my $graphs_cursor = $graphs_dbi->Cursor;
			foreach my $gid (values %graphs) {
				my $key	= $gid;
				eval {
					local($LMDB_File::die_on_err)	= 0;
					if (my $err = $graphs_cursor->get($key, $empty, MDB_SET_RANGE)) {
						$graphs_cursor->put($gid, $empty);
					} else {
						if ($key ne $gid) {
							$graphs_cursor->put($gid, $empty);
						}
					}
				};
			}
			$txn->put($stats_dbi, $next_quad, pack('Q>', $next));
			$txn->commit();
		}
	}

	sub _quad_exists_with_txn {
		my $self	= shift;
		my $txn		= shift;
		my $quads	= shift;
		my $t2i		= shift;
		my @nodes	= @_;
# 		my $bound_data	= $self->_compute_bound(@nodes, $txn);
		my %bound;
		foreach my $pos (0 .. 3) {
			my $n	= $nodes[ $pos ];
			my $id	= $self->_get_term_id($n, $t2i);
			unless ($id) {
				# one of the bound terms in the pattern doesn't exist in the database,
				# so no quads will match.
				return 0;
			}
			$bound{ $pos }	= $id;
		}
		if (my $best = $self->_best_index(\%bound, $txn)) {
			my ($index, $score)	= @$best;
			my $order		= $self->indexes->{$index};
			my @positions	= @$order[0..$score-1];
			my @prefix		= map { $bound{$_} } @positions;
			my @lower		= @prefix;
			my @upper		= @prefix;
			$upper[-1]++;
			my $quadids	= $self->_get_ordered_matching_quads($txn, \%bound, $index, \@lower, \@upper);
			return scalar(@$quadids);
		}
		my $quadids	= $self->_get_unordered_matching_quads($quads, \%bound);
		return scalar(@$quadids);
	}


	sub _graph_id_exists_with_txn {
		my $self	= shift;
		my $txn		= shift;
		my $quads	= shift;
		my $t2i		= shift;
		my $gid		= shift;
		my %bound	= (3 => $gid);
		if (my $best = $self->_best_index(\%bound, $txn)) {
			my ($index, $score)	= @$best;
			my $order		= $self->indexes->{$index};
			my @positions	= @$order[0..$score-1];
			my @prefix		= map { $bound{$_} } @positions;
			my @lower		= @prefix;
			my @upper		= @prefix;
			$upper[-1]++;
			my $quadids	= $self->_get_ordered_matching_quads($txn, \%bound, $index, \@lower, \@upper);
			return scalar(@$quadids);
		}
		my $quadids	= $self->_get_unordered_matching_quads($quads, \%bound);
		return scalar(@$quadids);
	}
}

1;

__END__

=back

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/perlrdf2/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 SEE ALSO

=over 4

=item * L<Diomede|https://github.com/kasei/diomede/> is a Swift LMDB-based quadstore that shares the same file format as this module.

=back

=head1 COPYRIGHT

Copyright (c) 2020 Gregory Todd Williams. This
program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
