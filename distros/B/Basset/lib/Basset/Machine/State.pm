package Basset::Machine::State;

#Basset::Machine::State, copyright and (c) 2004, 2006 James A Thomason III
#Basset::Machine::State is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Machine::State - used to create machine states.

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

Read the pod on L<Basset::Machine> for more information on machines. Basset::Machine::State
is a mostly abstract superclass for states defined to work with machines.

 package Some::Machine::Foozle;
 use base 'Basset::Machine::State';
 
 sub main {
 	my $self = shift;
 	my $machine = $self->machine;
 	
 	#do interesting things.
 	
 	return $machine->transition('beezle');
 }

states live under their machine ('My::Machine' requires 'My::Machine::State1', 'My::Machine::State2', etc.)
and are entered via the method ->main, which the machine calls when the state is entered.

=cut

$VERSION = '1.01';

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

=over

=item machine

The machine associated with this state.

=back

=cut

__PACKAGE__->add_attr('machine');

=pod

=head1 METHODS

=over

=item main

abstract super method. You will need to override this with the code for your state. This
implementation only aborts the machine.

=back

=cut

sub main {
	return shift->machine->abort("Cannot enter state : no main method", "BMS-01");
}

1;
