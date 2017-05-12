package Anarres::Mud::Driver::Compiler::Dump;

use strict;
use Carp qw(:DEFAULT cluck);
use Exporter;
use Data::Dumper;
use Anarres::Mud::Driver::Compiler::Type qw(:all);
use Anarres::Mud::Driver::Compiler::Node qw(@NODETYPES);

push(@Anarres::Mud::Driver::Compiler::Node::ISA, __PACKAGE__);

sub dumptype {
	my $self = shift;
	return "" unless $self->type;
	my $flags =
			$self->flags & F_CONST  ? "z" : "" .
			$self->flags & F_LVALUE ? "=" : "" ;
	return "[" . $flags . $self->type->dump(@_) . "] ";
}

sub dump {
	my $self = shift;
	$self->dumpblock( [ $self->values ], @_ );
}

sub dumpblock {
	my ($self, $vals, $indent, @rest) = @_;
	$indent++;

	my $op = $self->opcode;

	my @fields = map {
			  ! $_				? "<undef>"
			: ! ref($_)			? "q[$_]"
			: ref($_) !~ /::/	? "[" . ref($_) . "]"
			: $_->dump($indent, @rest)
					} @$vals;
	my $sep = "\n" . ("\t" x $indent);
	return join($sep,
			"(" . $self->dumptype($indent, @rest) . lc $op,
			@fields
				) . ")";
	# return join($sep, "([V] block", @locals, @stmts) . ")";
}

{
	package Anarres::Mud::Driver::Compiler::Node::String;
	use String::Escape qw(quote printable);
	sub dump { return quote(printable($_[0]->value(0))) }
}

{
	package Anarres::Mud::Driver::Compiler::Node::Integer;
	sub dump { return $_[0]->value(0) }
}

{
	package Anarres::Mud::Driver::Compiler::Node::Variable;
	sub dump {
		my $self = shift;
		# my $var = $self->value(0);
		# XXX Typechecking should replace with an object?
		# return ref($var) ? $var->dump : $var;
		return "(" . $self->dumptype . "variable "
						. $self->value(0) . ")";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarLocal;
	sub dump {
		"(" . $_[0]->dumptype . "varlocal " . $_[0]->value(0) . ")";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarGlobal;
	sub dump {
		"(" . $_[0]->dumptype . "varglobal " . $_[0]->value(0) . ")";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::VarStatic;
	sub dump {
		"(" . $_[0]->dumptype . "varstatic " . $_[0]->value(0) . ")";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Parameter;
	sub dump {
		my $self = shift;
		return "(" . $self->dumptype . "parameter "
						. $self->value(0) . ")";
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Funcall;
	sub dump {
		my $self = shift;
		my @args = $self->values;
		my $method = shift @args;
		@args = map { " " . $_->dump(@_) } @args;
		return "(" . $self->dumptype(@_) . "funcall '" .
						$method->name . "'" . join("", @args) . ")"
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::CallOther;
	sub dump {
		my $self = shift;
		my @values = $self->values;
		my $exp = shift @values;
		my $name = shift @values;
		my $type = $self->dumptype;
		@values = map { ref($_) =~ /::/ ? " " . $_->dump(@_) : $_ }
						@values;
		return "(" . $type . "callother " . $exp->dump(@_) . " -> '" .
						$name . "'" . join("", @values) . ")"
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::Block;
	sub dump {
		my $self = shift;
		return $self->dumpblock(
				[ @{ $self->value(0) },	# locals
				  @{ $self->value(1) },	# statements
				], @_ );
	}
}

{
	package Anarres::Mud::Driver::Compiler::Node::StmtIf;
	sub dump {
		my $self = shift;
		my ($cond, $if, $else) = $self->values;
		my $vals = defined $else
				? [ $cond, $if, $else, ]
				: [ $cond, $if, ];
		return $self->dumpblock($vals, @_);
	}
}

if (0) {
	my $package = __PACKAGE__;
	no strict qw(refs);
	my @missing;
	foreach (@NODETYPES) {
		# next if defined $OPCODETABLE{$_};	# XXX No dump table
		next if defined &{ "$package\::$_\::dump" };
		push(@missing, $_);
	}
	print "No dump in @missing\n" if @missing;
}

1;
