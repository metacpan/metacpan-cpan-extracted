# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003 - 2004 Joost Diepenmaat.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the COPYING file for more information.

package Audio::LADSPA::Plugin::Sequencer4;
use strict;
use base qw(Audio::LADSPA::Plugin::Perl);
our $VERSION = "0.021";
use Carp;


my @frequency_table = map { 440 * (2 ** ( ( $_ - 69) / 12 )) } 0 .. 127;

__PACKAGE__->description(
	name => 'Audio::LADSPA::Plugin::Sequencer4',
	label => 'squencer',
	maker => 'Joost Diepenmaat',
	copyright => 'GPL',
	id => '1',
	ports => [
	    {
		name => 'Run/Step',
		is_input => 1,
		is_control => 1,
		is_integer => 1,
		upper_bound => 10000,
	    },
	    {
		name => 'Step 1',
		is_input => 1,
		is_control => 1,
		is_integer => 1,
		upper_bound => 127,
	    },
	    {
		name => 'Step 2',
		is_input => 1,
		is_control => 1,
		is_integer => 1,
		upper_bound => 127,
	    },
	    {
		name => 'Step 3',
		is_input => 1,
		is_control => 1,
		is_integer => 1,
		upper_bound => 127,
	    },
	    {
		name => 'Step 4',
		is_input => 1,
		is_control => 1,
		is_integer => 1,
		upper_bound => 127,
	    },
	    {
		name => 'Frequency',
		is_input => 0,
		is_control => 1,
	    },
	    {
		name => 'Trigger',
		is_input => 0,
		is_control => 1,
	    },
    
	],
);

sub init {
    my $self = shift;
    $self->{run_counter} = 0;
    $self->{step_counter} = 1;
}

sub run {
    my ($self,$samples) = @_;
    $self->set(5, $frequency_table[$self->get( $self->{step_counter})]);
    if (++$self->{run_counter} >= $self->get(0)) {
	$self->{run_counter} = 0;
	$self->{step_counter}++;
	$self->{step_counter} = 1 if $self->{step_counter} > 4;
	$self->set(6,1);
    }
    else {
	$self->set(6,0);
    }
}




__END__

=pod

=head1 NAME

Audio::LADSPA::Plugin::Sequencer4 - Really simple 4-step sequencer

=head1 SYNOPSIS

    use Audio::LADSPA::Network;
    use Audio::LADSPA::Plugin::Play;
    use Audio::LADSPA::Plugin::Sequencer4;

    my $net = Audio::LADSPA::Network->new( buffer_size => 100 );
    my $seq = $net->add_plugin( 'Audio::LADSPA::Plugin::Sequencer4' );
    my $sine = $net->add_plugin( id => 1047);
    my $delay = $net->add_plugin( id => 1043);
    my $play = $net->add_plugin( 'Audio::LADSPA::Plugin::Play' );

    $net->connect($seq,'Frequency',$sine, 'Frequency (Hz)');
    $net->connect($sine,'Output', $delay, 'Input');
    $net->connect($delay,'Output', $play, 'Input');

    $sine->set(Amplitude => 1);

    $delay->set('Delay (Seconds)' => 0.5);
    $delay->set('Dry/Wet Balance' => 0.3);

    $seq->set('Step 1',70); # midi note numbers
    $seq->set('Step 2',82);
    $seq->set('Step 3',96);
    $seq->set('Step 4',108);
    $seq->set('Run/Step',150);

    while (1) {
	$net->run(100);
    }

=head1 DESCRIPTION

Audio::LADSPA::Sequencer4 is a simple step-sequencer for use in an
Audio::LADSPA::Network. 

=head2 Input control ports

B<"Run/Step">

how many times run() must be called before a new step is triggered

B<"Step 1" .. "Step 4">

The note value for step 1 .. 4 as a MIDI note number.

=head2 Output control ports

B<"Frequency">

Output frequency of the current step (in Hz)

B<"Trigger">

Trigger for start of each step.

=head2 More info

More information can be requested with the C<pluginfo> tool:

  pluginfo --package Audio::LADSPA::Plugin::Sequencer4

=head1 SEE ALSO

L<Audio::LADSPA::Network>, L<Audio::LADSPA::Plugin::Perl>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Joost Diepenmaat <jdiepen@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

