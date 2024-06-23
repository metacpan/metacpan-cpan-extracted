use strict;
use warnings;
package Audio::SunVox::FFI;
use base qw/ Exporter /;

use FFI::Platypus 2.00;
use FFI::CheckLib 0.25 qw/ find_lib_or_die /;
use Carp qw/ croak carp /;

our $VERSION = '0.01';

# ABSTRACT: Bindings for the SunVox library - a modular synthesizer and sequencer

our $lofi = 0;
my $ffi;
my $constants;
my $binds;

{
    package SunVox::Note;
    use FFI::Platypus::Record;

    record_layout_1(
        uint8   => 'note',
        uint8   => 'vel',
        uint16  => 'module',
        uint16  => 'ctl',
        uint16  => 'ctl_val',
    );
}

sub _load_sunvox {
    $ffi = FFI::Platypus->new(
        api => 2,
        lib => [
            find_lib_or_die(
                lib   => 'sunvox',
                alien => 'Alien::SunVox',
            )
        ]
    );
    return 1;
}

sub _bind {
    $ffi->type('record(SunVox::Note)' => 'sunvox_note');
    for my $fn ( keys %{ $binds } ) {
        $ffi->attach( $fn => @{ $binds->{ $fn } } );
    }
}

BEGIN {
    _load_sunvox;

    $constants = {
        NOTECMD_NOTE_OFF        => 128,
        NOTECMD_ALL_NOTES_OFF   => 129,
        NOTECMD_CLEAN_SYNTHS    => 130,
        NOTECMD_STOP            => 131,
        NOTECMD_PLAY            => 132,
        NOTECMD_SET_PITCH       => 133,
        NOTECMD_CLEAN_MODULE    => 140,

        SV_INIT_FLAG_NO_DEBUG_OUTPUT        => ( 1 << 0 ),
        SV_INIT_FLAG_USER_AUDIO_CALLBACK    => ( 1 << 1 ),
        SV_INIT_FLAG_OFFLINE                => ( 1 << 1 ),
        SV_INIT_FLAG_AUDIO_INT16            => ( 1 << 2 ),
        SV_INIT_FLAG_AUDIO_FLOAT32          => ( 1 << 3 ),
        SV_INIT_FLAG_ONE_THREAD             => ( 1 << 4 ),

        SV_TIME_MAP_SPEED       => 0,
        SV_TIME_MAP_FRAMECNT    => 1,

        SV_MODULE_FLAG_EXISTS       => ( 1 << 0 ),
        SV_MODULE_FLAG_GENERATOR    => ( 1 << 1 ),
        SV_MODULE_FLAG_EFFECT       => ( 1 << 2 ),
        SV_MODULE_FLAG_MUTE         => ( 1 << 3 ),
        SV_MODULE_FLAG_SOLO         => ( 1 << 4 ),
        SV_MODULE_FLAG_BYPASS       => ( 1 << 5 ),

        SV_MODULE_INPUTS_OFF    => 16,
        SV_MODULE_INPUTS_MASK   => ( 255 << 16 ),
        SV_MODULE_OUTPUTS_OFF   => 16 + 8,
        SV_MODULE_OUTPUTS_MASK  => ( 255 << ( 16 + 8 ) ),
    };

    $binds = {
        sv_init                         => [ [qw/ string int int uint32 /]                  => 'int' ],
        sv_deinit                       => [ [qw/ void /]                                   => 'int' ],
        sv_get_sample_rate              => [ [qw/ void /]                                   => 'int' ],
        sv_update_input                 => [ [qw/ void /]                                   => 'int' ],
        sv_audio_callback               => [ [qw/ opaque int int uint32 /]                  => 'int' ],
        sv_audio_callback2              => [ [qw/ opaque int int uint32 int int opaque /]   => 'int' ],
        sv_open_slot                    => [ [qw/ int /]                                    => 'int' ],
        sv_close_slot                   => [ [qw/ int /]                                    => 'int' ],
        sv_lock_slot                    => [ [qw/ int /]                                    => 'int' ],
        sv_unlock_slot                  => [ [qw/ int /]                                    => 'int' ],
        sv_load                         => [ [qw/ int string /]                             => 'int' ],
        sv_load_from_memory             => [ [qw/ int opaque uint32 /]                      => 'int' ],
        sv_save                         => [ [qw/ int string /]                             => 'int' ],
        sv_play                         => [ [qw/ int /]                                    => 'int' ],
        sv_play_from_beginning          => [ [qw/ int /]                                    => 'int' ],
        sv_stop                         => [ [qw/ int /]                                    => 'int' ],
        sv_pause                        => [ [qw/ int /]                                    => 'int' ],
        sv_resume                       => [ [qw/ int /]                                    => 'int' ],
        sv_sync_resume                  => [ [qw/ int /]                                    => 'int' ],
        sv_set_autostop                 => [ [qw/ int int /]                                => 'int' ],
        sv_set_autostop                 => [ [qw/ int /]                                    => 'int' ],
        sv_end_of_song                  => [ [qw/ int /]                                    => 'int' ],
        sv_rewind                       => [ [qw/ int int /]                                => 'int' ],
        sv_volume                       => [ [qw/ int int /]                                => 'int' ],
        sv_set_event_t                  => [ [qw/ int int int /]                            => 'int' ],
        sv_send_event                   => [ [qw/ int int int int int int int /]            => 'int' ],
        sv_get_current_line             => [ [qw/ int /]                                    => 'int' ],
        sv_get_current_line             => [ [qw/ int /]                                    => 'int' ],
        sv_get_current_signal_level     => [ [qw/ int int /]                                => 'int' ],
        sv_get_song_name                => [ [qw/ int /]                                    => 'string' ],
        sv_set_song_name                => [ [qw/ int string /]                             => 'int' ],
        sv_get_song_bpm                 => [ [qw/ int /]                                    => 'int' ],
        sv_get_song_tpl                 => [ [qw/ int /]                                    => 'int' ],
        sv_get_song_length_frames       => [ [qw/ int /]                                    => 'uint32' ],
        sv_get_song_length_lines        => [ [qw/ int /]                                    => 'uint32' ],
        sv_get_time_map                 => [ [qw/ int int uint32 int /]                     => 'int' ],
        sv_new_module                   => [ [qw/ int string string int int int /]          => 'int' ],
        sv_remove_module                => [ [qw/ int int /]                                => 'int' ],
        sv_connect_module               => [ [qw/ int int int /]                            => 'int' ],
        sv_disconnect_module            => [ [qw/ int int int /]                            => 'int' ],
        sv_load_module                  => [ [qw/ int string string int int int /]          => 'int' ],
        sv_load_module_from_memory      => [ [qw/ int opaque uint32 int int int /]          => 'int' ],
        sv_sampler_load                 => [ [qw/ int int string int /]                     => 'int' ],
        sv_sampler_load_from_memory     => [ [qw/ int opaque uint32 int /]                  => 'int' ],
        sv_metamodule_load              => [ [qw/ int int string /]                         => 'int' ],
        sv_metamodule_load_from_memory  => [ [qw/ int int opaque uint32 /]                  => 'int' ],
        sv_vplayer_load                 => [ [qw/ int int string /]                         => 'int' ],
        sv_vplayer_load_from_memory     => [ [qw/ int int opaque uint32 /]                  => 'int' ],
        sv_get_number_of_modules        => [ [qw/ int /]                                    => 'int' ],
        sv_find_module                  => [ [qw/ int string /]                             => 'int' ],
        sv_get_module_flags             => [ [qw/ int int /]                                => 'uint32' ],
        sv_get_module_inputs            => [ [qw/ int int /]                                => 'int*' ],
        sv_get_module_outputs           => [ [qw/ int int /]                                => 'int*' ],
        sv_get_module_type              => [ [qw/ int int /]                                => 'string' ],
        sv_get_module_xy                => [ [qw/ int int /]                                => 'uint32' ],
        sv_get_module_color             => [ [qw/ int int /]                                => 'int' ],
        sv_set_module_color             => [ [qw/ int int int /]                            => 'int' ],
        sv_get_module_finetune          => [ [qw/ int int /]                                => 'uint32' ],
        sv_set_module_finetune          => [ [qw/ int int int /]                            => 'int' ],
        sv_set_module_relnote           => [ [qw/ int int int /]                            => 'int' ],
        sv_get_module_scope2            => [ [qw/ int int int sint16* uint32 /]             => 'uint32' ],
        sv_module_curve                 => [ [qw/ int int int float* int int/]              => 'int' ],
        sv_get_number_of_module_ctls    => [ [qw/ int int /]                                => 'int' ],
        sv_get_module_ctl_name          => [ [qw/ int int int /]                            => 'string' ],
        sv_get_module_ctl_value         => [ [qw/ int int int int /]                        => 'int' ],
        sv_set_module_ctl_value         => [ [qw/ int int int int int /]                    => 'int' ],
        sv_get_module_ctl_min           => [ [qw/ int int int int /]                        => 'int' ],
        sv_get_module_ctl_max           => [ [qw/ int int int int /]                        => 'int' ],
        sv_get_module_ctl_offset        => [ [qw/ int int int /]                            => 'int' ],
        sv_get_module_ctl_type          => [ [qw/ int int int /]                            => 'int' ],
        sv_get_module_ctl_group         => [ [qw/ int int int /]                            => 'int' ],
        sv_new_pattern                  => [ [qw/ int int int int int int int string /]     => 'int' ],
        sv_remove_pattern               => [ [qw/ int int /]                                => 'int' ],
        sv_get_number_of_patterns       => [ [qw/ int /]                                    => 'int' ],
        sv_find_pattern                 => [ [qw/ int string /]                             => 'int' ],
        sv_get_pattern_x                => [ [qw/ int int /]                                => 'int' ],
        sv_get_pattern_y                => [ [qw/ int int /]                                => 'int' ],
        sv_set_pattern_xy               => [ [qw/ int int int int /]                        => 'int' ],
        sv_get_pattern_tracks           => [ [qw/ int int /]                                => 'int' ],
        sv_get_pattern_lines            => [ [qw/ int int /]                                => 'int' ],
        sv_set_pattern_size             => [ [qw/ int int int int /]                        => 'int' ],
        sv_get_pattern_name             => [ [qw/ int int /]                                => 'string' ],
        sv_get_pattern_data             => [ [qw/ int int /]                                => 'sunvox_note*' ],
        sv_set_pattern_event            => [ [qw/ int int int int int int int int int /]    => 'int' ],
        sv_get_pattern_event            => [ [qw/ int int int int int /]                    => 'int' ],
        sv_pattern_mute                 => [ [qw/ int int int /]                            => 'int' ],
        sv_get_ticks                    => [ [qw/ void /]                                   => 'uint32' ],
        sv_get_ticks_per_second         => [ [qw/ void /]                                   => 'uint32' ],
        sv_get_log                      => [ [qw/ int /]                                    => 'string' ],
    }
}

