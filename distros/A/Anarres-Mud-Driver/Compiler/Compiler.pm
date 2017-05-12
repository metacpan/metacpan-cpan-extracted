package Anarres::Mud::Driver::Compiler;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use Carp qw(cluck confess);

require DynaLoader;

$VERSION = 0.10;
@ISA = qw(DynaLoader);

use Anarres::Mud::Driver::Compiler::Type;
use Anarres::Mud::Driver::Compiler::Node;
use Anarres::Mud::Driver::Compiler::Dump;
use Anarres::Mud::Driver::Compiler::Check;
use Anarres::Mud::Driver::Compiler::Generate;

bootstrap Anarres::Mud::Driver::Compiler;

sub compile {
	my ($self, $path) = @_;
	my $program = new Anarres::Mud::Driver::Program(
					Path	=> $path,
						);
	my $data;
	{
		local $/ = undef;
		local *FH;

		open(FH, "<$path") or die "Compiler: Cannot open file $path";
		$data = <FH>;
		close(FH);
	}

	{
		local $SIG{__WARN__} = sub { cluck @_; };
		local $SIG{__DIE__} = sub { confess @_; };
		$self->parse($program, $data);
	}

	return $program
}

1;
