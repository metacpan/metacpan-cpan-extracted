# SYNOPSIS

```perl
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
    sv_send_event( $slot, 0, 50, 127, $generator + 1 );
    sleep(1);
    
    # Save the patch
    sv_save( $slot, 'awesome_patch.sunvox' )
    
    # Clean up
    sv_close_slot( 0 );
    sv_deinit;
```

# DESCRIPTION

[SunVox](https://warmplace.ru/soft/sunvox/) is a modular synthesizer with pattern-based
sequencer (tracker). [The SunVox library](https://warmplace.ru/soft/sunvox/sunvox_lib.php)
is a free library offering access to the facilities offered by SunVox, minus the frontend,
allowing for real-time control of sequences and playback.

This module offers a binding to the SunVox library.

# CONTRIBUTING

[https://github.com/jbarrett/Audio-SunVox-FFI](https://github.com/jbarrett/Audio-SunVox-FFI)

All comments and contributions welcome.

# BUGS AND SUPPORT

Please direct all requests to [https://github.com/jbarrett/Audio-SunVox-FFI/issues](https://github.com/jbarrett/Audio-SunVox-FFI/issues)

# ACKNOWLEDGEMENTS

Powered by SunVox (modular synth & tracker)
Copyright (c) 2008 - 2024, Alexander Zolotov <nightradio@gmail.com>, WarmPlace.ru