use constant $constants;
_bind;

my @export_constants = ( sort keys %{ $constants } );
my @export_binds     = ( sort keys %{ $binds } );
our @EXPORT_OK       = ( @export_constants, @export_binds );
our %EXPORT_TAGS     = ( all => \@EXPORT_OK, constants => \@export_constants, binds => \@export_binds );


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Audio::SunVox::FFI - Bindings for the SunVox library - a modular synthesizer and sequencer

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Audio::SunVox::FFI ':all';
    
    # Initialise
    my $audiodriver = 'asio';
    my $audiodevice = 1;
    my $buffer      = 256;
    my $frequency   = 48_000;
    my $channels    = 2;
    sv_init( "audiodriver=$audiodriver|audiodevice=$audiodevice|buffer=$buffer", $frequency, $channels );
    
    # Open a "slot" - an instance of SunVox
    my $slot = 0;
    sv_open_slot( $slot );
    
    # Create a "generator" oscillator
    sv_lock_slot( $slot );
    my $generator = sv_new_module( $slot, "Generator", "foo name" );
    sv_connect_module( $slot, $generator, 0 ); # 0 is Output
    sv_unlock_slot( $slot );
    
    # Send an event to the generator
    sv_set_event_t( $slot, 1, 0 ); # Process events in real time
    sv_set_module_ctl_value( $slot, $generator, 7, 0, 2 ); # Disable sustain
    sv_set_module_ctl_value( $slot, $generator, 4, 200, 2 ); # Set release value
    sv_send_event( $slot, 0, 50, 127, $generator + 1 ); # Send a note on event
    # ^ Why $generator + 1? Dunno yet...
    sleep(1);
    
    # Save the patch
    sv_save( $slot, 'awesome_patch.sunvox' );
    
    # Clean up
    sv_close_slot( 0 );
    sv_deinit;

