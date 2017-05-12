package Data::SimplePath;

use warnings;
use warnings::register;
use strict;

=head1 NAME

Data::SimplePath - Path-like access to complex data structures

=head1 VERSION

Version 0.005

=cut

our $VERSION = '0.005';

{
	# global options, will be used as defaults for newly created objects, can be changed on
	# import (see import):

	my %config = (
		'AUTO_ARRAY'   => 1,
		'REPLACE_LEAF' => 1,
		'SEPARATOR'    => '/',
	);

	# _global ($key, $value) - retrieves or changes global configuration options,
	#       $key        the option to get (see %config above for valid keys)
	#       $value      if defined, the option will be set to this value and a true value
	#                   will be returned, if undefined, current value of the option will be
	#                   returned
	# if $key is invalid, an undefined value will be returned

	sub _global {
		my ($key, $value) = @_;
		return unless exists $config {$key};
		if (defined $value) {
			$config {$key} = $value;
			return 1;
		}
		return $config {$key};
	}

	my $valid_number = qr/^\d+$/; # only positive integers (no sign) are valid as array index

	# _number ($var) - returns the - always true - array index if $var is a valid number (ie.
	# the number $var if it is greater than 0 or '0 but true' for the value 0 itself). if the
	# argument is not a valid number, returns undef.

	sub _number {
		my ($num) = @_;
		return unless $num =~ /$valid_number/;
		return $num == 0 ? '0 but true' : $num;
	}

}

# import (%args) - allow global options to be set when the module is used.
# eg.: use Data::SimplePath 'AUTO_ARRAY' => 1, 'SEPARATOR' => '/';
# see global config hash above for valid keys. will warn on invalid keys if enabled.

sub import {
	my ($class, %args) = @_;
	while (my ($key, $value) = each %args) {
		_warn ("Unknown option: $key") unless _global ($key, $value);
	}
	return; # birthday present for perl::critic...
}

=head1 SYNOPSIS

	# use default options
	use Data::SimplePath;

	# or change the default options for new objects:
	use Data::SimplePath 'AUTO_ARRAY'   => 0,
	                     'REPLACE_LEAF' => 0,
	                     'SEPARATOR'    => '#';

	# create new empty object with default options:
	my $a = Data::SimplePath -> new ();

	# create new object, set some initial content:
	my $b = Data::SimplePath -> new (
		{ 'k1' => 'v1', 'k2' => ['a', { 'b' => 'c' }, 'd'] }
	);

	# same as above, but override some default options:
	my $c = Data::SimplePath -> new (
		{ 'k1' => 'v1', 'k2' => ['a', { 'b' => 'c' }, 'd'] },
		{ 'AUTO_ARRAY' => 0, 'SEPARATOR' => ':' }
	);

	# get the value 'c', ':' is the separator:
	my $x = $c -> get ('k2:1:b');

	# change the separator to '/':
	$c -> separator ('/');

	# enable automatic creation of arrays for numeric keys:
	$c -> auto_array (1);

	# create a new element:
	$c -> set ('k2/4/some key/0', 'new value');

	# the object will now contain the following data:
	#
	# {
	#   'k1' => 'v1',          # k1
	#   'k2' => [              # k2
	#     'a',                 # k2/0
	#     {                    # k2/1
	#       'b' => 'c'         # k2/1/b
	#     },
	#     'd',                 # k2/2
	#     undef,               # k2/3
	#     {                    # k2/4
	#       'some key' => [    # k2/4/some key
	#         'new value'      # k2/4/some/key/0
	#       ]
	#     }
	#   ]
	# }

=head1 DESCRIPTION

This module enables path-like (as in file system path) access to complex data structures of hashes
and/or arrays. Not much more to say, see the L<SYNOPSIS> example above...

Ok, a few more notes: The data structure may consist of hashes or arrays, to an arbitrary depth,
and scalar values. You probably should not try to put blessed arrays or hashes in it, it may lead
to unexpected behaviour in some situations. 

The object containing the data structure exists only to help accessing the contents, you are free
to modify the data in any way you want without the provided methods if you like, this will not
break the object's behaviour.

The methods to access a certain element in the data structure need to know which element to act on
(of course), there are two ways of specifying the element:

=over

=item by key

