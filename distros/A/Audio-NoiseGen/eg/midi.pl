#!/usr/bin/env perl

use v5.14;
use Audio::NoiseGen ':all';
    
use MIDI::ALSA qw(
  SND_SEQ_EVENT_PORT_UNSUBSCRIBED
  SND_SEQ_EVENT_NOTEON
  SND_SEQ_EVENT_NOTEOFF
);

use Music::Note;

init();

MIDI::ALSA::client('Perl MIDI::ALSA client', 1, 1, 0);
MIDI::ALSA::connectfrom(0, 20, 0) or die "Can't connect: $!";
MIDI::ALSA::start() or die "Can't start: $!";

sub midiplay {
  my (%params) = gen_params(@_);
}

while (1) {
    my @alsaevent = MIDI::ALSA::input();

    my @data = @{$alsaevent[7]};

    if ($alsaevent[0] == SND_SEQ_EVENT_PORT_UNSUBSCRIBED()) {
        last;
    }
    elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEOFF()
        || ($alsaevent[0] == SND_SEQ_EVENT_NOTEON && !$data[2]))
    {
        # ... just ignore the key being released ...
    }
    elsif ($alsaevent[0] == SND_SEQ_EVENT_NOTEON()) {
        my $channel = $data[0];
        my $pitch   = $data[1];
        my $key     = $channel * 128 + $pitch;

        print "midi $key\n";

        my $note = Music::Note->new( $key, 'midinum' )->format('iso');
        print "note: [$note]\n";

        play( gen => segment( notes => $note ) );

        # play gens => [
          # segment( note => $note)
        # ];

        print "Played!\n";

    }
}


