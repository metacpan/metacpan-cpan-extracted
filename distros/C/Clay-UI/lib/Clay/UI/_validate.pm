package Clay::UI::_validate;
our $VERSION = '0.07';
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Scalar::Util qw(blessed reftype looks_like_number);
use overload ();
use Exporter 'import';

use Clay::XS qw(check_struct);
use Clay::UI::_keys qw(camelize_keys snake_keys snake_string);
use Clay::UI::_error qw(croak_ui);

our @EXPORT_OK = qw(
	optional
	required
	clay_struct
	clay_field
	copy_value
	is_finite_number
	is_index
	shown_value
	described_value
	require_predicate
	validate_border_width
	validate_id
	validate_group_id
	validate_text
	USER_GROUP_ID_MAX
);

# The largest user sizing-group id. Clay::UI::Grid packs its own ids
# above it (grid id << the bits of this range), so the two never meet.
use constant USER_GROUP_ID_MAX => (1 << 20) - 1;

sub _fail ($name, $message) {
	croak_ui "Clay::UI: '$name' $message";
}

# A plain (non-reference) number that is neither NaN nor infinite.
sub is_finite_number ($value) {
	return defined $value && !ref $value && looks_like_number($value)
		&& $value == $value && $value != 9**9**9 && $value != -9**9**9;
}

# A child, row or column index: a non-negative integer in plain decimal
# digits without leading zeros (so '01' and '1' are never two indices),
# defined and not a reference.
sub is_index ($value) {
	return defined $value && !ref $value && $value =~ /\A(?:0|[1-9][0-9]*)\z/ ? 1 : 0;
}

# A value as an error message shows it: the value itself, its reference
# type, or 'undef'.
sub shown_value ($value) {
	return 'undef' unless defined $value;
	return ref($value) || $value;
}

# The same for a "got ..." message: a string is quoted.
sub described_value ($value) {
	return ref($value) || (defined $value ? "'$value'" : 'undef');
}

# Dies unless $predicate, an argument of $method, is a code reference.
sub require_predicate ($method, $predicate) {
	croak_ui "Clay::UI: $method takes a code reference, got " . described_value($predicate)
		unless ref $predicate && reftype($predicate) eq 'CODE';
	return;
}

# A deep copy of the hashes and arrays in $value, as plain (unblessed)
# data: Clay reads a blessed hash like any other. Scalars and objects with
# overloading (value objects such as Math::BigInt numbers) are kept as
# they are. Attribute values are copied where they are validated and
# where they are read, so the widget never shares a container with its
# caller.
sub copy_value ($value) {
	return $value if !ref $value || (blessed $value && overload::Overloaded($value));
	my $type = reftype $value;
	if ($type eq 'HASH') {
		return { map { my $v = $value->{$_}; $_ => (ref $v ? copy_value($v) : $v) } keys %$value };
	}
	return [ map { ref $_ ? copy_value($_) : $_ } @$value ] if $type eq 'ARRAY';
	return $value;
}

# Accessor helpers: apply $validator to the single value written to an
# attribute. optional() lets undef through (attribute unset); required()
# does not.
sub optional ($validator, $name, @value) {
	croak_ui "Clay::UI: '$name' takes one value" unless @value == 1;
	return undef unless defined $value[0];
	return $validator->($name, $value[0]);
}

sub required ($validator, $name, @value) {
	croak_ui "Clay::UI: '$name' takes one value" unless @value == 1;
	return $validator->($name, $value[0]);
}

# Validators for Clay values: check mode of Clay::XS (check_struct) does
# the checking, so the rules are exactly those Clay::XS applies when the
# value reaches Clay. clay_struct checks a whole struct, clay_field one
# field of it (named by its C name).
sub clay_struct ($type) {
	return sub ($name, $value) { _check($name, $type, $value) };
}

sub clay_field ($type, $field) {
	return sub ($name, $value) { _check($name, $type, $value, $field) };
}