The key is a single string, with parts of the path separated by the (object specific) separator.
This is the recommended way to access an element. Note that the methods will normalize the provided
key before it is used, see the C<normalize ()> method below.

=item by path

The path is an array containing the parts of the full path, it is basically the key split on the
separator string. Empty (or undef) elements are usually ignored when a path is processed.

=back

In the following documentation these two terms will be used as described above. Note that the root
of the data structure is specified as an empty key (ie. he empty string C<''>) or an empty array as
path.

=head2 Similar Modules

There are a few modules with similar functionality are available: L<Data::Path> and L<Data::DPath>
provide access to data structures using a more flexible and powerful (some may call it complicated)
XPath like matching.

L<Data::SPath> provides access to data structures using paths like C<Data::SimplePath> does
(including accessing arrayrefs with numeric keys, L<Data::Path> and L<Data::DPath> require special
syntax for arrayrefs). Also, this module does support calling object methods with method names
specified in the path, C<Data::SimplePath> does not offer special treatment for objects.

However, unlike the aforementioned modules, C<Data::SimplePath> not only provides read access to an
existing data structure, it also provides methods to create, change or delete values in the data
structure, using paths to specify the location, and automatically create nested structures if
required.

So if you only need read access, see the documentation of the modules mentioned above, maybe one is
better suited for your needs than C<Data::SimplePath>.

=head1 CONFIGURATION

Each of the following configuration options can be set for every object either when creating the
object (see C<new ()> and the example in the L<SYNOPSIS> above) or later on with the methods
C<auto_array ()>, C<replace_leaf ()> and C<separator ()> (see below). The default values for the
options are mentioned below, and these defaults can be modified on C<import ()> time, as shown in
the C<SYNOPSIS> example above.

=head2 AUTO_ARRAY

If this option is set to a true value, arrays will be created for numeric keys:

	# suppose the data structure is an empty hashref:

	# with AUTO_ARRAY set to true:
	$h -> set ('a/0/b', 'value');

	# the data structure will now contain:
	# {
	#   'a' => [         # array created due to numeric key 0
	#     {
	#       'b' => 'value'
	#     }
	#   ]
	# }

	# same with AUTO_ARRAY set to false:
	$h -> set ('a/0/b', 'value');

	# the data structure will now contain:
	# {
	#   'a' => {         # everything's a hash
	#     '0' => {
	#       'b' => 'value'
	#     }
	#   }
	# }

This only works for newly created sub-lists (and thus this setting only changes how the C<set ()>
method works), already existing hashes will not be changed, and elements in these hashes can be
created, deleted and accessed with numeric keys as usual.

The default value of this option is C<1> (enabled).

=head2 REPLACE_LEAF

If this option is true (default), an already existing scalar value in the data structure will be
replaced by a hashref or arrayref automatically if you try to C<set ()> a value beneath its path:

	# suppose the data structure contains the following data:
	# {
	#   'key' => 'value'
	# }

	# with REPLACE_LEAF disabled:
	$h -> set ('key/subkey', 'value'); # this won't work
	                                   # data is not changed

	# with REPLACE_LEAF enabled:
	$h -> set ('key/subkey', 'value'); # works

	# the data structure now contains:
	# {
	#   'key' => {
	#     'subkey' => 'value'
	#   }
	# }

Note that if this option is set to false, you can still assign a hashref (or arrayref) directly to
the element itself:

	# same result as above:
	$h -> set ('key', {'subkey' => 'value'});

The default value of this option is C<1> (enabled).

=head2 SEPARATOR

The string used to separate path elements in the key. This may be any string you like, just make
sure the string itself is not contained in any actual keys of the hashes in the data structure, you
will not be able to access such elements by key (access by path will still work, though).

The default value is C<'/'>.

=head1 CLASS METHODS

=head2 new

	my $h = Data::SimplePath -> new ($initial, $config);

Creates a new C<Data::SimplePath> object. If C<$initial> is specified, which must be either a
hashref or an arrayref, the contents of the object will be set to this data structure. C<$config>
may be used to set the configuration options for the object. It must be a hashref, valid keys are
C<'AUTO_ARRAY'>, C<'REPLACE_LEAF'> and C<'SEPARATOR'> (see the L<CONFIGURATION> section for
details). Note that you have to specify C<$initial> if you want to set configuration options, even
if you don't want to add any initial content, use C<undef> in that case:

	my $h = Data::SimplePath -> new (undef, $config);

