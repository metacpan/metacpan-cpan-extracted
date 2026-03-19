package Data::Hash::Patch::Smart::Engine;

use strict;
use warnings;

use Scalar::Util qw(refaddr);
use Storable qw(dclone);

sub patch {
	my ($data, $changes, %opts) = @_;

	my $copy = dclone($data);

	for my $c (@$changes) {
		_apply_change($copy, $c, \%opts);
	}

	return $copy;
}

sub _apply_change {
	my ($root, $c, $opts) = @_;

	my $op = $c->{op} or die 'change missing op';
	my $path = $c->{path} or die 'change missing path';

	# Split path into segments like ('items', '0') or ('items', '*')
	my @parts = _split_path($path);

	# Leaf is the last segment; parent is everything before it
	my $leaf = pop @parts;

	# Structural wildcard (in parent path)
	if (grep { $_ eq '*' } @parts) {
		return _apply_structural_wildcard($root, \@parts, $leaf, $c, $opts);
	}

	# Walk down to the parent container (hash or array)
	my $parent = _walk_to_parent($root, \@parts, $leaf, $opts);

	# Unordered array semantics: leaf is '*'
	if ($leaf eq '*') {
		if ($op eq 'add') {
			_add_unordered($parent, $c->{value}, $opts);
		} elsif ($op eq 'remove') {
			_remove_unordered($parent, $c->{from}, $opts);
		} else {
			die "Unsupported op '$op' for unordered path '$path'";
		}
		return;
	}

	# Normal index/hash semantics
	if ($op eq 'change') {
		_set_value($parent, $leaf, $c->{to}, $opts);
	} elsif ($op eq 'add') {
		_add_value($parent, $leaf, $c->{value}, $opts);
	} elsif ($op eq 'remove') {
		_remove_value($parent, $leaf, $opts);
	} else {
		die "Unsupported op: $op";
	}
}

sub _split_path {
	my $path = $_[0];

	return () if !defined $path || $path eq '';
	my @parts = grep { length $_ } split m{/}, $path;
	return @parts;
}