=head1 DESCRIPTION

L<SunVox|https://warmplace.ru/soft/sunvox/> is a modular synthesizer with pattern-based
sequencer (tracker). L<The SunVox library|https://warmplace.ru/soft/sunvox/sunvox_lib.php>
is a free library offering access to the facilities offered by SunVox, minus the frontend,
allowing for real-time control of sequences and playback.

This module offers Perl bindings for the SunVox library.

This distribution is currently in alpha. The bindings interface (this module) is unlikely to change
significantly, though it may benefit from some niceties - make function parameters as
consistent as possible, easier audio device discovery, automagic locking, object interface
and so on. That is, it is not as feature complete and usable as I would wish.

=head1 Getting Started

Before using this library, I would recommend trying out the complete
L<SunVox tracker application|https://warmplace.ru/soft/sunvox/> for your platform to
familiarise yourself with its capabilities and terminology. A detailed
L<User manual for SunVox|https://warmplace.ru/soft/sunvox/manual.php> is available.

As this is a more-or-less direct binding to the library, the
L<SunVox library manual|https://warmplace.ru/soft/sunvox/sunvox_lib.php> should also
provide a useful reference.

What follows is some terminology used by SunVox, with a focus on the synthesizer components
rather than the sequencer - learning to use a tracker is left to the reader as an exercise.