# Returns the value as the widget stores it: a copy with snake_case keys,
# whatever spelling the caller used. Runs check_struct on its camelized
# form and rethrows its error in Clay::UI's words: the attribute name plus
# the snake_case path inside it.
sub _check ($name, $type, $value, $field = undef) {
	_fail($name, 'must be defined') unless defined $value;
	my $stored = snake_keys(copy_value($value), $name);
	my $input  = camelize_keys(defined $field ? { $field => $stored } : $stored);
	return $stored if eval { check_struct($type, $input, $name); 1 };

	my $error = $@;
	die $error unless blessed $error && $error->isa('Clay::XS::StructError');

	my ($root, @inner) = @{ $error->path };
	shift @inner if defined $field;
	my $where = join '.', $root, map { snake_string($_) } @inner;

	if (my $unknown = $error->unknown_keys) {
		_fail($where, sprintf "has unknown key%s %s (known keys: %s)",
			@$unknown > 1 ? 's' : '',
			join(', ', map { "'" . snake_string($_) . "'" } @$unknown),
			join(', ', map { snake_string($_) } @{ $error->known_keys }));
	}
	my $message = 'expected ' . $error->expected . ', got ' . $error->got;
	$message .= ' (' . $error->hint . ')' if defined $error->hint;
	_fail($where, $message);
}

# A number applies to the four outer sides (Clay::UI::Role::Style::HasBorder
# expands it); anything else is a Clay_BorderWidth.
sub validate_border_width ($name, $value) {
	return _check($name, 'Clay_BorderWidth', $value, 'left') if defined $value && !ref $value;
	return _check($name, 'Clay_BorderWidth', $value);
}

sub validate_id ($name, $value) {
	_fail($name, 'must be a non-empty string')
		unless defined $value && !ref $value && length $value;
	_fail($name, "must not start with 'anon:' (reserved for the ids Clay::UI derives for widgets without one)")
		if index($value, 'anon:') == 0;
	return $value;
}

sub validate_group_id ($name, $value) {
	_fail($name, 'must be an integer in 0..' . USER_GROUP_ID_MAX . ' (larger ids are reserved for Clay::UI::Grid)')
		unless is_finite_number($value) && $value == int($value) && $value >= 0 && $value <= USER_GROUP_ID_MAX;
	return $value;
}

sub validate_text ($name, $value) {
	_fail($name, 'must be a defined string') unless defined $value && !ref $value;
	return $value;
}

1;

__END__

=head1 NAME

Clay::UI::_validate - internal attribute validation for Clay::UI widgets

=head1 DESCRIPTION

Functions the widget roles call from their constructors and accessors,
so a bad attribute dies where it is set instead of when the tree is
rendered. C<optional> and C<required> wrap a validator for the
one-argument write of an accessor (C<optional> accepts undef). Each
validator takes the attribute name (used in the message) and the value,
dies with C<< Clay::UI: '<name>' ... >> when the value is wrong, and
otherwise returns the value: the Clay validators return a deep copy
(C<copy_value>) with snake_case keys (C<snake_keys>), so a widget never
shares a hash or array with the caller that passed it and stores one
spelling of every key, and accessors return copies of what they hold.
Objects with overloading (value objects such as L<Math::BigInt>
numbers) are kept as they are.

Clay values are checked by L<Clay::XS/CHECKING STRUCTS>:
C<clay_struct($type)> returns a validator for a whole struct (for
example C<Clay_LayoutConfig>), C<clay_field($type, $field)> one for a
single field of it (for example C<fontSize> of
C<Clay_TextElementConfig>). Keys may be snake_case or camelCase and are
stored in snake_case; both spellings of one key in a hash die. Errors
name the attribute and the snake_case path inside it, e.g.
C<Clay::UI: 'layout.padding.left' expected an integer in 0..65535, got '-5'>,
and list the known keys for an unknown one.

The other validators hold Clay::UI's own rules: element ids must not
start with C<anon:>, user sizing-group ids must stay at or below
C<USER_GROUP_ID_MAX> (C<2**20 - 1>; L<Clay::UI::Grid> packs its own ids
above it), text must be a defined string, and C<border_width> may also
be a single number.

C<is_finite_number> is true for a plain number that is neither NaN nor
infinite. C<copy_value> deep-copies hashes and arrays (blessed ones
into plain data) and keeps scalars and objects with overloading as they
are.

This module is internal. The API is not part of the public contract.

=cut
