package Anarres::Mud::Driver::Program;

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS %PROGS);
use Exporter;
use Carp qw(:DEFAULT cluck);
use Data::Dumper;
use File::Basename;
use String::Escape qw(quote printable);
use Anarres::Mud::Driver::Compiler::Type qw(:all);
use Anarres::Mud::Driver::Program::Variable;
use Anarres::Mud::Driver::Program::Method;
use Anarres::Mud::Driver::Program::Efun qw(efuns efunflags);

# This object is big and the 'context'-related stuff and possibly the
# 'generate'-related stuff could be split out.

@ISA = qw(Exporter);
	# Oddly enough, the PERL_* tags here must be in order.
@EXPORT_OK = (qw(package_to_path path_to_package
				PERL_HEAD PERL_USE PERL_VARS PERL_SUBS PERL_TAIL
				PERL_DOCS));
%EXPORT_TAGS = (
	sections	=> [ grep { /^PERL_/ } @EXPORT_OK ],
	all			=> \@EXPORT_OK,
		);

	# To insert various things into the Perl code.
sub PERL_HEAD	() { 0 }
sub PERL_USE	() { 1 }
sub PERL_VARS	() { 2 }
sub PERL_SUBS	() { 3 }
sub PERL_TAIL	() { 4 }
sub PERL_DOCS	() { 5 }

my $DEBUGLABELS = 0;

%PROGS = (
	"/foo/bar"	=> new Anarres::Mud::Driver::Program(Path=>"/foo/bar"),
		);

# Class methods

sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	confess "No Path in program" unless $self->{Path};

	$self->{Perl} = [ ];
	$self->{PerlGlobals} = [ ];

	$self->{Inherits} = { };
	$self->{Statics} = { };
	$self->{Globals} = { };
	$self->{Locals} = { };
	$self->{Labels} = { };
	$self->{LabelDefault} = undef;
	$self->{Methods} = efuns;
	$self->{MethodFlags} = efunflags;

	$self->{ScopeStack} = [ ];
	$self->{LabelStack} = [ ];

	$self->{Warnings} = [ ];
	$self->{Errors} = [ ];

	$self->{Label} = 0;

	$self->{Closures} = [ ];

	$self->{Classes} = { };

	return bless $self, $class;
}

sub find {	# find Anarres::Mud::Driver::Program $path
	return $PROGS{$_[1]};
}

