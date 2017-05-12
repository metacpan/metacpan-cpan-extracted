package Anarres::Mud::Driver::Program::Efun;

use strict;
use vars qw(@ISA @EXPORT_OK %EFUNS %EFUNFLAGS);
use Data::Dumper;
use Carp;
use Exporter;
use Anarres::Mud::Driver::Program::Variable;
use Anarres::Mud::Driver::Program::Method;
use Anarres::Mud::Driver::Compiler::Type qw(:all);

@ISA = qw(Anarres::Mud::Driver::Program::Method);
@EXPORT_OK = qw(register efuns efunflags);

%EFUNS = ();
%EFUNFLAGS = ();

sub instantiate {
}

sub register {
	my ($class, $flags, $rettype, @argtypes) = @_;

	# print "Registering efun $class(".join(", ",map{$$_}@argtypes).")\n";

	my $efun = $class;
	$efun =~ s/^.*:://;

	croak "Duplicate efun $efun" if $EFUNS{$efun};

	my @args = ();
	my $i = 0;
	foreach (@argtypes) {
		my $arg = new Anarres::Mud::Driver::Program::Variable(
						Type	=> $_,
						Name	=> "arg" . $i,
							);
		push(@args, $arg);
		$i++;
	}

	{
		no strict qw(refs);
		*{"$class\::ISA"} = [ qw(Anarres::Mud::Driver::Program::Efun) ]
						unless @{"$class\::ISA"};
	}

	my $instance = $class->new(
					Name	=> $efun,
					Type	=> $rettype,
					Args	=> \@args,
						);

	$EFUNS{$efun} = $instance;
	$EFUNFLAGS{$efun} = $flags | M_EFUN | M_INHERITED;
}

# Class methods

sub efuns { return { %EFUNS }; }
sub efunflags { return { %EFUNFLAGS }; }

# Instance methods

sub generate_call {
	my ($self, @args) = @_;
	unshift(@args, '$self');
	return ref($self) . '::invoke(' . join(', ', @args) . ')';
}

sub dump {
	my $self = shift;
	my $name = ref($self);
	$name =~ s/^.*:://;
	return "(efun $name)";
}

1;