The initial hashref (or arrayref) will be used as is, every modification of the object will alter
the original data:

	my $i = { 'a' => 'b' };
	my $h = Data::SimplePath -> new ($i);

	$h -> set ('a', 'c');
	print $i -> {'a'};	# will print the new value 'c'

Note that if C<$initial> is defined a warning will be printed if it is not a hashref or an
arraryref, see the L<WARNINGS> section below. An invalid value for C<$config> will cause no
warning, the default settings will be used in this case.

=cut

sub new {
	my ($class, $init, $config) = @_;
	my $self = {
		'DATA'         => undef,
		'AUTO_ARRAY'   => _global ('AUTO_ARRAY'),
		'REPLACE_LEAF' => _global ('REPLACE_LEAF'),
		'SEPARATOR'    => _global ('SEPARATOR'),
		_hashref ($config) ? %$config : ()
	};
	$self -> {'DATA'} = $init if _valid_root ($init);
	_warn ("Discarding invalid data: $init") if defined $init and not $self -> {'DATA'};
	return bless $self, $class;
}

sub _arrayref { return ref shift eq 'ARRAY' ? 1 : 0; }
sub _hashref  { return ref shift eq 'HASH'  ? 1 : 0; }

sub _warn {
	warnings::warn (shift) if warnings::enabled ();
	return;
}

# _is_number ($var) - basically the same as _number (), but prints a warning if $var is no number

sub _is_number {
	my ($number) = @_;
	unless ($number = _number ($number)) {
		_warn ("Trying to access array element with non-numeric key $_[0]");
		return;
	}
	return $number;
}

# _valid_root can be used as a class method (with one parameter $root) and as an object method
# (without any parameter), it will return true if $root or $self -> {'DATA'} is a hashref or an
# arrayref.

sub _valid_root {
	my ($root) = @_;
	$root = $root -> {'DATA'} if (ref $root eq __PACKAGE__);
	return (_arrayref ($root) or _hashref ($root)) ? 1 : 0;
}

=head1 OBJECT METHODS

=head2 auto_array, replace_leaf, separator

	# get current value
	my $aa = $h -> auto_array ();

	# set AUTO_ARRAY to 1, $aa will contain the old value:
	my $aa = $h -> auto_array (1);

	# the same syntax works for $h -> replace_leaf () and
	# $h -> separator ()

Get and/or set the object's C<AUTO_ARRAY>, C<REPLACE_LEAF> and C<SEPARATOR> options. If no
parameter is specified (or the paramter is C<undef>) these methods will return the current value of
the option, else the option will be set to the given (scalar) value and the old setting will be
returned.

=cut

sub auto_array   { return shift -> _config ('AUTO_ARRAY',   shift); }
sub replace_leaf { return shift -> _config ('REPLACE_LEAF', shift); }
sub separator    { return shift -> _config ('SEPARATOR',    shift); }

# _config ($key, $value) - get or set a configuration option
#    $key       the name of the option to get/set (AUTO_ARRAY, REPLACE_LEAF or SEPARATOR)
#    $value     if defined, the option is set to this new value and the old value is returned, if
#               undefined, only the current value of the option will be returned
# for invalid keys (or the DATA key) undef must be returned!

sub _config {
	my ($self, $key, $new) = @_;
	return if not exists $self -> {$key} or $key eq 'DATA';
	return $self -> {$key} unless defined $new;
	(my $old, $self -> {$key}) = ($self -> {$key}, $new);
	return $old;
}

=head2 clone

	my $copy = $h -> clone ();

Creates a new C<Data::SimplePath> object with the same contents and settings as the original one.
Both objects are independent, ie. changing the contents (or settings) of one object does not effect
the other one. (L<Storable>'s C<dclone ()> funtion is used to create the copy, see its
documentation for details.)

=over

If you actually need more than one object to modify one data structure, either create the root
reference first and pass it to the constructors of the different objects, or retrieve the root
reference from an existing object with the C<data ()> method and pass it to the constructor. This
may be useful for example if you need certain operations with C<AUTO_ARRAY> enabled and others
without the C<AUTO_ARRAY> feature.

=back

=cut