sub path_to_package {
	my $path = shift;
	$path =~ s,/,::,g;
	$path =~ s/\.c$//;
	$path =~ s,^/*,,;
	return "Anarres::Mud::Library::" . $path;
}

sub package_to_path {
	my $package = shift;
	die "package_to_path: Invalid package name"
			unless $package =~ s/^Anarres::Mud::Library//;
	$package =~ s,::,/,g;
	return $package;
}

# Debugging methods

sub warning {
	my $self = shift;
	print "WARNING: $_\n" foreach @_;
	push(@{ $self->{Warnings} }, @_);
}

sub error {
	my $self = shift;
	print "ERROR: $_\n" foreach @_;
	push(@{ $self->{Errors} }, @_);
}

# Instance query methods

sub path { return $_[0]->{Path}; }
sub source { return $_[0]->{Source}; }
sub ppsource { return $_[0]->{PPSource}; }
sub package { return path_to_package $_[0]->{Path}; }

sub methods	{ return values %{ $_[0]->{Methods} }; }
# sub locals	{ return values %{ $_[0]->{Globals} }; }
sub globals	{ return values %{ $_[0]->{Globals} }; }

sub variable {
	my ($self, $name) = @_;
	return $self->{Locals}->{$name}
		|| $self->{Globals}->{$name}
		|| undef;
}

# Instance modification methods

sub closure {
	my ($self, $clousure) = @_;
	return (push(@{ $self->{Closures} }, $clousure) - 1);
}

sub reset_labels {
	my $self = shift;
	# invoke for new method?
	die "Label stack not empty" if @{ $self->{LabelStack} };
	$self->{LabelDefault} = undef;
	$self->{Labels} = { };
	$self->{LabelCurrent} = undef;
	$self->{LabelStack} = [ ];
	$self->{BreakTarget} = undef;
	$self->{BreakStack} = [ ];
	print "Label stack reset\n" if $DEBUGLABELS;
}

sub switch_start {
	my ($self, $type) = @_;		# Do something with 'type'
	push(@{$self->{LabelStack}},
			[
				$self->{Labels},
				$self->{LabelDefault},
			]);
	$self->{LabelDefault} = undef;
	$self->{Labels} = { };
	push(@{$self->{BreakStack}}, $self->{BreakTarget});
	$self->{BreakTarget} = $self->label(undef);
	print "Start switch: Push labels: " .
							scalar(@{ $self->{LabelStack} }) . "\n"
					if $DEBUGLABELS;
	return $self->{BreakTarget};
}

sub switch_end {
	my $self = shift;
	my $ret = [ $self->{Labels}, $self->{LabelDefault} ];
	my ($labels, $default) = @{ pop(@{ $self->{LabelStack} }) };
	$self->{Labels} = { %{$self->{Labels}}, %$labels, };
	$self->{LabelDefault} ||= $default;
	$self->{BreakTarget} = pop(@{$self->{BreakStack}});
	print "End switch: Pop labels: " .
							scalar(@{ $self->{LabelStack} }) . "\n"
					if $DEBUGLABELS;
	return $ret;
}

sub loop_start {
	my $self = shift;
	$self->{BreakTarget} = undef;
	$self->{ContinueTarget} = $self->label(undef);
}

sub loop_end {
	my $self = shift;
	$self->{BreakTarget} = pop(@{$self->{BreakStack}});
	return $self->{BreakTarget};	# Make the return explicit
}

# XXX This mechanism isn't currently used.
sub statement {
	$_[0]->{LabelCurrent} = undef;
}

sub label {
	my ($self, $val) = @_;
	return undef if $self->{LabelCurrent};
	my $label = '__AMD_LABEL' . $self->{Label}++;
	if (defined $val) {
		print "Adding label $label => " . $val->dump . "\n"
					if $DEBUGLABELS;
		$self->{Labels}->{$label} = $val
	}
	return $label;
}

sub default {
	my $self = shift;
	print "Adding DEFAULT label\n"
				if $DEBUGLABELS;
	return ($self->{LabelDefault} = $self->label(undef));
}

# This should return a label in a switch or undef in a loop.
sub getbreaktarget {
	$_[0]->{BreakTarget};
}

sub save_locals {
	my $self = shift;
	my %saved = %{ $self->{Locals} };
	push(@{$self->{ScopeStack}}, \%saved);
}

sub restore_locals {
	my $self = shift;
	$self->{Locals} = pop(@{ $self->{ScopeStack} });
}

	# XXX Check that we don't declare a variable of type void.

sub local {
	my ($self, $name, $var) = @_;
	# print STDERR "local($name, $var)\n";
	return $self->{Locals}->{$name} unless $var;
	$self->warning("Local $name masks previous definition")
			if $self->{Locals}->{$name}
			|| $self->{Globals}->{$name}
			|| $self->{Statics}->{$name};
	# print "Storing local variable " . $var->dump . "\n";
	$self->{Locals}->{$name} = $var;
	return ();
}

sub global {
	my ($self, $name, $var) = @_;
	# print STDERR "global($name, $var)\n";
	return $self->{Globals}->{$name} unless $var;
	$self->error("Global $name masks previous definition in file XXX")
			if $self->{Globals}->{$name}
			|| $self->{Statics}->{$name};
	# print "Storing variable $name\n";
	$self->{Globals}->{$name} = $var;
	return ();
}

sub static {
	my ($self, $name, $var) = @_;
	# print STDERR "static($name, $var)\n";
	return $self->{Statics}->{$name} unless $var;
	$self->error("Static $name masks previous definition in file XXX")
			if $self->{Statics}->{$name};
	# print "Storing variable $name\n";
	$self->{Statics}->{$name} = $var;
	return ();
}

sub method {
	my ($self, $name, $method) = @_;

	# print STDERR "method($name, $method)\n";

	# print STDERR "program->method($method)\n";

	unless ($method) {
		$name =~ s/^.*:://;	# XXX Remove and do properly.
		my $ob = $self->{Methods}->{$name};
		if (!$ob) {
			$self->error("Method $name not found") unless $ob;
			# warn "Autodefining method $name for bison yyparse";
			$ob ||= new Anarres::Mud::Driver::Program::Method(
							Type	=> T_INTEGER,
							Name	=> $name,
							Args	=> [],
							Flags	=> M_UNKNOWN,
								);
			$self->{Methods}->{$name} = $ob;
			$self->{MethodFlags}->{$name} = 0;	# XXX UNDEFINED!
		}
		return $ob;
	}

	my $proto = $self->{Methods}->{$name};
	if ($proto) {
		# XXX Check that types match!
		warn "Method $name already defined"
				if $proto->code;
	}

	# print STDERR "Defining method $name\n";

	# XXX Check prototype match with superclass
	# XXX Check sanity of modifiers

	$self->{Methods}->{$name} = $method;
	$self->{MethodFlags}->{$name} = 0
					unless exists $self->{MethodFlags}->{$name};

	return ();
}

sub inherit {
	my ($self, $name, $path) = @_;

	my $inh = $PROGS{$path};
	return "Could not find inherited program '$path'" unless $inh;

	$name = basename($path, ".c") unless $name;		# Also support DGD
	return "Already inheriting file named $name"
					if $self->{Inherits}->{$path};

	$self->{Inherits}->{$name} = $inh;

	my @errors;

	foreach ($inh->globals) {
		my $err = $self->global($_);
		push(@errors, $err), next if $err;
		# Variable flags? Accessibility.
	}

	foreach ($inh->methods) {
		next if $_->flags & (M_EFUN | M_UNKNOWN | M_PRIVATE);
		my $err = $self->method($_->name, $_);	# XXX Mark inherited
		push(@errors, $err) if $err;
		$err = $self->method($name . "::" . $_->name, $_);
		push(@errors, $err) if $err;
	}

	return @errors;
}

sub class {
	my ($self, $cname, $fields) = @_;

	unless ($fields) {
		# Search for the class; return a valid type for it.
		my $class = $self->{Classes}->{$cname};
		return $class if $class;
		$self->error("No class named $cname");
		return undef;
	}

	my (%class, @types);
	foreach (@$fields) {
		my ($name, $type) = ($_->name, $_->type);
		push(@types, $type);

		if ($class{$name}) {
			$self->error("Field name $name multiply defined in class " .
							$cname);
			next;
		}
		$class{$name} = $type;
	}

	my $type = T_CLASS($cname, @types);

	$self->{Classes}->{$cname} = {
					Data	=> $fields,
					Fields	=> \%class,
					Type	=> $type,
						};

	# print Dumper($fields);
	# print STDERR "New class type is " . $$type . "\n";

	return 1;
}

sub class_type {
	my ($self, $cname) = @_;

	my $class = $self->class($cname);
	unless ($class) {
		$self->error("No such class $cname");
		return T_FAILED;
	}

	return $class->{Type};
}

sub class_field_type {
	my ($self, $cname, $fname) = @_;

	my $class = $self->{Classes}->{$cname};
	unless ($class) {
		$self->error("No such class $cname");
		return T_FAILED;
	}

	my $ftype = $class->{Fields}->{$fname};
	unless ($ftype) {
		$self->error("No such field $fname in class $cname");
		return T_FAILED;
	}

	return $ftype;
}

# Debugging

sub dump {
	my ($self) = @_;

	my @inh = map { "(inherit " .
					quote(printable $_) . " " .
					quote(printable $self->{Inherits}->{$_}->path)
					. ")" }
					keys %{$self->{Inherits}};
	my @glob = sort map { $_->dump(1) } values %{$self->{Globals}};
	my @meth = sort keys %{$self->{Methods}};
	@meth = grep { ! ($self->{MethodFlags}->{$_} & M_EFUN) } @meth;
	@meth = map { $self->{Methods}->{$_}->dump(1) } @meth;

	my $out = "(program\n\t" . join("\n\t", @inh, @glob, @meth) . "\n)";

	return $out;
}

# Semantics

sub check {
	my $self = shift;

	my @meth = grep { ! ($self->{MethodFlags}->{$_} & M_EFUN) }
					keys %{$self->{Methods}};

	my $ret = 1;
	foreach (@meth) {
		my $tcm = $self->{Methods}->{$_}->check($self, 0);
		$ret &&= $tcm;
	}

	return $ret;
}

# Output

sub perl {
	my ($self, $section, @code) = @_;
	if (@code) {
		push(@{ $self->{Perl}->[$section] }, @code);
		return ();
	}
	else {
		return join("\n", @{ $self->{Perl}->[$section] });
	}
}

sub perl_global {
	my ($self, @globals) = @_;
	push( @{ $self->{PerlGlobals} }, @globals);
}

sub generate {
	my ($self) = @_;

	my $path = $self->{Path};
	my $package = $self->package;

	$self->perl(PERL_HEAD, "# program $path;");
	$self->perl(PERL_HEAD, "package $package;");
	$self->perl(PERL_USE, "use strict;");
	$self->perl(PERL_USE, "use warnings;");

	$self->perl_global(q[$PROGRAM]);

	if (scalar %{ $self->{Inherits} }) {
		my $inh = join " ",
				map { $_->package }
						values %{ $self->{Inherits} };
		$self->perl_global(q[@ISA]);
		$self->perl(PERL_VARS, qq[\@ISA = qw($inh);]);
	}
	else {
		$self->perl(PERL_SUBS, qq[sub new { bless { }, shift; }\n]);
	}

	$self->perl(PERL_USE, 'use vars qw(' .
							join(" ", @{ $self->{PerlGlobals} }) .
							");");
	# XXX $path forms part of a Perl program. Beware.
	$self->perl(PERL_VARS,
			'*PROGRAM = \$' . __PACKAGE__ . "::PROGS{'$path'};");
	$self->perl(PERL_TAIL, '1;');
	$self->perl(PERL_TAIL, '__END__');

	# These have a very large extent.
	local *::methods = $self->{Methods};
	local *::methodflags = $self->{MethodFlags};

	# Should we be doing these in order of definition? I've just
	# put them into alpha order so I can find methods more easily
	# in the generated Perl, but we lose definition order in the
	# hash.
	my @meth = map { $::methods{$_}->generate(0, $path) }
				grep { ! ($::methodflags{$_} & M_EFUN) }
					sort keys %::methods;


	$self->perl(PERL_SUBS, @meth);

	my $out = '';
	foreach (0..$#{$self->{Perl}}) {
		$out .= "# === Section " .
						$EXPORT_TAGS{sections}->[$_] . "\n";
		$out .= $self->perl($_) . "\n\n";
	}
	return $out;
}

1;
