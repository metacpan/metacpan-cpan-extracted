package Anarres::Mud::Driver::Efun::Core;

use strict;
use warnings;
use vars qw($VERSION @ISA);

# XXX Where should I be requiring these: before or after bootstrap?

use Anarres::Mud::Driver::Compiler::Type qw(:all);	# We do this twice?!

# Efuns need to be normal functions in a program symbol table but
# will not inherit or issue a warning if redefined.

# Note that we don't actually register all available efuns. We
# register only those which are visible as efuns to the LPC code.
# We may have more efuns, an individual efun typecheck_call method
# may decide to rebless the node into a different efun class.
# For example, map => map_array or map_mapping. In this way we
# can use the Perl object oriented dispatch mechanism to speed up
# many operations where a pure Perl conditional would be slower.

require DynaLoader;

$VERSION = 0.10;
@ISA = qw(DynaLoader);

bootstrap Anarres::Mud::Driver::Efun::Core;

use Anarres::Mud::Driver::Compiler::Type qw(:all);	# We do this twice?!
use Anarres::Mud::Driver::Program::Efun qw(register);
use Anarres::Mud::Driver::Program::Method;

{
	# As traditional, [ flags, return type, argtype .... ]
	my $pflags = M_PURE | M_NOMASK;	# This just lets me format nicely.
	my %efuns = (
		# Common stuff

		copy			=> [ 0,		T_UNKNOWN, T_UNKNOWN, ],

		# Object stuff

		this_object		=> [ 0,		T_OBJECT, ],
		previous_object	=> [ 0,		T_OBJECT, T_INTEGER, ],
	all_previous_objects=> [ 0,		T_OBJECT->array ],
		file_name		=> [ 0,		T_STRING, T_OBJECT, ],
		find_object		=> [ 0,		T_OBJECT, T_STRING, ],
		load_object		=> [ 0,		T_OBJECT, T_STRING, ],
		clone_object	=> [ 0,		T_OBJECT, T_STRING, ],
		destruct		=> [ 0,		T_INTEGER, T_OBJECT, ],
		children		=> [ 0,		T_OBJECT->array, T_STRING, ],
		objects			=> [ 0,		T_OBJECT->array, ],

		# String stuff

		implode		=> [ M_PURE, T_STRING, T_STRING->array, T_STRING ],
		explode		=> [ M_PURE, T_STRING->array, T_STRING, T_STRING ],
		lower_case		=> [ M_PURE, T_STRING, T_STRING, ],
		upper_case		=> [ M_PURE, T_STRING, T_STRING, ],
		strlen			=> [ M_PURE, T_INTEGER, T_STRING, ],
		replace_string	=> [ M_PURE, T_STRING, T_STRING, T_STRING, T_STRING, ],
		substr			=> [ M_PURE, T_STRING,
										T_STRING,
										T_INTEGER, T_INTEGER,	# off
										T_INTEGER, T_INTEGER, ],# end
		subchar			=> [ M_PURE, T_INTEGER,
										T_STRING,		# offset
										T_INTEGER, ],	# from end?
		capitalize		=> [ M_PURE, T_STRING, T_STRING, ],
		strsrch			=> [ M_PURE, T_INTEGER, T_STRING, T_STRING, ],
		regexp			=> [ M_PURE, T_INTEGER, T_STRING, T_STRING, ],

		# XXX varargs
		sprintf			=> [ M_PURE, T_STRING, T_STRING, T_ARRAY, ],
		sscanf			=> [ M_PURE, T_STRING, T_STRING, T_ARRAY, ],

		# Array stuff

		member_array	=> [ M_PURE, T_INTEGER, T_UNKNOWN, T_ARRAY, ],
		unique_array	=> [ M_PURE, T_ARRAY->array, T_ARRAY, T_CLOSURE],
			# XXX We can map mappings. :-(
		map				=> [ 0,		T_ARRAY, T_ARRAY, T_CLOSURE, ],
		filter			=> [ 0,		T_ARRAY, T_ARRAY, T_CLOSURE, ],
		allocate		=> [ 0,		T_ARRAY, T_INTEGER, T_UNKNOWN, ],

		# Mapping stuff

		keys			=> [ M_PURE,	T_STRING->array, T_MAPPING, ],
		values			=> [ M_PURE,	T_ARRAY, T_MAPPING, ],
		map_delete		=> [ 0,			T_UNKNOWN, T_MAPPING,T_STRING,],

		# Type stuff

		to_int			=> [ M_PURE,	T_INTEGER, T_STRING, ],
		to_string		=> [ M_PURE,	T_STRING, T_INTEGER, ],
		typeof			=> [ M_PURE,	T_STRING, T_UNKNOWN, ],
		sizeof			=> [ M_PURE,	T_INTEGER, T_UNKNOWN, ],

		intp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		stringp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		arrayp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		mapp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		functionp		=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		classp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		objectp			=> [ $pflags,	T_BOOL, T_UNKNOWN, ],
		clonep			=> [ M_PURE,	T_BOOL, T_UNKNOWN, ],
		undefinedp		=> [ M_PURE,	T_BOOL, T_UNKNOWN, ],

		# Closure stuff

		# XXX varargs
		evaluate		=> [ 0,		T_UNKNOWN, T_CLOSURE, T_ARRAY, ],

		# Reflection

		function_exists	=> [ 0,		T_OBJECT, T_STRING, T_INTEGER, ],
		functions		=> [ 0,		T_OBJECT, T_INTEGER, ],
		variables		=> [ 0,		T_OBJECT, T_INTEGER, ],
		inherits		=> [ M_PURE,	T_INTEGER, T_STRING, T_OBJECT, ],
		call_stack		=> [ 0,		T_STRING->array, T_INTEGER, ],

		# File stuff

		file_size		=> [ 0,		T_INTEGER, T_STRING, ],
		read_file		=> [ 0,		T_STRING, T_STRING, ],
		write_file		=> [ 0,		T_INTEGER, T_STRING, T_STRING, ],

		# System stuff

		time			=> [ 0,		T_INTEGER, ],

		debug_message	=> [ 0,		T_STRING, T_STRING, ],
		error			=> [ 0,		T_INTEGER, T_STRING, ],
		catch			=> [ 0,		T_STRING, T_UNKNOWN, ],
		shutdown		=> [ 0,		T_INTEGER, ],

		trace			=> [ 0,		T_INTEGER, T_INTEGER, ],
			);

	# We call this as an exported function since ISA isn't yet set up.
	foreach (keys %efuns) {
		register(__PACKAGE__ . "::" . $_, @{ $efuns{$_} });
	}
}

