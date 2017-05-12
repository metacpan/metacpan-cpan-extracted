package Anarres::Mud::Driver::Compiler::Type;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS
				%TYPENAMES %TYPECODES);
use Exporter;
use Carp;

BEGIN {
	$VERSION = 0.10;
	@ISA = qw(DynaLoader Exporter);
	@EXPORT_OK = qw(T_CLASS F_CONST F_LVALUE);	# .xs adds more to this
	%EXPORT_TAGS = (
		all	=> \@EXPORT_OK,
			);
	require DynaLoader;
	bootstrap Anarres::Mud::Driver::Compiler::Type;
}

%TYPENAMES = (
	${T_VOID()}		=> "void",
	${T_NIL()}		=> "nil",
	${T_UNKNOWN()}	=> "unknown",
	${T_BOOL()}		=> "boolean",
	${T_CLOSURE()}	=> "function",
	${T_INTEGER()}	=> "integer",
	${T_OBJECT()}	=> "object",
	${T_STRING()}	=> "string",
	${T_FAILED()}	=> "ERROR",
		);

%TYPECODES = (
	${T_VOID()}		=> "void",
	${T_NIL()}		=> "nil",
	${T_UNKNOWN()}	=> "mixed",
	${T_BOOL()}		=> "bool",
	${T_CLOSURE()}	=> "function",
	${T_INTEGER()}	=> "int",
	${T_OBJECT()}	=> "object",
	${T_STRING()}	=> "string",
	${T_FAILED()}	=> "ERROR",
		);

sub T_CLASS {
	my $class = __PACKAGE__;
	my $name = shift;
	# DEBUG
	croak "Error: Class must be named." if ref($name);
	my $self = T_M_CLASS_BEGIN . $name . T_M_CLASS_MID .
					join('', map { $$_ } @_) . T_M_CLASS_END;
	return $class->new($self);
}

sub F_CONST		()	{ 1 }
sub F_LVALUE	()	{ 2 }

sub array {
	my ($self, $num) = @_;
	$num = 1 unless defined $num;
	my $out = "*" x $num . $$self;
	return $self->new($out);
}

sub mapping {
	my ($self, $num) = @_;
	$num = 1 unless defined $num;
	my $out = "#" x $num . $$self;
	return $self->new($out);
}

sub dereference {
	my ($self) = @_;
	my $new;
	if ($$self =~ /^[*#]/) {
		$new = substr($$self, 1)
	}
	elsif ($$self eq ${ &T_STRING }) {	# XXX Remove this case?
		warn "Dereferencing string!";
		$new = T_INTEGER;
	}
	else {
		die "Cannot dereference nonreference type $$self";
	}
	return $self->new($new);
}

sub is_array {
	return ${$_[0]} =~ /^\*/;
}

sub is_mapping {
	return ${$_[0]} =~ /^#/;
}

sub is_class {
	return ${$_[0]} =~ /^{/;
}

sub class {
	return undef unless ${$_[0]} =~ /^{([^:]*):/;
	return $1;
}

sub dump {
	return ${$_[0]};
}

sub equals {
	# Since we have unique types, the references should compare
	# equal just as the referenced values do.
	warn "Problem with type uniqueness"
		if (($_[0] == $_[1]) != (${$_[0]} eq ${$_[1]}));
	return ${$_[0]} eq ${$_[1]};
}

# Called from Node->promote in Check.pm
sub promote {
	my ($self, $node, $type) = @_;
	# We might be promoted to a more specific type.
	# We might be promoted to a less specific type.
	# This routine must return a typechecked object.
	if ($$self ne $$type) {
#		print "Promoting " . sprintf("%-20.20s", $node->nodetype) .
#						" from $$self to $$type\n";
	}
	return $node;	# XXX do something here!
}

sub name {
	my ($self) = shift;
	my $code = $$self;
	my $out = "";
	while (length $code) {
		if ($code =~ s/^#//) {
			$out .= "mapping of ";
		}
		elsif ($code =~ s/^\*//) {
			$out .= "pointer to ";
		}
		elsif ($code =~ m/^z/) {
			$out .= "constant ";
		}
		elsif ($code =~ m/^=/) {
			$out .= "lvalue ";
		}
		elsif ($code =~ m/^{([^:]+):/) {
			return $out . "class $1";
		}
		elsif ($TYPENAMES{$code}) {
			return $out . $TYPENAMES{$code};
		}
		else {
			die "Unknown type code $code!";
		}
	}
	die "Invalid type code $$self !";
}

# Currently only called from Method::proto
sub deparse {
	my ($self) = shift;
	my $code = $$self;
	my $out = "";
	while (length $code) {
		if ($code =~ s/^#//) {
			$out .= "#";
		}
		elsif ($code =~ s/^\*//) {
			$out .= "*";
		}
		elsif ($code =~ m/^z/) {
			# $out .= "const ";
		}
		elsif ($code =~ m/^=/) {
			# $out .= "lvalue ";
		}
		elsif ($code =~ m/^{([^:]+):/) {
			return "class $1 $out";
		}
		elsif ($TYPECODES{$code}) {
			return "$TYPECODES{$code} $out" if length $out;
			return $TYPECODES{$code};
		}
		else {
			die "Unknown type code $code!";
		}
	}
	die "Invalid type code $$self !";
}

1;
