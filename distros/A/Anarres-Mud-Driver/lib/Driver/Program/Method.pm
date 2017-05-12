package Anarres::Mud::Driver::Program::Method;

use strict;
use vars qw(@ISA @EXPORT);
use Data::Dumper;
use Carp qw(cluck);
use Anarres::Mud::Driver::Program::Variable;
use Anarres::Mud::Driver::Compiler::Type qw(:all);

@ISA = qw(Anarres::Mud::Driver::Program::Variable);
*EXPORT = \@Anarres::Mud::Driver::Program::Variable::EXPORT;

sub args { return $_[0]->{Args}; }

# Code is added later in the parser (was?)
sub code {
	my ($self, $code) = @_;
	# cluck "Add code $code to method $self->{Name}\n" if $code;
	if (defined $code) {
		$self->{Code} = $code;
		# print Dumper($code);
	}
	return $self->{Code};
}

sub check {
	my ($self, $program, @rest) = @_;
	# print "Typechecking method " . $self->name . " (top level)\n";
	# print $self->dump, "\n";

	# Start adding locals, etc, etc.

	$program->reset_labels;
	$program->save_locals;
	foreach (@{ $self->args }) {
		$program->local($_->name, $_);
	}
	my $code = $self->code;
	if ($code) {
		$code->check($program, @rest);
	}
	else {
		$program->error("No code in method " . $self->name);
	}
	$program->restore_locals;
	# print $self->dump, "\n";
}

sub dump {
	my $self = shift;
	my $indent = shift;
	$indent++;

	my $sep = "\n" . ("\t" x $indent);

	# XXX No types
	my $out = "([" . $self->type->dump(@_) . "] method " . $self->name;
	# my $out = "(method " . $self->name;
	my $args = join("", map { " " . $_->dump($indent, @_) } @{$self->args});
	my $code = ! $self->code				? "(nocode)"
			: ref($self->code) !~ /::/		? ref($self->code)
			: $self->code->dump($indent, @_)
		;

	$out  = $out .
		$sep . "(args" . $args . ")" .
		$sep . $code . ")";

	return $out;
}

	# This should generate Perl code for the method
sub generate {
	my $self = shift;
	my $indent = shift;
	$indent++;

	return "\n\n# No code in " . $self->name . "\n\n\n"
					unless $self->code;

	my $proto = '$' . ('$' x @{$self->args});
	my $rtproto = join("", map { ${ $_->type } } @{ $self->args });
	my $head =
		"# method " . $self->name . " proto o" . $rtproto . "\n" .
		"sub _M_" . $self->name . " ($proto) {\n";
	# XXX Generate warning if no return from nonvoid function.
	my $tail = "\n\treturn undef;\n}\n";

	my @args = map { ', $_L_' . $_->name } @{ $self->args };
	my $args = "\t" . 'my ($self' . join('', @args) . ') = @_;' .
					"\n\t";

	return $head . $args . $self->code->generate($indent, @_) . $tail;
}

	# This has a weird prototype for a typecheck method.
sub typecheck_call {
	my ($self, $program, $values, @rest) = @_;

	if ($self->flags & M_UNKNOWN) {
		return $self->type;
	}

	# print "Typecheck call: " . Dumper($values) . "\n";
	# print "Typecheck call: " . Dumper($self) . "\n";

	my @values = @$values;
	my $method = shift @values;

	my @args = @{ $self->args };

	if (@values < @args) {
		$program->error("Too few arguments (" . scalar(@values) .
						") to function " .  $method->name .
						", try " .  scalar(@args));
		return $self->type;
	}
	elsif (@values > @args) {
		$program->error("Too many arguments (" . scalar(@values) .
						") to function " . $method->name .
						", try " .  scalar(@args));
		return $self->type;
	}

	my $i = 1;
	foreach my $decl (@args) {
		my $val = $values->[$i];
		# print "Matching arg " . $val->dump . " against " . $decl->dump . "\n";
		my $arg = $val->promote($decl->type);
		if (! $arg) {
			$program->error("Argument $i to " . $self->name .
							" is type " . $val->type->name .
							" not type " . $decl->type->name);
		}
		elsif ($arg != $val) {
			$arg->check($program, undef, @rest);
			$values->[$i] = $arg;
		}
		# print "OK\n";
	}
	continue {
		$i++;
	}

#		print "Funcall " . $method->name . " checked and becomes type "
#						. ${$method->type} . "\n" if 0;
	return $self->type;
}

sub generate_call {
	my ($self, @args) = @_;
	return '$self->_M_' . $self->name . "(" . join(", ", @args) .")";
}

sub proto {
	my ($self) = @_;
	return $self->type->deparse . " " . $self->name . "(...)";
}

1;
