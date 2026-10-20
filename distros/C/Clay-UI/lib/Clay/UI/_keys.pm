package Clay::UI::_keys;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed reftype);
use Exporter 'import';
use Clay::UI::_error qw(croak_ui);

our @EXPORT_OK = qw(camelize_keys camelize_string snake_keys snake_string);

# The walker camelizes every widget's config every frame, and the keys
# come from a small closed set (Clay's field names), so conversions are
# cached. Each cache stops growing at a fixed size, so arbitrary keys (from
# a bad attribute value, say) cannot make it grow without bound.
my %camelized;
my %snaked;
my $CACHE_MAX = 4096;

sub camelize_string ($key) {
	my $cached = $camelized{$key};
	return $cached if defined $cached;
	my $camel = _camelize($key);
	$camelized{$key} = $camel if keys %camelized < $CACHE_MAX;
	return $camel;
}

sub _camelize ($key) {
	return $key unless $key =~ /_/;
	my @parts = split /_/, $key, -1;
	my $head  = shift @parts;
	for my $part (@parts) {
		next unless length $part;
		my $first = substr($part, 0, 1);
		substr($part, 0, 1) = uc $first if $first =~ /[a-z]/;
	}
	return join '', $head, @parts;
}

sub snake_string ($key) {
	my $cached = $snaked{$key};
	return $cached if defined $cached;
	my $snake = $key =~ s/([A-Z])/_\l$1/gr;
	$snaked{$key} = $snake if keys %snaked < $CACHE_MAX;
	return $snake;
}

sub camelize_keys ($node) {
	return $node unless ref $node;
	return $node if blessed $node;

	my $type = reftype $node;

	# Leaves are copied inline: this runs for every widget every frame.
	if ($type eq 'HASH') {
		my %out;
		for my $key (keys %$node) {
			my $new_key = $camelized{$key} // camelize_string($key);
			if ($new_key ne $key && exists $node->{$new_key}) {
				croak_ui "Clay::UI: key '$key' camelizes to '$new_key', which is already present in the same hash";
			}
			if (exists $out{$new_key}) {
				croak_ui "Clay::UI: key '$key' collides with another key that camelized to '$new_key'";
			}
			my $value = $node->{$key};
			$out{$new_key} = ref $value ? camelize_keys($value) : $value;
		}
		return \%out;
	}

	if ($type eq 'ARRAY') {
		return [ map { ref $_ ? camelize_keys($_) : $_ } @$node ];
	}

	return $node;
}

# The mirror of camelize_keys, run where attributes are set: same
# traversal, snake_case keys. $where names the value in collision errors
# (an attribute name, extended by the path below it).
sub snake_keys ($node, $where = undef) {
	return $node unless ref $node;
	return $node if blessed $node;

	my $type = reftype $node;

	if ($type eq 'HASH') {
		my $in = defined $where ? " in '$where'" : '';
		my %out;
		for my $key (keys %$node) {
			my $new_key = snake_string($key);
			if ($new_key ne $key && exists $node->{$new_key}) {
				croak_ui "Clay::UI: key '$key'$in is '$new_key' in snake_case, which is already present in the same hash";
			}
			if (exists $out{$new_key}) {
				croak_ui "Clay::UI: key '$key'$in collides with another key that is '$new_key' in snake_case";
			}
			my $value = $node->{$key};
			$out{$new_key} = ref $value ? snake_keys($value, defined $where ? "$where.$new_key" : undef) : $value;
		}
		return \%out;
	}

	if ($type eq 'ARRAY') {
		return [ map { ref $node->[$_] ? snake_keys($node->[$_], defined $where ? "$where.$_" : undef) : $node->[$_] } 0 .. $#$node ];
	}

	return $node;
}

1;

__END__

=head1 NAME

Clay::UI::_keys - internal snake_case and camelCase key translator

=head1 DESCRIPTION

Pure helper used by the L<Clay::UI> high-level layer. Widgets store
Clay values with C<snake_case> keys whatever spelling the caller used
(C<snake_keys>, run where attributes are set), and the layout pass
rewrites them to the C<camelCase> field names the underlying
L<Clay::XS> binding expects (C<camelize_keys>).

This module is internal. The API is not part of the public contract.

=head1 FUNCTIONS

=head2 camelize_string($key)

Returns the camelCase form of a snake_case string. Keys containing no
underscore are returned unchanged.

=head2 snake_string($key)

Returns the snake_case form of a camelCase string, the inverse of
C<camelize_string> for keys Clay uses (C<childGap> becomes C<child_gap>).
Used by C<snake_keys> and to report Clay paths in the spelling widgets
store.

=head2 camelize_keys($node)

Recurses through hashes and arrays, returning a new structure in which
every hash key has been camelized. Blessed references, coderefs, and
scalars pass through untouched. Throws if two source keys would collide
after camelization (for example, both C<backgroundColor> and
C<background_color> in the same hash).

=head2 snake_keys($node, $where)

The mirror of C<camelize_keys>: returns a new structure in which every
hash key is in snake_case (C<childGap> becomes C<child_gap>), with the
same traversal rules. Throws if two source keys would collide after the
conversion; the message names C<$where> (optional, for example the
attribute name) and the path below it.

=cut