{
	package Anarres::Mud::Driver::Efun::Core::time;
	sub generate_call { "time()" }
}

{
	package Anarres::Mud::Driver::Efun::Core::debug_message;
	sub generate_call { "print STDERR $_[1], '\\n'" }
}

{
	package Anarres::Mud::Driver::Efun::Core::previous_object;
	sub invoke { undef }
}

{
	package Anarres::Mud::Driver::Efun::Core::file_name;
	sub generate_call {
		"Anarres::Mud::Driver::Program::package_to_path(ref($_[1]))"
	}
}

{
	package Anarres::Mud::Driver::Efun::Core::find_object;
	# sub generate_call { "undef" }
	sub invoke { undef }
}

{
	package Anarres::Mud::Driver::Efun::Core::to_string;
	# XXX This only works for CONSTANT integers, of course.
	# sub generate_call { '"' . $_[1] . '"' }
	# This works for any integer which is about to be evaluated as
	# a string by Perl. 6 . 7 == "67";
	sub generate_call { ('' . $_[1]) }
}

{
	package Anarres::Mud::Driver::Efun::Core::strlen;
	sub generate_call { "length($_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::error;
	sub generate_call { "die('LPC: ' . $_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::catch;
	sub generate_call { "do { eval { $_[1] }; $@; }"; }
}

{
	package Anarres::Mud::Driver::Efun::Core::implode;
	sub generate_call { "join($_[2], \@{ $_[1] })" }
}

{
	package Anarres::Mud::Driver::Efun::Core::explode;
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::replace_string;
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::intp;
	# sub generate_call { "(defined($_[1]) && !ref($_[1]))" }
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::stringp;
	# sub generate_call { "(defined($_[1]) && !ref($_[1]))" }
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::arrayp;
	sub generate_call { "ref($_[1]) eq 'ARRAY'" }
}

{
	package Anarres::Mud::Driver::Efun::Core::mapp;
	sub generate_call { "ref($_[1]) eq 'HASH'" }
}

{
	package Anarres::Mud::Driver::Efun::Core::objectp;
	sub generate_call { "ref($_[1]) =~ /::/" }	# XXX
}

{
	package Anarres::Mud::Driver::Efun::Core::clonep;
	sub generate_call { "ref($_[1]) =~ /::/" }	# XXX
}

{
	package Anarres::Mud::Driver::Efun::Core::undefinedp;
	sub generate_call { "defined($_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::keys;
	sub generate_call { "keys(\%{$_[1]})" }
}

{
	package Anarres::Mud::Driver::Efun::Core::values;
	sub generate_call { "values(\%{$_[1]})" }
}

{
	package Anarres::Mud::Driver::Efun::Core::map_delete;
	sub generate_call { "delete(\${$_[1]}->{$_[2]})" }
}

{
	package Anarres::Mud::Driver::Efun::Core::regexp;
	sub generate_call { "XXX($_[1] =~ m/$_[2]/)" }
}

{
	package Anarres::Mud::Driver::Efun::Core::clone_object;
	sub generate_call { "$_[1]\->new()" }
}

{
	package Anarres::Mud::Driver::Efun::Core::this_object;
	sub generate_call { '$self' }
}

{
	package Anarres::Mud::Driver::Efun::Core::strsrch;
	sub generate_call { "index($_[1], $_[2])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::lower_case;
	sub generate_call { "lc($_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::upper_case;
	sub generate_call { "uc($_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::substr;
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::subchar;
	# invoke is an XSUB
}

{
	package Anarres::Mud::Driver::Efun::Core::capitalize;
	sub generate_call { "ucfirst($_[1])" }
}

{
	package Anarres::Mud::Driver::Efun::Core::allocate;
	sub generate_call {
		my $val = defined $_[2] ? $_[2] : 'undef';
		return "[ ($val) x $_[1] ]"
	}
}

{
	package Anarres::Mud::Driver::Efun::Core::to_int;
	sub generate_call { "(0 + ($_[1]))" }
}

{
	package Anarres::Mud::Driver::Efun::Core::copy;
	sub invoke { $_[1] }	# XXX dclone - but not for objects.
}

{
	package Anarres::Mud::Driver::Efun::Core::inherits;
	sub generate_call { "($_[2])->isa(XXX_to_package($_[1]))" }
}

{
	package Anarres::Mud::Driver::Efun::Core::sizeof;
	sub generate_call {
		# XXX Arse - use typechecking info!
		# XXX Deal with ints
		'do { my $__a = ' . $_[1] . '; my $__r = ref($__a); ' .
				# ($#$__a + 1) ?
				'$__r eq "ARRAY" ? scalar(@{$__a}) : ' .
				'$__r eq "HASH" ? scalar(keys %{$__a}) : ' .
				'$__r eq "" ? length($__a) : ' .
				'die "Cannot take sizeof($__r)"; }';
	}
}

{
	package Anarres::Mud::Driver::Efun::Core::file_size;
	use Fcntl qw(:mode);
	sub invoke {
		my @stat = stat($_[1]);
		return -1 unless @stat;
		return -2 if ($stat[2] & S_IFDIR);
		return $stat[2];
	}
}

{
	package Anarres::Mud::Driver::Efun::Core::map;
	use Anarres::Mud::Driver::Compiler::Type qw(:all);
	sub typecheck_call {
		my ($self, $program, $values, @rest) = @_;
		my $val = $values->[1];
		my $func = $values->[2];

		$func = $func->infer(T_CLOSURE);
		unless ($func) {
			$program->error("Argument 2 to map must be a closure.");
		}

		if (my $arr = $val->infer(T_ARRAY)) {
			# $values->[0] = "(pointer to map_array)";
			$values->[1] = $arr;
			$arr->typecheck($program, undef, @rest) unless $arr == $val;
			return $arr->type;
		}
		elsif (my $map = $val->infer(T_MAPPING)) {
			# $values->[0] = "(pointer to map_mapping)";
			$values->[1] = $map;
			$map->typecheck($program, undef, @rest) unless $map == $val;
			return $map->type;
		}
		elsif (my $str = $val->infer(T_STRING)) {
			$values->[1] = $str;
			$str->typecheck($program, undef, @rest) unless $str == $val;
			return $str->type;
		}
		else {
			$program->error("Argument 1 to map must be a mapping " .
							"or an array.");
			return undef;
		}
	}
}

1;