=head2 Slot

A slot is an independent instance of the SunVox engine, with its own set
of sequences and modules. You may create up to 16 of these, numbered from zero to fifteen.

=head2 Module

Modules perform the functions of a modular synthesizer - they perform some task as part
of a connected chain of modules, passing audio or control signals between each other
in order to play back or perform music.

In SunVox these tasks are separated into three broad categories, synths (often called
oscillators in other modular systems), effects, and misc (often called utility modules).

=head3 Synths

Synths are the noise makers, the sound producing components of the modular system. They
vary from basic oscillators and samplers, to complex additive systems like FM and
spectrographic synthesis.

Examples of Synths in SunVox include Generator, Sampler, FM, SpectraVoice, and DrumSynth.

=head3 Effects

These modules shape and colour the sound provided by synths to provide a sense
of movement, or just to make it sound good to your ears.

Examples of Effects in SunVox include Filter, Delay, Reverb, Distortion, and Compressor.

=head3 Misc

Misc modules are those which do not fit into either category above. They usually provide
useful services for directing the parameters of other modules. The provide facilities
such as envelopes, portamento (glide between notes), pitch following, and signal routing
and duplication.

Examples of Misc modules in SunVox include ADSR, Glide, Pitch Detector, and MultiSynth.

=head3 MetaModule

MetaModule is a stand out misc-category module. It is a module of modules. That is, it allows for
the creation of custom modules using existing modules as building blocks.

It may be possible to create MetaModules using the sunvox library by creating and
loading patches as MetaModules, though a means of mapping controllers to MetaModule
components does not appear to be available currently.

=head3 Input / Output

Module 0 is a special module called "Output", which is always present. This module
represents the output side of the configured audio interface.

A corresponding synth module called "Input" may be instantiated to route audio from the
input of your audio interface for, e.g. live performance or sampling of another
instrument.

=head2 Connection

Connections between modules may be created in any arbitrary combination, though only some
of these make sense, e.g. the classic oscillator -> filter -> output chain (if you noticed
the absence of a VCA and envelope generator here, note that SunVox synths usually
incorporate their own envelopes and amplitude control, as well as filters and filter
envelopes in some cases).

Any set of modules hoping to produce a sound must ultimately be connected to the Output
module.

=head1 CONTRIBUTING

L<https://github.com/jbarrett/Audio-SunVox-FFI>

All comments and contributions welcome.

=head1 BUGS AND SUPPORT

Please direct all requests to L<https://github.com/jbarrett/Audio-SunVox-FFI/issues>

=head1 ACKNOWLEDGEMENTS

Powered by SunVox (modular synth & tracker),
Copyright (c) 2008 - 2024, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru

=head1 AUTHOR

John Barrett <john@jbrt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by John Barrett.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