sub clone {
	my ($self) = @_;
	require Storable if $self -> {'DATA'};
	return __PACKAGE__ -> new (
		$self -> {'DATA'} ? Storable::dclone ($self -> {'DATA'}) : undef,
		{
			'AUTO_ARRAY'   => $self -> auto_array (),
			'REPLACE_LEAF' => $self -> replace_leaf (),
			'SEPARATOR'    => $self -> separator (),
		}
	);
}

=head2 data

	my $data = $h -> data ();	# get a reference to the object contents
	my %data = $h -> data ();	# or - if it's a hash - put a copy in a hash
	my @data = $h -> data ();	# or put a copy in an array

Returns the object contents. In scalar context, the reference (either a hashref or an arrayref,
depending on the data structure's root) will be returned - note that this is the actual data as
used in the object, modifications will effect the object's data. In list context L<Storable>'s
C<dclone ()> function will be used to create a copy of the data, the copy's root will be
dereferenced and the resulting list will be returned. Please see L<Storable>'s documentation for
limitations.

If there is no data, C<undef> (or an empty list) will be returned.

=cut

sub data {
	my ($self) = @_;
	return unless $self -> {'DATA'};
	if (wantarray) {
		require Storable;
		my $new = Storable::dclone ($self -> {'DATA'});
		return _hashref ($new) ? %$new : @$new;
	}
	return $self -> {'DATA'};
}

=head2 does_exist

	if ($h -> does_exist ($key)) { ... }

Returns a true value if the element specified by the key exists in the data structure. If it does
not exist, an undefined value will be returned. Instead of a key you may also specify an arrayref
containing the path to the element to check. Using a key is recommended, though. The key will be
normalized before it is used, see the C<normalize_key ()> method below.

=over

Actually, the value returned is a reference: if the element is itself a hashref or an arrayref,
that reference is returned, in all other cases, a reference to the element is returned (unless the
element does not exist, of course):

	# for a Data::SimplePath object with the following data:
	my $data = {
	  'a' => {
	    'a1' => 'scalar value for a1'
	  },
	  'b' => 'scalar value for b',
	};

	my $ref1 = $h -> does_exist ('a');
	my $ref2 = $h -> does_exist ('b');

In this example C<$ref2> will be set to a reference to C<'scalar value for b'>, changing this
value is possible:

	$$ref2 = 'another value for b';

C<$ref1> will contain the same reference as C<< $data -> {'a'} >>, so you can change the contents
of this (sub-) hashref, but not C<< $data -> {'a'} >> itself.

However, it is recommended to use the C<set ()> method to change the data structure, the behaviour
of C<does_exist ()> may change in future versions.

=back

=cut

sub does_exist {
	my ($self, $key) = @_;
	my @path = $self -> _path ($key);
	my $root = $self -> {'DATA'};
	while (defined (my $top = shift @path)) {
		return unless $root = $self -> _find_element ($root, $top);
	}
	return $root;
}

# _find_element ($root, $key) - find an element directly under $root
#       $root   the current hashref or arrayref
#       $key    the key (or array index) to look for
# if either $root -> {$key} or $root -> [$key] exists, a reference will be returned, as described
# in the pod for the does_exist () method above (ie. hashref and arrayref will be returned
# directly, else a ref to the scalar will be returned). if the key does not exist, undef will be
# returned. additionally, a warning will be printed (if enabled) if the $root is an arrayref and
# the $key is not a number. if $root is invalid, undef will be returned, too.

sub _find_element {
	my ($self, $root, $key) = @_;
	if (_hashref ($root)) {
		return unless exists $root -> {$key};
		return $root -> {$key} if _valid_root ($root -> {$key});
		return \($root -> {$key});
	}
	elsif (_arrayref ($root)) {
		return unless $key = _is_number ($key);
		return unless @{$root} > $key;
		return $root -> [$key] if _valid_root ($root -> [$key]);
		return \($root -> [$key]);
	}
	return;
}       # complaining about the returns: that's a paddling...

=head2 get

	my $value = get ($key);

Returns the value of the element specified by the key C<$key>. If the element does not exist an
undefined value will be returned (which may be the actual value of the element, so better use the
C<does_exist ()> method to check for existence if this is required). Instead of a key you may also
specify an arrayref containing the path to the element to check. Using a key is recommended,
though. The key will be normalized before it is used, see the C<normalize_key ()> method below.

If the element specified by the key (or path) is itself a hashref or an arrayref, this reference
will be returned if the method is called in scalar context. In list context, it will be copied
(using L<Storable>'s C<dclone ()> function) and the resulting (dereferenced) list will be returned.
(See L<Storable>'s documentation for limitations.)

Note that if called with an empty key (or an empty path) C<get ()> works like the C<data ()>
method, see above for details.

=cut

sub get {
	my ($self, $key) = @_;
	my $ref = $self -> does_exist ($key);
	return unless $ref;
	if (_valid_root ($ref)) {
		return $ref unless wantarray;
		require Storable;
		my $new = Storable::dclone ($ref);
		return _hashref ($new) ? %$new : @$new;
	}
	return $$ref;
}

=head2 set

	my $success = $h -> set ($key, $value);

Sets the element specified by C<$key> (may be an arrayref to the element's path, as usual) to the
value C<$value>. All required intermediate arrayrefs and/or hashrefs will be created:

	# starting with an empty arrayref as the data structure...

	$h -> set ('0/hash/0', 'value');

	# the data structure now contains:
	# [
	#   {                   # 0
	#     'hash' => [       # 0/hash
	#       'value'         # 0/hash/0
	#     ]
	#   }
	# ]

Note that in the example above the AUTO_ARRAY option is turned on. Another option that modifies the
behaviour of C<set ()> is REPLACE_LEAF. See the L<CONFIGURATION> section for a description of both
options and some example code.

The method will return true if the operation was successful, and false if an error occured. If
warnings are enabled (see the L<WARNINGS> section below), a warning will be printed in case of an
error.

If you specify an empty key or path, the value must be a hashref or arrayref and the object's data
will be set to this new data structure.

=cut

sub set { ## no critic (Subroutines::RequireFinalReturn) - we always return, believe it or not...

	my ($self, $key, $value) = @_;
	my @path = $self -> _path ($key);

	# path is empty, the root element must be changed. but only if the new value is either a
	# hashref or an arrayref:
	unless (@path) {
		return unless _valid_root ($value);
		$self -> {'DATA'} = $value;
		return 1;
	}

	# if root is not yet set, we need to create it before we start:
	unless ($self -> {'DATA'}) {
		$self -> {'DATA'} = ($self -> auto_array () and _number ($path [0])) ? [] : {};
	}

	# path is not empty, start iterating along the path, start at the root:
	my $root = $self -> {'DATA'};

	# don't forget the defined, the key may be 0. test cases would catch it, though...
	while (defined (my $top = shift @path)) {

		# if REPLACE_LEAF is disabled, root may be something else than a hashref or an
		# arrayref, print a warning and return in this case:
		unless (_valid_root ($root)) {
			_warn 'Trying to add an element beneath a scalar value';
			return;
		}

		# path is empty, $top was the last element -> set the value:
		unless (@path) {
			if (_arrayref ($root)) {
				return unless $top = _is_number ($top);
				$root -> [$top] = $value;
			}
			else {
				$root -> {$top} = $value;
			}
			return 1;
		}

		# path is not yet empty, search a child with the key $top in current $root:
		my $child = $self -> _find_element ($root, $top);

		# child may now be an arrayref or a hashref, in that case we can just use it as the
		# new root element (skip the if block below). if child is undef it does not yet
		# exist and we need to create it. in all other cases, ie. it exists but is not an
		# array- or a hashref, we override it with an array- or hashref if the REPLACE_LEAF
		# option is set.

		if (
			not $child or                           # child doesn't exist
			(
				$self -> replace_leaf () and    # REPLACE_LEAF is set
				not _valid_root ($child)        # and it's no hash- or arrayref
			)
		) {


			if (_arrayref ($root)) {

				# important: _find_element will also return false if the root is an
				# array and the key is no valid number, we need to check this:
				return unless $top = _number ($top);

				# note that the type of the child (ie. arrayref or hashref) depends
				# on the AUTO_ARRAY setting and the value of the next key:
	
				if ($self -> auto_array () and _number ($path [0])) {
					$child = $root -> [$top] = [];
				}
				else {
					$child = $root -> [$top] = {};
				}
	
			}
			else {

				if ($self -> auto_array () and _number ($path [0])) {
					$child = $root -> {$top} = [];
				}
				else {
					$child = $root -> {$top} = {};
				}

			}

		}

		# at this point $child can be used as the next root element, if it is no arrayref
		# or hashref we exit at the start of the next loop.

		$root = $child;

	}

}

=head2 remove

	my $removed = $h -> remove ($key);

Deletes the element specified by the key C<$key> (you may also specify an arrayref containing the
element's path in the data structure, usage of the key is recommended, though). The value of the
removed element will be returned. If the element does not exist, C<undef> will be returned. If the
key (or path) is empty, the root reference will be returned and the data structure will be removed
from the object.

This function basically works like Perl's C<delete ()> function for hashes and like the
C<splice ()> function for arrays (removing one element and not adding anything to the array, of
course).

=cut

sub remove { ## no critic (Subroutines::RequireFinalReturn)
	my ($self, $key) = @_;
	my @path = $self -> _path ($key);
	my $root = $self -> {'DATA'};
	unless (@path) {
		$self -> {'DATA'} = undef;
		return $root;
	}
	while (defined (my $top = shift @path)) {
		unless (@path) {
			if (_hashref ($root)) {
				return delete $root -> {$top};
			}
			elsif (_arrayref ($root)) {
				return unless $top = _is_number ($top);
				return splice (@$root, $top, 1) if @$root > $top;
			}
			return;
		}
		return unless $root = $self -> _find_element ($root, $top);
	}
}

=head2 path

	my @path = $h -> path ($key);

Returns an array containing the path elements for the specified key C<$key>, ie. the normalized key
(see C<normalize_key ()> below) split at the separator. Note that the resulting array may be empty.

=cut

sub path {
	my ($self, $key) = @_;
	$key = $self -> normalize_key ($key);
	my $s = $self -> {'SEPARATOR'};
	return split /\Q$s\E/, $key;
}

=head2 key

	my $key = $h -> key (@path);

Joins the array with the current separator string and returns the resulting string. The example
above can be written as:

	my $key = join $h -> separator (), @path;

Additionally, you may use this function with an arrayref, the following will return the same
string as the first example:

	my $key = $h -> key (\@path);

Note that - unlike the C<path ()> function - no further processing is done. For example, if the
array contains empty strings, the resulting string will contain multiple consecutive separators.
Use C<normalize_key ()> to remove these if required.

=cut

sub key {
	my ($self, @path) = @_;
	@path = @{$path [0]} if _arrayref ($path [0]);
	return join $self -> {'SEPARATOR'}, @path;
}

=head2 normalize_key

	$key = $h -> normalize_key ($key);

Removes separator string(s) at the beginning and end of the specified key and replaces all
occurrences of multiple consecutive separator strings in the key with a single one. For example,
the normalized version of C</some//path//> (with the separator C</>) would be C<some/path>.

=cut

sub normalize_key {
	my ($self, $key) = @_;
	my $s = $self -> {'SEPARATOR'};
	$key =~ s{^(?:\Q$s\E)*(.*?)(?:\Q$s\E)*$}{$1};
	$key =~ s{(?:\Q$s\E)+}{$s}g;
	return $key;
}

# _path ($key_or_path) - get path array
#        $key_or_path    if this is an array reference, the array will be returned, if not, it is
#                        assumed to be a scalar, split at the separator and the array is returned
# some minor improvement: if an arrayref is used, the array will be cleaned of all invalid
# elements, ie. only non-empty scalar values will be returned.

sub _path {
	my ($self, $key) = @_;
	if ($key and _arrayref ($key)) {
		my @new;
		foreach (@$key) {
			push @new, $_ if defined $_ and not ref $_ and $_ ne '';
		}
		return @new;
	}
	return $self -> path ($key);
}

=head1 WARNINGS

C<Data::SimplePath> can print warnings if something is wrong, eg. if you try to access an array
element with a non-numeric key or if you call the C<new ()> function with C<$initial> being not a
hashref or arrayref. If you enable warnings (ie. C<use warnings;>) these warnings will be enabled,
too. You may use the C<use warnings 'Data::SimplePath';> command to enable only the warnings of
this module, and if you want to enable warnings in general but disable C<Data::SimplePath>'s ones,
use C<no warnings 'Data::SimplePath';>.

=head1 AUTHOR

Stefan Goebel

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 - 2013 Stefan Goebel, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

1;
