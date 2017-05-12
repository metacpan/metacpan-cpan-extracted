package Data::Typed::Expression::Env;

use Carp 'croak';

use warnings;
use strict;

=head1 NAME

Data::Typed::Expression::Env - Evalutation environment for typed expressions

=head1 VERSION

Version 0.005

=cut

our $VERSION = '0.005';

=head1 SYNOPSIS

See L<Data::Typed::Expression>.

=head1 DESCRIPTION

An environment is an object describing known types and variables to be used by
expressions of type L<Data::Typed::Expression>. Types can be marked as simple
ones or defined as compounds (structures) with fields of other types.

=head1 METHODS

=head2 new

Creates a new enviroment in which expressions can be evaluated.

Arguments are two hashrefs, the first one containing types declarations, the
second one containing variables definitions.

Each type declaration is a single hash entry, with type name being the key and
type definition being the value.

Type definition is either C<undef>, when there is nothing "internal" about the
type or a hashref, for compound types. Each entry in compound type definition
is a mapping from a compound element name to its type name.

For example, if we define the C<car> type as having "color" property, which is
represented as RGB triple, "price" as double and "name" as a string, the
corresponding type definitions can look like:

  {
    car => {
      color => 'color',
      price => 'double',
      name => 'string'
    },
    color => {
      r => 'double',
      g => 'double',
      b => 'double'
    },
    double => undef,
    string => undef
  }

Variables definition is a mapping from variable name to its type name.

=cut

sub new {
	my ($class, $types, $vars) = @_;
	$vars = { } unless defined $vars;
	$types = { } unless defined $types;
	my $self = {
		t => $types,
		v => $vars
	};
	
	return bless $self, $class;
}

=head2 new_with

Creates a new environment based on the current one.

The created environment contains all the types and variables from the current
environment, as well as the new types and variables passed as the arguments,
in the same way as to L<new()|/new> method.

If types or variables which are defined in the current object and also passed
as parameters, definitions given in parameters override the current ones in the
created object.

=cut

sub new_with {
	my ($self, $types, $vars) = @_;
	my $t = {
		%{$self->{t}},
		%$types
	};
	my $v = {
		%{$self->{v}},
		%$vars                        
	};
	return (ref $self)->new($t, $v);
}

=head2 get_type_def

Returns type definition for a given type name, as passed to L<new()|/new>.

=cut

sub get_type_def {
	return $_[0]->{t}{$_[1]};
}

=head2 get_var_type

Returns variable type name, as passed to L<new()|/new>.

=cut

sub get_var_type {
	return $_[0]->{v}{$_[1]};
}

=head2 validate

Checks if the given expression represents a valid one, in the context of the
current environent.

For expression to be valid, all used variables, types and components must exist
in the environment, and appropriate operators arguments must be of special and
coherent types (e.g. C<int> for array indexing or C<int> or C<double> for
mathematical operations).

Returns name of the type of passed expression.

=cut

sub validate {
	return $_[0]->_validate_ast($_[1]->{ast});
}

sub _check_const_type {
	if ($_[0] =~ /^\d+(\.\d+)?$/) {
		return (defined $2) ? 'double' : 'int';
	} 
	
	undef;
}

sub _validate_ast {
	my ($self, $ast) = @_;
	return '' unless defined $ast;
	
	my ($op, $arg) = (ref $ast) ?
		($ast->{op}, $ast->{arg}) :
		('V', $ast);

	if ($op eq 'I') {
		return 'int';
	} elsif ($op eq 'D') {
		return 'double';
	} elsif ($op eq 'V') {
		if (ref $arg) {
			$arg = $arg->[0];
		}
		croak "Undefined var: $arg" unless exists $self->{v}{$arg};
		return $self->{v}{$arg};
	} elsif ($op eq '.') {
		if (ref $arg->[1] && $arg->[1]{op} ne 'V') {
			croak "Unexpected element type ($arg->[1]{op}) on right side of '.'";
		}
		my $subt = $self->_validate_ast($arg->[0]);
		my $e = $arg->[1]{arg};
		croak "Tried to get elements of simple type ($subt)"
			unless ref $self->{t}{$subt};
		croak "Type ($subt) has no element named $e"
			unless exists $self->{t}{$subt}{$e};
		return $self->{t}{$subt}{$e};
	} elsif ($op =~ m{[-+*/]}) {
		my $t = 'int';
		for (@$arg) {
			my $tt = $self->_validate_ast($_);
			if ($tt eq 'int') {
				# fine
			} elsif ($tt eq 'double') {
				$t = 'double';
			} else {
				croak "Arithmetic operation ($op) on non-numeric type ($t)";
			}
		}
		return $t;
	} elsif ($op eq '[]') {
		my ($arr, @ind) = @$arg;
		my $subt = $self->_validate_ast($arr);
		for (@ind) {
			my $indt = $self->_validate_ast($_);
			croak "Can't index ($subt) with non-int ($indt) type"
				if $indt ne 'int';
		}
		my $indbr = '[]' x int(@ind);
		$subt =~ s/\Q$indbr\E$// or
				croak "Tried to index non-array type ($subt) with ($indbr)";
		return $subt; 
	}
}

1;

