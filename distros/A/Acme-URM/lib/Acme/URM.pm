package Acme::URM;
use strict;
use Data::Dumper;

our $VERSION	= '0.02';

use constant	LAST		=> -1;
use constant	THIS		=> -2;
use constant	MAX_STEPS	=> -3;

my $DEBUG   = 0;
sub import {
    foreach (@_) {
        if(/^debug$/) {
            $DEBUG  = 1;
        }
    }
}

sub new {
	my $class	= shift;
	my $self	= {@_};
	$self		= bless $self, $class;
	$self->_init();
	$self
}

sub _init {
	my $self	= shift;
	$self->{registers}	= ();
	$self->{program}	= ();
	$self->{instr_num}	= 0;
	$self->{max_steps}	= -1;	# infinite
}

sub program {
	my $self	= shift;
	push @{$self->{program}}, @_	if scalar @_;
	[$self->{program}]
}

sub clear_program {
	my $self	= shift;
	$self->{program}	= ();
}

sub register {
	my $self	= shift;
	my $n		= shift || 0;
	my $i		= $n;
	foreach (@_) {
		$self->{registers}[$i++]	= $_;
	}
	(defined $self->{registers}[$n]) ? $self->{registers}[$n] : 0
}

sub clear_registers {
	my $self	= shift;
	$self->{registers}	= [];
}

sub clear {
	my $self	= shift;
	$self->clear_program();
	$self->clear_registers();
}

sub run {
	my $self	= shift;
	$self->{instr_num}	= 0;
	$self->{steps_num}	= 0;
	my $run	= 1;
	do {
		my $step	= $self->_step();
		return	$step	if MAX_STEPS == $step;
		$run		= (scalar(@{$self->{program}}) > $step) ? 1 : 0;
	} while( $run );
	_debug( "program executed",
		   "registers: " . Dumper([$self->{registers}]),
		   "",
		  );
	$self->register(0)
}

sub _check_nreg {
	my $self	= shift;
	my $nreg	= shift;
	die "invalid register index: '$nreg'\n"	if $nreg !~ /^\s*\d+\s*$/ || $nreg < 0;
}

sub _step {
	my $self	= shift;
	my $cmd		= $self->{program}[ $self->{instr_num} ];
	_debug( "running instruction $self->{instr_num}: $cmd",
		   "registers: " . Dumper($self->{registers}),
		   "",
		  );
	my $instr_num_save	= $self->{instr_num};
	if( $cmd =~ /^\s*Z\s*\((.*)\)$/i ) {
		my $nreg	= $1;
		$self->_check_nreg( $nreg );
		$self->register( $nreg, 0 );
		$self->{instr_num}++;
	} elsif( $cmd =~ /^\s*S\s*\((.*)\)$/i ) {
		my $nreg	= $1;
		$self->_check_nreg( $nreg );
		$self->register( $nreg, $self->register($nreg) + 1 );
		$self->{instr_num}++;
	} elsif( $cmd =~ /^\s*T\s*\((.*)\)$/i ) {
		my ($nreg0,$nreg1)	= split /\s*,\s*/, $1;
		$self->_check_nreg( $nreg0 );
		$self->_check_nreg( $nreg1 );
		$self->register( $nreg1, $self->register($nreg0) );
		$self->{instr_num}++;
	} elsif( $cmd =~ /^\s*J\s*\((.*)\)$/i ) {
		my ($nreg0,$nreg1,$q)	= split /\s*,\s*/, $1;
		$self->_check_nreg( $nreg0 );
		$self->_check_nreg( $nreg1 );
		if( $self->register($nreg0) == $self->register($nreg1) ) {
			if( $q == LAST ) {
				$self->{instr_num}	= scalar @{$self->{program}};
			} elsif( $q == THIS ) {
				# save instruction number
			} elsif( $q !~ /^\s*\d+\s*$/ ) {
				die "invalid instruction index: '$q'\n";
			} else {
				$self->{instr_num}	= $q;
			}
		} else {
			$self->{instr_num}++;
		}
	} else {
		die "invalid instruction: '$cmd'\n";
	}
	$self->{steps_num}++;
	if( 0 < $self->{max_steps} && $self->{max_steps} < $self->{steps_num} ) {
		return	MAX_STEPS;
	}
	_debug( "after running instruction $instr_num_save: $cmd",
		   "registers: " . Dumper($self->{registers}),
		   "",
		  );
	$self->{instr_num}
}

