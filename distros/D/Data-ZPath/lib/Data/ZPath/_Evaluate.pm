use strict;
use warnings;

package Data::ZPath::_Evaluate;

use Carp         qw(croak);
use POSIX        qw(ceil floor);
use Regexp::Util qw(deserialize_regexp);
use Scalar::Util qw(blessed refaddr);

use Data::ZPath::Node;

our $VERSION = '0.001000';

sub _pattern_to_regexp {
	my ( $pat ) = @_;

	for my $candidate ( qw{ / | : " ' }, '#' ) {
		if ( index($pat, $candidate) < 0 ) {
			return deserialize_regexp sprintf( 'qr%s%s%s', $candidate, $pat, $candidate );
		}
	}

	$pat =~ s{\/}{\\\/}g;
	return deserialize_regexp sprintf( 'qr/%s/', $pat );
}

sub _eval_expr {
	my ( $ast, $ctx ) = @_;

	my $t = $ast->{t};

	if ( $t eq 'num' ) {
		return Data::ZPath::Node->_wrap($ast->{v});
	}
	if ( $t eq 'str' ) {
		return Data::ZPath::Node->_wrap($ast->{v});
	}
	if ( $t eq 'path' ) {
		return _eval_path($ast, $ctx);
	}
	if ( $t eq 'fn' ) {
		return _eval_fn($ast, $ctx);
	}
	if ( $t eq 'un' ) {
		my @v = _eval_expr($ast->{e}, $ctx);
		my $x = _truthy($v[0]);

		if ( $ast->{op} eq '!' ) {
			return (Data::ZPath::Node->_wrap($x ? !!0 : !!1));
		}
		if ( $ast->{op} eq '~' ) {
			my $n = _to_number($v[0]);
			return unless defined $n;
			return Data::ZPath::Node->_wrap((~(int($n))));
		}
		croak "Unknown unary op $ast->{op}";
	}
	if ( $t eq 'bin' ) {
		my @l = _eval_expr($ast->{l}, $ctx);
		my @r = _eval_expr($ast->{r}, $ctx);

		my $lv = $l[0];
		my $rv = $r[0];
		my $op = $ast->{op};

		# Logical ops treat as booleans
		if ( $op eq '&&' || $op eq '||' ) {
			my $lb = _truthy($lv);
			my $rb = _truthy($rv);
			return (Data::ZPath::Node->_wrap(
				($op eq '&&') ? ($lb && $rb ? !!1 : !!0) : ($lb || $rb ? !!1 : !!0),
				undef, undef
			));
		}

		# Equality (loose-ish, but stable)
		if ( $op eq '==' || $op eq '!=' ) {
			my $eq = 0;

			if ( @l && @r ) {
				OUTER:
				for my $ln (@l) {
					for my $rn (@r) {
						if ( _equals($ln, $rn) ) {
							$eq = 1;
							last OUTER;
						}
					}
				}
			}

			$eq = !$eq if $op eq '!=';
			return (Data::ZPath::Node->_wrap($eq ? !!1 : !!0));
		}

		# Relations (numeric if both numeric, else string)
		if ( $op =~ /^( >= | <= | > | < )$/x ) {
			my $ln = _to_number($lv);
			my $rn = _to_number($rv);
			my $ok;
			if ( defined $ln && defined $rn ) {
				$ok = ($op eq '>=' ? $ln >= $rn
					:  $op eq '<=' ? $ln <= $rn
					:  $op eq '>'  ? $ln >  $rn
					:               $ln <  $rn);
			} else {
				my $ls = _to_string($lv) // '';
				my $rs = _to_string($rv) // '';
				$ok = ($op eq '>=' ? $ls ge $rs
					:  $op eq '<=' ? $ls le $rs
					:  $op eq '>'  ? $ls gt $rs
					:               $ls lt $rs);
			}
			return (Data::ZPath::Node->_wrap($ok ? !!1 : !!0));
		}

		# Bitwise ops (ints)
		if ( $op eq '&' || $op eq '|' || $op eq '^' ) {
			my $ln = _to_number($lv);
			my $rn = _to_number($rv);
			return () unless defined $ln && defined $rn;
			my $li = int($ln);
			my $ri = int($rn);
			my $res = ($op eq '&') ? ($li & $ri) : ($op eq '|') ? ($li | $ri) : ($li ^ $ri);
			return (Data::ZPath::Node->_wrap($res));
		}

		# Arithmetic (scalar only)
		if ( $op eq '+' || $op eq '-' || $op eq '*' || $op eq '/' || $op eq '%' ) {
			my $ln = _to_number($lv);
			my $rn = _to_number($rv);

			if ( $op eq '%' and $ln=~/\./ || $rn=~/\./ ) {
				return Data::ZPath::Node->_wrap(_floaty_modulus($ln, $rn));
			}

			return () unless defined $ln && defined $rn;
			my $res =
				$op eq '+' ? ($ln + $rn) :
				$op eq '-' ? ($ln - $rn) :
				$op eq '*' ? ($ln * $rn) :
				$op eq '/' ? ($rn == 0 ? undef : ($ln / $rn)) :
				($rn == 0 ? undef : ($ln % $rn));
			return unless defined $res;
			return Data::ZPath::Node->_wrap($res);
		}

		croak "Unknown binary op $op";
	}

	if ( $t eq 'ternary' ) {
		my @c = _eval_expr($ast->{c}, $ctx);
		my $cond = _truthy($c[0]);
		return $cond ? _eval_expr($ast->{a}, $ctx) : _eval_expr($ast->{b}, $ctx);
	}

	croak "Unknown AST node type: $t";
}

# Reference implementation of ZPath is in Java, which has a sane
# floating point modulus opertator. Try to implement equivalent in Perl.
sub _floaty_modulus {
	my ( $ln, $rn ) = @_;
	my $count = POSIX::floor($ln / $rn);
	$ln - ( $count * $rn );
}

sub _eval_path {
	my ( $path_ast, $ctx ) = @_;

	my @current = @{$ctx->nodeset};
	my $parentset = $ctx->parentset;

	for my $seg (@{$path_ast->{s}}) {
		my @next;

		if ( $seg->{k} eq 'root' ) {
			@next = ($ctx->root);
		}
		elsif ( $seg->{k} eq 'dot' ) {
			@next = @current;
		}
		elsif ( $seg->{k} eq 'parent' ) {
			@next = grep { defined $_ } map { $_->parent } @current;
			@next = _dedup_nodes(@next);
		}
		elsif ( $seg->{k} eq 'ancestors' ) {
			my @anc;
			for my $n (@current) {
				my $p = $n->parent;
				while ( $p ) {
					push @anc, $p;
					$p = $p->parent;
				}
			}
			@next = _dedup_nodes(@anc);
		}
		elsif ( $seg->{k} eq 'star' ) {
			my @kids;
			for my $n (@current) {
				push @kids, grep { $_->type ne 'attr' } $n->children;
			}
			@next = _dedup_nodes(@kids);
		}
		elsif ( $seg->{k} eq 'desc' ) {
			my @acc;
			my @stack = @current;
			while ( @stack ) {
				my $n = shift @stack;
				push @acc, $n;
				my @kids = grep { $_->type ne 'attr' } $n->children;
				push @stack, @kids;
			}
			@next = _dedup_nodes(@acc);
		}
		elsif ( $seg->{k} eq 'index' ) {
			my $idx = $seg->{i};
			my @kids;
			for my $n (@current) {
				my @ch = grep { $_->type ne 'attr' } $n->children;
				push @kids, $ch[$idx] if defined $ch[$idx];
			}
			@next = _dedup_nodes(@kids);
		}
		elsif ( $seg->{k} eq 'fnseg' ) {
			my @out;
			for my $n (@current) {
				my $seg_ctx = $ctx->with_nodeset( [$n], \@current );
				my @res = _eval_fn({ t => 'fn', n => $seg->{n}, a => $seg->{a} }, $seg_ctx);
				push @out, @res;
			}
			@next = @out;
		}
		elsif ( $seg->{k} eq 'name' ) {
			my $name = $seg->{n};

			# XML attribute shorthand: @name or @*
			if ( $name =~ /^\@/ ) {
				if ( $name eq '@*' ) {
					my @attrs;
					for my $n (@current) { push @attrs, $n->attributes; }
					@next = _dedup_nodes(@attrs);
				} else {
					my $attr_name = substr($name, 1);
					my @attrs;
					for my $n (@current) {
						my $raw = $n->raw;
						next unless blessed($raw) && $raw->isa('XML::LibXML::Element');
						my $a = $raw->getAttributeNode($attr_name);
						push @attrs, Data::ZPath::Node->_wrap($a, $n, '@'.$attr_name) if $a;
					}
					@next = _dedup_nodes(@attrs);
				}
			} else {
				my @kids;
				for my $n (@current) {
					my @ch = grep { $_->type ne 'attr' } $n->children;
					push @kids, grep { (defined($_->name) && $_->name eq $name) } @ch;
				}
				@next = _dedup_nodes(@kids);
			}

			if ( defined $seg->{i} ) {
				my $idx = $seg->{i};
				# interpret as: among matching name children for each parent, pick #idx
				my @picked;
				for my $n (@current) {
					my @ch = grep { $_->type ne 'attr' } $n->children;
					my @m  = grep { (defined($_->name) && $_->name eq $name) } @ch;
					push @picked, $m[$idx] if defined $m[$idx];
				}
				@next = _dedup_nodes(@picked);
			}
		}
		else {
			croak "Unknown path segment kind: $seg->{k}";
		}

		# qualifiers
		if ( $seg->{q} && @{$seg->{q}} ) {
			QUALIFIER:
			for my $q (@{$seg->{q}}) {
				if ( 
					$q->{t}
					and $q->{t} eq 'num'
					and $q->{v} =~ /\A[0-9]+\z/
				) {
					my $idx = 0 + $q->{v};

					if ( 
						@next
						and blessed($next[0]->raw)
						and $next[0]->raw->isa('XML::LibXML::Node')
					) {
						@next = defined $next[$idx] ? ( $next[$idx] ) : ();
					}
					else {
						my @picked;
						for my $node (@next) {
							my @ch = grep { $_->type ne 'attr' } $node->children;
							push @picked, $ch[$idx] if defined $ch[$idx];
						}
						@next = @picked;
					}

					next QUALIFIER;
				}

				my @filtered;
				for ( my $i = 0; $i < @next; $i++ ) {
					my $node = $next[$i];
					my $ns_ctx = $ctx->with_nodeset(\@next, \@current);
					my @r = _eval_expr($q, $ns_ctx->with_nodeset([$node], \@next));

					my $ok;
					if ( $q->{t} and $q->{t} eq 'path' ) {
						$ok = scalar(@r) ? 1 : 0;
					}
					else {
						$ok = _truthy($r[0]);
					}

					push @filtered, $node if $ok;
				}
				@next = @filtered;
			}
		}

		$parentset = \@current;
		@current = @next;
	}

	return @current;
}

sub _eval_fn {
	my ( $fn_ast, $ctx ) = @_;
	my $name = $fn_ast->{n};
	my @args = @{$fn_ast->{a}};

	my $ns = $ctx->nodeset;

	# helpers
	my $eval_arg = sub {
		my ( $i, $local_ctx ) = @_;
		return _eval_expr($args[$i], $local_ctx // $ctx);
	};

	return Data::ZPath::Node->_wrap(!!0) if $name eq 'false';
	return Data::ZPath::Node->_wrap(!!1) if $name eq 'true';
	return Data::ZPath::Node->_wrap(undef) if $name eq 'null';

	if ( $name eq 'count' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return Data::ZPath::Node->_wrap(scalar(@r));
		}
		my $scope = $ctx->parentset // $ns;
		return Data::ZPath::Node->_wrap(scalar(@$scope));
	}

	if ( $name eq 'index' ) {
		if ( @args ) {
			# index(expression): for each node matched, its index into its parent
			my @r = $eval_arg->(0);
			my @out;
			for my $n (@r) {
				if ( defined( my $i = $n->ix ) ) {
					push @out, Data::ZPath::Node->_wrap(0+$i);
				}
				elsif ( defined( my $k = $n->key ) ) {
					push @out, Data::ZPath::Node->_wrap(0+$k) if $k =~ /^[0-9]+$/;
				}
			}
			return @out;
		}

		# index() within qualifier scope: index of THIS node in parentset; otherwise nodeset
		my $cur = $ns->[0];
		return unless $cur;

		my $scope = $ctx->parentset // $ns;
		my $ix = $cur->ix;
		return Data::ZPath::Node->_wrap($ix) if defined $ix;
		my $id = $cur->id;
		return unless defined $id;
		for ( my $i = 0; $i < @$scope; $i++ ) {
			my $nid = $scope->[$i]->id;
			if ( defined $nid && $nid eq $id ) {
				return Data::ZPath::Node->_wrap($i);
			}
		}
		return Data::ZPath::Node->_wrap(0);
	}

	if ( $name eq 'key' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return map {
				my $k = $_->key;
				defined $k ? Data::ZPath::Node->_wrap($k) : ()
			} @r;
		}
		my $cur = $ns->[0];
		return unless $cur && defined $cur->key;
		return Data::ZPath::Node->_wrap($cur->key);
	}

	if ( $name eq 'union' ) {
		my @all;
		for my $i (0 .. $#args) {
			push @all, $eval_arg->($i);
		}
		return _dedup_nodes(@all);
	}

	if ( $name eq 'intersection' ) {
		return () unless @args;
		my @base = $eval_arg->(0);
		my %have = map { $_->id // ("p:".refaddr(\$_)) => $_ } @base;

		for my $i (1 .. $#args) {
			my @r = $eval_arg->($i);
			my %next = map { $_->id // ("p:".refaddr(\$_)) => 1 } @r;
			for my $k (keys %have) {
				delete $have{$k} unless $next{$k};
			}
		}
		return values %have;
	}

	if ( $name eq 'is-first' ) {
		my $cur = $ns->[0];
		return unless $cur && $cur->parent;
		return Data::ZPath::Node->_wrap($cur->ix == 0);
	}

	if ( $name eq 'is-last' ) {
		my @i = _eval_fn({ t=>'fn', n=>'index', a=>[] }, $ctx);
		my @c = _eval_fn({ t=>'fn', n=>'count', a=>[] }, $ctx);
		return () unless @i && @c;
		return (Data::ZPath::Node->_wrap($i[0]->primitive_value == ($c[0]->primitive_value - 1) ? !!1 : !!0));
	}

	if ( $name eq 'next' || $name eq 'prev' ) {
		my $cur = $ns->[0];
		return unless $cur && $cur->parent;
		my @siblings = grep { $_->type ne 'attr' } $cur->parent->children;
		my $i;
		for my $ix ( 0 .. $#siblings ) {
			my $sraw = $siblings[$ix]->raw;
			my $craw = $cur->raw;
			if (  blessed($sraw) and blessed($craw)
				and $sraw->isa('XML::LibXML::Node')
				and $craw->isa('XML::LibXML::Node') ) {
				next unless eval { $sraw->isSameNode($craw) };
				$i = $ix;
				last;
			}
			next unless defined $siblings[$ix]->id and defined $cur->id;
			if ( $siblings[$ix]->id eq $cur->id ) {
				$i = $ix;
				last;
			}
		}

		return unless defined $i;
		my $ni = $name eq 'next' ? $i + 1 : $i - 1;
		return if $ni < 0 || $ni > $#siblings;
		return $siblings[$ni];
	}

	if ( $name eq 'string' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return map {
				my $s = $_->string_value;
				defined $s ? Data::ZPath::Node->_wrap($s) : ()
			} @r;
		}
		my $cur = $ns->[0];
		return () unless $cur;
		my $s = $cur->string_value;
		return defined $s ? (Data::ZPath::Node->_wrap($s)) : ();
	}

	if ( $name eq 'number' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return map {
				my $n = $_->number_value;
				defined $n ? Data::ZPath::Node->_wrap($n) : ()
			} @r;
		}
		my $cur = $ns->[0];
		return unless $cur;
		my $n = $cur->number_value;
		return defined $n ? Data::ZPath::Node->_wrap($n) : ();
	}

	if ( $name eq 'value' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return map {
				my $v = $_->primitive_value;
				Data::ZPath::Node->_wrap($v)
			} @r;
		}
		my $cur = $ns->[0];
		return unless $cur;
		return Data::ZPath::Node->_wrap($cur->primitive_value);
	}

	if ( $name eq 'type' ) {
		if ( @args ) {
			my @r = $eval_arg->(0);
			return Data::ZPath::Node->_wrap('undefined') unless @r;
			return map {
				Data::ZPath::Node->_wrap($_->type)
			} @r;
		}
		my $cur = $ns->[0];
		return Data::ZPath::Node->_wrap($cur ? $cur->type : 'undefined');
	}

	# Math helpers: map numeric over input set
	my $num_input = sub {
		my ( $expr_idx ) = @_;
		my @in = @args ? $eval_arg->($expr_idx) : @$ns;
		return map { $_->number_value } @in;
	};

	if ( $name eq 'ceil' || $name eq 'floor' || $name eq 'round' ) {
		my @in = $num_input->(0);
		my @out;
		for my $x (@in) {
			next unless defined $x;
			my $v = $name eq 'ceil'  ? POSIX::ceil($x)
				  : $name eq 'floor' ? POSIX::floor($x)
				  :                    int($x + ($x >= 0 ? 0.5 : -0.5));
			push @out, Data::ZPath::Node->_wrap($v);
		}
		return @out;
	}

	if ( $name eq 'sum' || $name eq 'min' || $name eq 'max' ) {
		my @in;
		if ( @args ) {
			for my $i ( 0 .. $#args ) {
				push @in, $num_input->($i);
			}
		} else {
			@in = $num_input->(0);
		}

		@in = grep { defined } @in;
		return unless @in;

		if ( $name eq 'sum' ) {
			my $s = 0;
			$s += $_ for @in;
			return Data::ZPath::Node->_wrap($s);
		}
		if ( $name eq 'min' ) {
			my $m = $in[0];
			( $_ < $m ) and ( $m = $_ ) for @in;
			return Data::ZPath::Node->_wrap($m);
		}
		my $m = $in[0];
		( $_ > $m ) and ( $m = $_ ) for @in;
		return Data::ZPath::Node->_wrap($m);
	}

	# String helpers
	my $str_input = sub {
		my ( $expr_idx ) = @_;
		my @in = @args ? $eval_arg->($expr_idx) : @$ns;
		return map { $_->string_value } @in;
	};

	if ( $name eq 'escape' ) {
		my @in;
		if ( @args ) {
			for my $i (0..$#args) { push @in, $eval_arg->($i); }
		} else {
			@in = @$ns;
		}
		return map {
			my $s = $_->string_value // '';
			$s =~ s/&/&amp;/g;
			$s =~ s/</&lt;/g;
			$s =~ s/>/&gt;/g;
			$s =~ s/"/&quot;/g;
			$s =~ s/'/&apos;/g;
			Data::ZPath::Node->_wrap($s)
		} @in;
	}

	if ( $name eq 'unescape' ) {
		my @in;
		if ( @args ) {
			for my $i (0..$#args) { push @in, $eval_arg->($i); }
		} else {
			@in = @$ns;
		}
		return map {
			my $s = $_->string_value // '';
			$s =~ s/&lt;/</g;
			$s =~ s/&gt;/>/g;
			$s =~ s/&quot;/"/g;
			$s =~ s/&apos;/'/g;
			$s =~ s/&amp;/&/g;
			Data::ZPath::Node->_wrap($s)
		} @in;
	}

	if ( $name eq 'literal' ) {
		# ZTemplate-specific behavior; for Data::ZPath, it's a no-op passthrough
		my @in;
		if ( @args ) {
			for my $i (0..$#args) { push @in, $eval_arg->($i); }
		} else {
			@in = @$ns;
		}
		return @in;
	}

	if ( $name eq 'format' ) {
		croak "format(format, expression)" unless @args >= 1;
		my @fmt = $eval_arg->(0);
		my $f = $fmt[0] ? ($fmt[0]->string_value // '') : '';
		my @in = @args > 1 ? $eval_arg->(1) : @$ns;
		return map {
			my $v = $_->primitive_value;
			Data::ZPath::Node->_wrap(sprintf($f, $v))
		} @in;
	}

	if ( $name eq 'index-of' || $name eq 'last-index-of' ) {
		croak "$name(search, expression)" unless @args >= 1;
		my $search = ($eval_arg->(0))[0]->string_value // '';
		my @in = @args > 1 ? $eval_arg->(1) : @$ns;
		return map {
			my $s = $_->string_value // '';
			my $pos = $name eq 'index-of' ? index($search, $s) : rindex($search, $s);
			Data::ZPath::Node->_wrap($pos)
		} @in;
	}

	if ( $name eq 'string-length' ) {
		my @in = @args ? $eval_arg->(0) : @$ns;
		return map {
			my $s = $_->string_value // '';
			Data::ZPath::Node->_wrap(length($s))
		} @in;
	}

	if ( $name eq 'upper-case' || $name eq 'lower-case' ) {
		my @in = @args ? $eval_arg->(0) : @$ns;
		return map {
			my $s = $_->string_value // '';
			$s = $name eq 'upper-case' ? uc($s) : lc($s);
			Data::ZPath::Node->_wrap($s)
		} @in;
	}

	if ( $name eq 'substring' ) {
		croak "substring(expression, start, length)" unless @args >= 2;
		my @in = @args > 2 ? $eval_arg->(0) : @$ns;
		my $start = ($eval_arg->(1))[0]->number_value // 0;
		my $len   = ($eval_arg->(2))[0]->number_value // 0;
		return map {
			my $s = $_->string_value // '';
			Data::ZPath::Node->_wrap(substr($s, int($start), int($len)))
		} @in;
	}

	if ( $name eq 'match' || $name eq 'matches' ) {
		croak "match(pattern, expression)" unless @args >= 1;
		my $pat = ($eval_arg->(0))[0]->string_value // '';
		my $re = _pattern_to_regexp( $pat );

		my @in = @args > 1 ? $eval_arg->(1) : @$ns;
		return map {
			my $s = $_->string_value // '';
			Data::ZPath::Node->_wrap(($s =~ $re) ? 1 : 0)
		} @in;
	}

	if ( $name eq 'replace' ) {
		croak "replace(pattern, replace, expression)" unless @args >= 2;
		my $pat = ($eval_arg->(0))[0]->string_value // '';
		my $rep = ($eval_arg->(1))[0]->string_value // '';
		my $re = _pattern_to_regexp( $pat );

		my @in = @args > 2 ? $eval_arg->(2) : @$ns;
		return map {
			my $s = $_->string_value // '';
			Data::ZPath::Node->_wrap(_string_replace($s, $re, $rep))
		} @in;
	}

	if ( $name eq 'join' ) {
		croak "join(joiner, expression)" unless @args >= 1;
		my $joiner = ($eval_arg->(0))[0]->string_value // '';
		my @in = @args > 1 ? $eval_arg->(1) : @$ns;
		my @ss = map { $_->string_value // '' } @in;
		return Data::ZPath::Node->_wrap(join($joiner, @ss));
	}

	# XML functions
	if ( $name eq 'url' ) {
		my @in = @args ? $eval_arg->(0) : @$ns;
		return map {
			my $raw = $_->raw;
			my $u = '';
			if ( blessed($raw) && $raw->can('namespaceURI') ) {
				$u = $raw->namespaceURI // '';
			}
			Data::ZPath::Node->_wrap($u)
		} @in;
	}

	if ( $name eq 'local-name' ) {
		my @in = @args ? $eval_arg->(0) : @$ns;
		return map {
			my $raw = $_->raw;
			my $ln = '';
			if ( blessed($raw) && $raw->can('localname') ) {
				$ln = $raw->localname // ($raw->nodeName // '');
			} else {
				$ln = $_->name // '';
			}
			Data::ZPath::Node->_wrap($ln)
		} @in;
	}

	# CBOR tag() (optional marker), returns empty set if absent
	if ( $name eq 'tag' ) {
		my @in = @args ? $eval_arg->(0) : @$ns;
		my @out;
		for my $n (@in) {
			my $raw = $n->raw;
			if ( blessed($raw) and $raw->isa('CBOR::Free::Tagged') ) {
				push @out, Data::ZPath::Node->_wrap($raw->[0]);
			}
		}
		return @out;
	}

	croak "Unknown function '$name'";
}

sub _string_replace {
	my ( $string, $pattern, $replacement ) = @_;

	my @matches = ( $string =~ /$pattern/p );
	unshift @matches, ${^MATCH};
	$string =~ s{$pattern}{
		my $r = "$replacement";
		$r =~ s{ \$ ([0-9]+) }{
			$1 <= $#matches ? $matches[$1] : ''
		}xeg;
		$r;
	}eg;

	return $string;
}

sub _dedup_nodes {
	my %seen;
	return grep {
		my $raw = $_->raw;
		my $key = $_->id;

		if ( blessed($raw) and $raw->isa('XML::LibXML::Node') ) {
			$key = join ':', 'xmlpath', $raw->nodeType, ($raw->nodePath // q{});
		}

		not $seen{$key}++;
	} @_;
}

sub _truthy {
	my ( $n ) = @_;
	return !!0 unless $n;
	my $pv = $n->primitive_value;
	return !!$pv;
}

sub _to_number {
	my ( $n ) = @_;
	return undef unless $n;
	return $n->number_value;
}

sub _to_string {
	my ( $n ) = @_;
	return undef unless $n;
	return $n->string_value;
}


sub _equals {
	my ( $a, $b ) = @_;
	return !!0 unless $a && $b;

	my $a_type = $a->type;
	my $b_type = $b->type;

	return $a_type eq 'null' if $b_type eq 'null';
	return $b_type eq 'null' if $a_type eq 'null';

	if ( $a_type eq 'boolean' and $b_type eq 'boolean' ) {
		my $av = !!$a->primative_value;
		my $bv = !!$b->primative_value;

		return $av == $bv;
	}

	if ( $a_type eq 'number' and $b_type eq 'number' ) {
		my $av = $a->number_value;
		my $bv = $b->number_value;

		# Floating point comparison
		if ( $av =~ /\./ or $bv =~ /\./ ) {
			return abs($av-$bv) < $Data::ZPath::Epsilon;
		}

		return $av == $bv;
	}

	my @string_like = qw( string text attr comment element );
	if (  grep { $a_type eq $_ } @string_like
	and  grep { $b_type eq $_ } @string_like ) {
		my $av = $a->string_value;
		my $bv = $b->string_value;
		return "$av" eq "$bv";
	}

	return unless $a->id;
	return unless $b->id;
	return $a->id eq $b->id;
}


1;