# Walk down the structure following the given path segments,
# stopping at the parent of the leaf. In strict mode, we die on
# invalid paths. With create_missing => 1, we auto-create
# intermediate hashes/arrays as needed.
sub _walk_to_parent {
	my ($cur, $parts, $leaf, $opts) = @_;

	# Walk all segments that lead to the parent of $leaf
	for (my $i = 0; $i < @$parts; $i++) {
		my $p	= $parts->[$i];
		my $is_last = ($i == $#$parts);

		# For container creation, "next" is either the next part,
		# or, if we're at the last part, the leaf segment.
		my $next = $is_last ? $leaf : $parts->[$i + 1];

		# -----------------------------
		# HASH navigation
		# -----------------------------
		if (ref($cur) eq 'HASH') {

			# Missing key
			if (!exists $cur->{$p}) {
				if ($opts->{create_missing}) {
					# Decide container type based on what comes after
					if (defined $next && $next =~ /^\d+$/) {
						$cur->{$p} = [];
					} else {
						$cur->{$p} = {};
					}
				}
				elsif ($opts->{strict}) {
					die "Invalid path: missing hash key '$p'";
				}
				else {
					return undef;
				}
			}

			$cur = $cur->{$p};
			next;
		}

		# -----------------------------
		# ARRAY navigation
		# -----------------------------
		if (ref($cur) eq 'ARRAY') {

			# Index must be numeric
			if ($p !~ /^\d+$/) {
				die "Invalid path: non-numeric array index '$p'"
					if $opts->{strict};
				return undef;
			}

			# Out of bounds
			if ($p > $#$cur) {
				if ($opts->{create_missing}) {
					# Extend array
					$#$cur = $p;

					# Decide container type for this new slot
					if (defined $next && $next =~ /^\d+$/) {
						$cur->[$p] = [];
					} else {
						$cur->[$p] = {};
					}
				}
				elsif ($opts->{strict}) {
					die "Invalid path: array index '$p' out of bounds";
				}
				else {
					return undef;
				}
			}

			$cur = $cur->[$p];
			next;
		}

		# -----------------------------
		# Undef or non-container
		# -----------------------------
		if (!defined $cur) {
			die "Invalid path: encountered undef while walking"
				if $opts->{strict};
			return undef;
		}

		die "Invalid path: cannot descend into non-container"
			if $opts->{strict};

		return undef;
	}

	return $cur;
}


sub _set_value {
	my ($parent, $leaf, $value, $opts) = @_;

	if (ref($parent) eq 'HASH') {
		if (!exists $parent->{$leaf} && $opts->{strict}) {
			die "Strict mode: cannot change missing hash key '$leaf'";
		}
		$parent->{$leaf} = $value;
		return;
	}

	if (ref($parent) eq 'ARRAY') {
		if ($leaf !~ /^\d+$/ || $leaf > $#$parent) {
			die "Strict mode: array index '$leaf' out of bounds"
				if $opts->{strict};
		}
		$parent->[$leaf] = $value;
		return;
	}

	die 'Strict mode: cannot set value on non-container' if $opts->{strict};
}

sub _add_value {
	my ($parent, $leaf, $value, $opts) = @_;

	if (ref($parent) eq 'HASH') {
		if (exists $parent->{$leaf} && $opts->{strict}) {
			die "Strict mode: cannot add existing hash key '$leaf'";
		}
		$parent->{$leaf} = $value;
		return;
	}

	if (ref($parent) eq 'ARRAY') {
		# Leaf must be numeric
		if ($leaf !~ /^\d+$/) {
			die "Strict mode: invalid array index '$leaf'"
				if $opts->{strict};
			return;
		}

		# Extend array if needed
		if ($leaf > $#$parent) {
			$#$parent = $leaf;
		}

		# Insert value at exact index
		$parent->[$leaf] = $value;
		return;
	}

	die 'Strict mode: cannot add value to non-container' if $opts->{strict};
}

sub _remove_value {
	my ($parent, $leaf, $opts) = @_;

	if (ref($parent) eq 'HASH') {
		if (!exists $parent->{$leaf} && $opts->{strict}) {
			die "Strict mode: cannot remove missing hash key '$leaf'";
		}
		delete $parent->{$leaf};
		return;
	}

	if (ref($parent) eq 'ARRAY') {
		if ($leaf !~ /^\d+$/ || $leaf > $#$parent) {
			die "Strict mode: array index '$leaf' out of bounds";
		}
		splice @$parent, $leaf, 1;
		return;
	}

	die 'Strict mode: cannot remove value from non-container' if $opts->{strict};
}

# Add a value to an unordered array.
# We treat the parent as an arrayref and simply push the new value.
sub _add_unordered {
	my ($parent, $value) = @_;

	die 'Unordered add requires an array parent' unless ref($parent) eq 'ARRAY';

	push @$parent, $value;
}

# Remove a single matching value from an unordered array.
# We scan linearly and delete the first element that compares equal.
sub _remove_unordered {
	my ($parent, $value, $opts) = @_;

	die "Unordered remove requires an array parent"
		unless ref($parent) eq 'ARRAY';

	for (my $i = 0; $i < @$parent; $i++) {
		if (!defined $parent->[$i] && !defined $value) {
			splice @$parent, $i, 1;
			return;
		}
		if (defined $parent->[$i] && defined $value && $parent->[$i] eq $value) {
			splice @$parent, $i, 1;
			return;
		}
	}

	die "Unordered remove: value '$value' not found" if $opts->{strict};

	# Non-strict: silently ignore
}

# Apply a change to all paths matching a wildcard pattern.
# Example pattern: ['users', '*', 'password']
#
# We recursively walk the data structure, matching literal segments
# and branching on '*' segments.
sub _apply_wildcard {
	my ($cur, $parts, $change, $opts, $depth) = @_;

	$depth //= 0;

	# If we've consumed all parts, we are at the leaf.
	if ($depth == @$parts) {
		# Apply the operation to this exact location.
		# We treat this as a non-wildcard leaf.
		my $op = $change->{op};

		if ($op eq 'change') {
			# Replace the entire subtree
			return $change->{to};
		} elsif ($op eq 'add') {
			# For wildcard add, we push into arrays or set hash keys
			# but since wildcard leafs are ambiguous, we do nothing here.
			# Wildcard adds are only meaningful when the leaf is '*'
			return $cur;
		} elsif ($op eq 'remove') {
			# Remove the entire subtree
			return undef;
		} else {
			die "Unsupported wildcard op: $op";
		}
	}

	my $seg = $parts->[$depth];

	# Literal segment: descend into matching child
	if ($seg ne '*') {
		if (ref($cur) eq 'HASH' && exists $cur->{$seg}) {
			$cur->{$seg} = _apply_wildcard($cur->{$seg}, $parts, $change, $opts, $depth+1);
		} elsif (ref($cur) eq 'ARRAY' && $seg =~ /^\d+$/ && $seg <= $#$cur) {
			$cur->[$seg] = _apply_wildcard($cur->[$seg], $parts, $change, $opts, $depth+1);
		}
		return;
	}

	# Wildcard segment: match all children at this level
	if (ref($cur) eq 'HASH') {
		for my $k (sort keys %$cur) {
			$cur->{$k} = _apply_wildcard($cur->{$k}, $parts, $change, $opts, $depth+1);
		}
	}
	elsif (ref($cur) eq 'ARRAY') {
		for my $i (0 .. $#$cur) {
			$cur->[$i] = _apply_wildcard($cur->[$i], $parts, $change, $opts, $depth+1);
		}
	}
}

sub _apply_structural_wildcard {
	my ($cur, $parts, $leaf, $change, $opts, $depth, $seen) = @_;

	$depth //= 0;
	$seen ||= {};

	# Detect cycles
	if (ref($cur)) {
		my $addr = refaddr($cur);
		if ($seen->{$addr}++) {
			die "Cycle detected during wildcard patch"
				if $opts->{strict};
			return;
		}
	}

	# If we've matched all wildcard segments, apply leaf op
	if ($depth == @$parts) {
		return _apply_leaf_op($cur, $leaf, $change, $opts);
	}

	my $seg = $parts->[$depth];

	# Literal segment
	if ($seg ne '*') {
		if (ref($cur) eq 'HASH' && exists $cur->{$seg}) {
			_apply_structural_wildcard($cur->{$seg}, $parts, $leaf, $change, $opts, $depth+1, $seen);
		} elsif (ref($cur) eq 'ARRAY' && $seg =~ /^\d+$/ && $seg <= $#$cur) {
			_apply_structural_wildcard($cur->[$seg], $parts, $leaf, $change, $opts, $depth+1, $seen);
		}
		return;
	}

	# Wildcard segment
	if (ref($cur) eq 'HASH') {
		for my $k (keys %$cur) {
			_apply_structural_wildcard($cur->{$k}, $parts, $leaf, $change, $opts, $depth+1, $seen);
		}
	} elsif (ref($cur) eq 'ARRAY') {
		for my $i (0 .. $#$cur) {
			_apply_structural_wildcard($cur->[$i], $parts, $leaf, $change, $opts, $depth+1, $seen);
		}
	}
}


sub _apply_leaf_op {
	my ($parent, $leaf, $change, $opts) = @_;

	my $op = $change->{op};

	if ($op eq 'change') {
		return _set_value($parent, $leaf, $change->{to}, $opts);
	} elsif ($op eq 'add') {
		return _add_value($parent, $leaf, $change->{value}, $opts);
	} elsif ($op eq 'remove') {
		return _remove_value($parent, $leaf, $opts);
	}

	die "Unsupported op '$op' in wildcard patch";
}

1;
