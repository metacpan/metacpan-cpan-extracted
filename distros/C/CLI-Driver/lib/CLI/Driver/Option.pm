package CLI::Driver::Option;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';

use Getopt::Long 'GetOptionsFromArray';
Getopt::Long::Configure('no_ignore_case');
Getopt::Long::Configure('pass_through');

with 'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has class => (
	is  => 'rw',
	isa => 'Str',
);

has cli_arg => (
	is  => 'rw',
	isa => 'Str'
);

has method_arg => (
	is  => 'rw',
	isa => 'Str|Undef'
);

has required => (
	is  => 'rw',
	isa => 'Bool'
);

has hard => (
	is  => 'rw',
	isa => 'Bool',
);

has flag => (
	is  => 'rw',
	isa => 'Bool',
);

has is_array => (
	is  => 'rw',
	isa => 'Bool',
);

has value => (
    is => 'rw',
    isa => 'Any',
);

has 'use_argv_map' => ( is => 'rw', isa => 'Bool' );

###############################################

method get_signature {

	my %sig;

	my $val = $self->_get_val;
	$self->value($val);
	if ( defined $val ) {
		$sig{ $self->method_arg } = $val;
	}

	return %sig;
}

method is_required {

	if ( $self->required ) {
		return 1;
	}

	return 0;
}

method is_flag {

	if ( $self->flag ) {
		return 1;
	}

	return 0;
}

method is_optional {

	if ( !$self->required ) {
		return 1;
	}

	return 0;
}

method is_hard {

	if ( $self->hard ) {
		return 1;
	}

	return 0;
}

method is_soft {

	if ( !$self->hard ) {
		return 1;
	}

	return 0;
}

method _get_val {

	my $arg = $self->cli_arg;
	my $val;

	if ( $self->is_flag ) {

		# - just a cli switch
		# - never required from cmdline

		if ( $self->use_argv_map ) {
			 $val = $ARGV{$self->method_arg};
			 delete $ARGV{$self->method_arg};
			 return $val;
		}
		else {
			my $success = GetOptionsFromArray( \@ARGV, "$arg" => \$val, );
			if ($success) {
				return $val ? 1 : 0;
			}
		}

		confess "something went sideways?";
	}
	else {

		if ( $self->use_argv_map ) {
			if ( $ARGV{$self->method_arg} ) {
				$val = $ARGV{$self->method_arg};
				delete $ARGV{$self->method_arg};
				return $val;
			}
		}
		else {
			# get "-arg <val>" from cmdline if exists
			my $arg_type = "s";
			$arg_type.= '@' if $self->is_array;

			my $success =
			  GetOptionsFromArray( \@ARGV, "$arg=$arg_type" => \$val, );
            if ($success) {
                return $val;
            }

			confess "something went sideways?" if !$success;
		}

		# we didn't find it in @ARGV
		if ( $self->required ) {
			confess "failed to get arg from argv: $arg";
		}
	}

	return;
}

1;