sub max_steps {
	my $self	= shift;
	my $val		= shift;
	$self->{max_steps}	= $val	if defined $val;
	$self->{max_steps}
}

sub _debug {
	print join("\n",@_),"\n"	if $DEBUG;
}

1;

__END__

=head1 NAME

Acme::URM - URM (unlimited register machine) emulation

=head1 SYNOPSIS

  use Acme::URM;

  my $rm  = Acme::URM->new();
  # program that summarize parameters given in R0,R1
  $urm->program(
               'T(0,2)',
               'T(1,3)',
               'J(3,4,6)',
               'S(2)',
               'S(4)',
               'J(0,0,2)',
               'T(0,3)',
               'J(3,1,'.Acme::URM::LAST.')',
               'J(3,2,11)',
               'S(3)',
               'J(0,0,7)',
               'T(1,0)',
               );

  $urm->register( 0, 2, 2 );	# fill the registers
  my $res	= $urm->run();	# res must be 4

=head1 DESCRIPTION

This module gives you the methods needed to emulate an URM in Perl.

Why? Because we can.

What is URM?

URM stands for unlimited register machine.

URM has unlimited number of registers: R0, R1, ... Those contain natural numbers: r0, r1, ... Default values for ri are 0.

Instruction for URM is one of the following instructions:

=over 3

=item *

Z(n)       - set up register with index n to zero

=item *

S(n)       - increment value of register with index n by 1

=item *

T(m, n)    - set up register with index n to value of register with index m

=item *

J(m, n, q) - conditional instruction: if values of registers with indexes m, n are equal, then go to insturction with index q (zero based index), else move to following instruction

=back


Program of URM is a finite list of URM instructions.

=head1 METHODS

=over 2

=item B<new>

Creates the URM machine object.

=item B<program> [new_instructions]

New instructions are added to program if given.
Returns reference to array with the current program of URM object

=item B<clear_program>

Clears current program of URM object

=item B<register> n [value [values]]

Set up nth register with "value" if given.
Returns value of nth register.
If values parameters is specified, values of registers following nth are set accordingly.

=item B<clear_registers>

Clears current registers of URM object

=item B<clear>

Clears current program & registers of URM object

=item B<max_steps> [value]

Set up value of maximum steps for URM if given.
Returns current values for maximum steps for URM.

This value is designed to prevent URM from infinite execution.

=item B<run>

Run program of URM object.
Possible return values:
- value of R0 register;
- MAX_STEPS	constant (see I<max_steps> function)

=back

=head1 EXAMPLE

The following example computes the maximum of 2 numbers:

  use Acme::URM;
  my $urm  = Acme::URM->new();
  $urm->program(
                         'T(0,2)',
                         'T(1,3)',
                         'J(3,4,6)',
                         'S(2)',
                         'S(4)',
                         'J(0,0,2)',
                         'T(0,3)',
                         'J(3,1,11)',
                         'J(3,2,'.Acme::URM::LAST.')',
                         'S(3)',
                         'J(0,0,7)',
                         'T(1,0)',
                         );

  $urm->register( 0, 2, 3 );
  $urm->run() == 3;

=head1 DEBUG MODE

You can use this module in debug mode, like this:

  use Acme::URM qw/debug/;

Which will produce some output while running the program.

=head1 USEFULNESS

I coded this module while checking out TA (theory of algorithms) materials.

=head1 REFERENCES

Russian wiki link:
http://ru.wikipedia.org/wiki/%D0%9C%D0%9D%D0%A0

=head1 AUTHOR

Alexander Soudakov (cygakoB@gmail.com), April 2008.

=cut
