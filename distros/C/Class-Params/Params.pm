package Class::Params;

use base qw(Exporter);
use strict;
use warnings;

use Error::Pure qw(err);
use Readonly;
use Scalar::Util qw(blessed);

# Export.
Readonly::Array our @EXPORT_OK => qw(params);

our $VERSION = 0.05;

# Params processing.
sub params {
	my ($self, $def_hr, $params_ar) = @_;

	# Process params.
	my @processed = ();
        while (@{$params_ar}) {
                my $key = shift @{$params_ar};
                my $val = shift @{$params_ar};

		# Check key.
		if (! $def_hr->{$key}->[0]) {
	                err "Unknown parameter '$key'.";
		}

		# Check type.
		if (! _check_type($val, $def_hr->{$key}->[2])) {
			err "Bad parameter '$key' type.";
		}

		# Check class.
		if (! _check_class($val, $def_hr->{$key}->[1])) {
			err "Bad parameter '$key' class.";
		}

		# Add value to class.
		$self->{$def_hr->{$key}->[0]} = $val;

		# Processed keys.
		push @processed, $key;
        }

	# Check requirement.
	foreach my $req (map { $def_hr->{$_}->[3] ? $_ : () } keys %{$def_hr}) {
		if (! grep { $req eq $_ } @processed) {
			err "Parameter '$req' is required.";
		}
	}

	return;
}

# Check type.
# Possible types: HASH, ARRAY, SCALAR.
sub _check_type {
	my ($value, $type) = @_;

	# Multiple types.
	if (ref $type eq 'ARRAY') {
		foreach (@{$type}) {
			if (_check_type_one($value, $_)) {
				return 1;
			}
		}
		return 0;

	# One type.
	} else {
		return _check_type_one($value, $type);
	}
}

# Check one type.
sub _check_type_one {
	my ($value, $type) = @_;
	if (ref $value eq $type 
		|| ref \$value eq $type) {

		return 1;
	} else {
		return 0;
	}
}

# Check class.
# Class: CLASS/undef.
sub _check_class {
	my ($value, $class_name) = @_;
	if ($class_name) {

		# Array.
		if (ref $value eq 'ARRAY') {
			foreach (@{$value}) {
				if (! _check_class($_, $class_name)) {
					return 0;
				}
			}
			return 1;
		# One.
		} else {
			return _check_class_one($value, $class_name);
		}
	} else {
		return 1;
	}
}

# Check ref to class.
sub _check_class_one {
	my ($class, $class_name) = @_;
	if (! blessed($class) || ! $class->isa($class_name)) {
		return 0;
	} else {
		return 1;
	}
}

1;

=pod

=encoding utf8

=head1 NAME

 Class::Params - Parameter utils for constructor.

=head1 SYNOPSIS

 use Class::Params qw(params);
 params($self, $def_hr, $params_ar);

=head1 DEFINITION FORMAT

 There is hash with parameters.
 internal_name => [real_name, class, possible_types, requirement]

 Example:
 'par1' => ['_par1', undef, 'SCALAR', 1],
 'par2' => ['_par2', undef, ['SCALAR', 'HASH'], 0],
 'par3' => ['_par3', 'Class', ['SCALAR', 'Class'], 0],

=head1 SUBROUTINES

=over 8

=item C<params($self, $def_hr, $params_ar)>

 Check for structure over definition and save input data to $self.
 Parameters:
 $self - Structure, for data save.
 $def_hr - Definition hash ref.
 $params_ar - Reference to array of key-value pairs.
 Returns undef.

=back

=head1 ERRORS

 params():
         Bad parameter '%s' type.
         Parameter '%s' is required.
         Unknown parameter '%s'.

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Class::Params qw(params);

 # Definition.
 my $self = {};
 my $def_hr = {
         'par' => ['_par', undef, 'SCALAR', 1],
 };

 # Check.
 # output_structure, definition, array of pairs (key, value).
 params($self, $def_hr, ['bad_par', 1]);

 # Output:
 # Unknown parameter 'bad_par'.

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Class::Params qw(params);
 use Data::Printer;

 # Definition.
 my $self = {};
 my $def_hr = {
         'par' => ['_par', undef, 'SCALAR', 1],
 };

 # Check.
 # output_structure, definition, array of pairs (key, value).
 params($self, $def_hr, ['par', 1]);

 # Dump $self.
 p $self;

 # Output:
 # \ {
 #     _par   1
 # }

=head1 EXAMPLE3

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Class::Params qw(params);

 # Definition.
 my $self = {};
 my $def_hr = {
         'par' => ['_par', 'Moo', ['ARRAY', 'Moo'], 0],
 };

 # Fake class.
 my $moo = bless {}, 'Moo';

 # Check bad 'par' parameter which has bad 'bar' scalar.
 params($self, $def_hr, ['par', [$moo, 'bar']]);

 # Output like:
 # Bad parameter 'par' class.

=head1 EXAMPLE4

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Class::Params qw(params);
 use Data::Printer;

 # Definition.
 my $self = {};
 my $def_hr = {
         'par' => ['_par', 'Moo', ['ARRAY', 'Moo'], 0],
 };

 # Fake class.
 my $moo = bless {}, 'Moo';

 # Check right 'par' parameter which has array of 'Moo' objects.
 params($self, $def_hr, ['par', [$moo, $moo]]);

 # Dump $self.
 p $self;

 # Output like:
 # \ {
 #     _par   [
 #         [0] Moo  {
 #             public methods (0)
 #             private methods (0)
 #             internals: {}
 #         },
 #         [1] var{_par}[0]
 #     ]
 # }

=head1 DEPENDENCIES

L<Error::Pure>,
L<Exporter>,
L<Readonly>,
L<Scalar::Util>.

=head1 REPOSITORY

L<https://github.com/tupinek/Class-Params>

=head1 AUTHOR

Michal Josef Špaček L<skim@cpan.org>

=head1 LICENSE AND COPYRIGHT

 © Michal Josef Špaček 2011-2018
 BSD 2-Clause License

=head1 VERSION

0.05

=cut
