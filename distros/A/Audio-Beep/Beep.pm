package Audio::Beep;

$Audio::Beep::VERSION = 0.11;

use strict;
use Carp;
use Exporter;
use vars qw(%NOTES @PITCH @EXPORT @EXPORT_OK @ISA);
@ISA        = qw(Exporter);
@EXPORT     = qw(beep);
@EXPORT_OK  = qw(beep);


### GLOBALS

%NOTES = (
    c   =>  0,
    d   =>  2,
    e   =>  4,
    f   =>  5,
    g   =>  7,
    a   =>  9,
    b   =>  11,
);

@PITCH = (
    261.6, 277.2, 
    293.6, 311.1, 
    329.6, 
    349.2, 370.0, 
    392.0, 415.3, 
    440.0, 466.1,
    493.8,
);


### OO METHODS

sub new {
    my $class = shift;
    carp "Odd number of parameters where hash expected" if @_ % 2 and $^W;
    my (%h) = @_;
    if ( $h{player} ) {
        $h{player} = _player_from_string( $h{player} ) unless ref $h{player};
    } else {
        $h{player} =  _best_player();
    }
    carp "No player found. You should specify one before playing anything." 
        unless $h{player};
    return bless \%h, $class;
}

sub player {
    my $self = shift;
    my ($player) = @_;
    $self->{player} = ref $player ? $player : _player_from_string($player) 
                                                                    if $player;
    return $self->{player};
}

sub rest {
    my $self = shift;
    my ($rest) = @_;
    $self->{rest} = $rest if defined $rest;
    return $self->{rest};
}

sub play {
    my $self = shift;
    my ($music) = @_;
    
    my %p = (
        note        =>  'c',
        duration    =>  4,
        octave      =>  0,
        bpm         =>  120,
        pitch_mod   =>  0,
        dot         =>  0,
        relative    =>  1,
        transpose   =>  0,
    );
    
    while ($music =~ /\G(?:([^\s#]+)\s*|#[^\n]*\n|\s*)/g) { 
        local $_ = $1 or next;
        
        if ( /^\\(.+)/ ) {
            COMMAND: {
                local $_ = $1;
                /^(?:bpm|tempo)(\d+)/   and do {$p{bpm} = $1; last};
                /^rel/                  and do {$p{relative} = 1; last};
                /^norel/                and do {$p{relative} = 0; last};
                /^transpose([',]+)/     and do {
                    local $_ = $1;
                    $p{transpose} = tr/'/'/ - tr/,/,/;
                    last;
                };
                carp qq|Command "$_" is unparsable\n| if $^W;
            }
            next;
        }
        
        my ($note, $mod, $octave, $dur, $dot) = 
            /^\W*([cdefgabr])(is|es|s)?([',]+)?(\d+)?(\.+)?\W*$/;
        
        unless ($note) {
            carp qq|Note "$_" is unparsable\n| if $^W;
            next;
        }
        
        $p{duration} = $dur if $dur;

        $p{dot} = 0;
        do{ $p{dot} += tr/././ for $dot } if $dot;
        
        if ( $note eq 'r' ) {
            $self->player->rest( _duration(\%p) );
        } else {
            if ( $p{relative} ) {
                my $diff = $NOTES{ $p{note} } - $NOTES{ $note };
                $p{octave} += $diff < 0 ? -1 : 1 if abs $diff > 5;
            } else {
                $p{octave} = $p{transpose};
            }
        
            do{ $p{octave} += tr/'/'/ - tr/,/,/ for $octave } if $octave;
        
            $p{pitch_mod} = 0;
            $p{pitch_mod} = $mod eq 'is' ? 1 : -1 if $mod;
        
            $p{note} = $note;
            $self->player->play( _pitch(\%p), _duration(\%p) );
        }
        
        select undef, undef, undef, $self->{rest} / 1000 if $self->{rest};
    }
}


### UTILITIES

sub _pitch {
    my $p = shift;
    return $PITCH[($NOTES{ $p->{note} } + $p->{pitch_mod}) % 12] * 
            (2 ** $p->{octave});
}

sub _duration {
    my $p = shift;
    my $dur = 4 / $p->{duration};
    if ( $p->{dot} ) {
        my $half = $dur / 2;
        for (my $i = $p->{dot}; $i--; ) {
            $dur  += $half;
            $half /= 2;
        }
    }
    return int( $dur * (60 / $p->{bpm}) * 1000 );
}

sub _best_player {
    my %os_modules = (
        linux   =>  [
            'Audio::Beep::Linux::beep',
            'Audio::Beep::Linux::PP',
        ],
        MSWin32   =>  [
            'Audio::Beep::Win32::API',
        ],
        freebsd =>  [
            'Audio::Beep::BSD::beep',
        ],
    );
    
    for my $mod ( @{ $os_modules{$^O} } ) {
        if (eval "require $mod") {
            my $player = $mod->new();
            return $player if defined $player;
        }
    }

    return;
}

sub _player_from_string {
    my ($mod) = @_;
    my $pack = __PACKAGE__;
    $mod =~ s/^(${pack}::)?/${pack}::/;
    eval "require $mod" or croak "Cannot load $mod : $@";
    return $mod->new();
}


### EXPORTED FUNCTIONS

{ #SCOPE FOR CACHED PLAYER

my $player;

sub beep {
    my ($pitch, $duration) = @_;
    $pitch      ||= 440;
    $duration   ||= 100;
    $player ||= _best_player() or croak "Couldn't find a working player";
    $player->play($pitch, $duration);
}

}

1;
