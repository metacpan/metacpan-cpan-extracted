# p5-Audio-Play-Native

## SYNOPSIS

```perl
use Audio::Play::Native;

# Asynchronous non-blocking playback
Audio::Play::Native->play('explosion.wav');

# Synchronous blocking playback
Audio::Play::Native->play('intro.wav', async => 0);

# Query active backend
print "Using backend: " . Audio::Play::Native->detected_backend . "\n";
```
    
## DESCRIPTION

Audio::Play::Native provides cross-platform audio playback for Perl. It does this by attempting to find and use available audio player tools to play the specified WAV file.

### Linux

Will try to use PipeWire (pw-play), PulseAudio (paplay), ALSA (aplay), SoX (play), and FFplay (ffplay).

### Windows

Will try to use Win32::Sound and PowerShell.

### macOS

Will try to use afplay.

## AI

This module was developed with assistance from Gemini Flash 3.8.

## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

