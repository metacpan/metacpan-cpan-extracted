# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003  Joost Diepenmaat.
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

package Audio::LADSPA::Plugin::Play;
use strict;
use Audio::LADSPA::Plugin::Perl;
use Audio::Play ();
our @ISA = qw(Audio::LADSPA::Plugin::Perl);
our $VERSION = "0.021";
use Carp;

sub init {
    my ($self) = @_;
    my $play = Audio::Play->new() or croak "Cannot create audio output";
    $self->{player} = $play;
}

__PACKAGE__->description(
	name => 'Audio::LADSPA::Plugin::Play',
	label => 'play',
	maker => 'Joost Diepenmaat',
	copyright => 'GPL',
	id => '0',
	ports => [
	    {
		name => 'Input',
		is_input => 1,
		is_control => 0,
	    },
	],
);

sub run {
    my ($self,$samples) = @_;
    my $bd = Audio::Data->new( rate => 44100 );
    $bd.= [$self->get_buffer('Input')->get_list() ];	# can this be made faster???
    $self->{player}->play( $bd );
}


__END__

=pod

=head1 NAME

Audio::LADSPA::Plugin::Play - Audio::LADSPA glue to Audio::Play

=head1 SYNOPSIS

    use Audio::LADSPA::Network;
    use Audio::LADSPA::Plugin::Play;

    my $net = Audio::LADSPA::Network->new();
    my $sine = $net->add_plugin( label => 'sine_fcac' );
    my $play = $net->add_plugin('Audio::LADSPA::Plugin::Play');

    $net->connect($sine,'Output',$play,'Input');
    
    $sine->set('Frequency (Hz)' => 440); # set freq
    $sine->set(Amplitude => 1);   # set amp

    for ( 0 .. 100 ) {
        $net->run(100);
    }


=head1 DESCRIPTION

This module is a glue module, acting as a 1-input Audio::LADSPA::Plugin
that sends its input to L<Audio::Play|Audio::Play>. This is currently
the easiest way of getting sound from the Audio::LADSPA modules.

=head1 CAVEATS

Due to
the limitation of Audio::Play, this module is currently mono only, but
it should be reasonably portable. 

All data coming in on its input port is I<immediately> send out to
the sound card when the run() method is called, which probably means
that on slower machines you need run() calls of more samples. On my
machine runs of 100 samples work fine most of the time, but YMMV.

This module is based on Audio::LADSPA::Plugin::Perl, which is unfinished,
so calling certain methods from the Audio::LADSPA::Plugin API on it might
not work. See L<Audio::LADSPA::Plugin::Perl> for details.

=head1 SEE ALSO

L<Audio::LADSPA::Network>, L<Audio::LADSPA::Plugin::Perl>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 Joost Diepenmaat <jdiepen@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

