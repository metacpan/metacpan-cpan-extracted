
package Musicgene;
use strict;
use warnings;
use MIDI::Simple;

BEGIN {
  use Exporter   ();
  use AI::Gene::Sequence;
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION     = 0.01;
  @ISA         = qw(Exporter AI::Gene::Sequence);
  @EXPORT      = ();
  %EXPORT_TAGS = ();
  @EXPORT_OK   = qw();
}
our @EXPORT_OK;

our @chords = ([qw(A C G)], [qw(A C E)]);       # type c
our @octaves = (3..10);                         # type o
our @notes = ('A'..'G', 'rest');                # type n
our @lengths = (qw(hn qn), '');                 # type l

sub new {
  my $class = shift;
  my $self = ['',[]];
  bless $self, ref($class) || $class;
  $self->mutate_insert($_[0]) if $_[0];
  return $self;
}

sub generate_token {
  my $self = shift;
  my ($type, $prev) = @_[0,1];
  my @rt;
  unless ($type) {
    my $rand = rand;
    if    ($rand < .7) {$type = 'n'}
    elsif ($rand < .8) {$type = 'l'}
    elsif ($rand < .9) {$type = 'o'}
    elsif ($rand < 1 ) {$type = 'c'}
    else {die "$0: bad probability: $rand"}
  }
  $rt[0] = $type;
 SWITCH: for ($type) {
    /n/ && do {$rt[1] = $notes[rand@notes]; last SWITCH};
    /c/ && do {$rt[1] = $chords[rand@chords]; last SWITCH};
    /l/ && do {$rt[1] = $lengths[rand@lengths]; last SWITCH};
    /o/ && do {$rt[1] = $octaves[rand@octaves]; last SWITCH};
    die "$0: unknown type: $type";
  }
  return @rt[0,1];
}

sub valid_gene {length($_[1]) < 50 ? 1 : 0};

sub write_file {
  my $self = shift;
  my $file_name = $_[0] or die "$0: No file passed to write_file";
  my $opus = MIDI::Simple->new_score();
  my $note_length = '';
  foreach my $pos (0..(length $self->[0])) {
  SWITCH: for (substr($self->[0], $pos, 1)) {
      /l/ && do {$note_length = $self->[1][$pos]             ;last SWITCH};
      /n/ && do {$opus->n($note_length, $self->[1][$pos])    ;last SWITCH};
      /o/ && do {$opus->noop('o'.$self->[1][$pos])           ;last SWITCH};
      /c/ && do {$opus->n($note_length, @{$self->[1][$pos]}) ;last SWITCH};
    }
  }

  $opus->write_score($file_name);
  return;
}

## Also override mutation method
# calls mutation method at random
# 0: number of mutations to perform
# 1: ref to hash of probs to use (otherwise uses default mutations and probs)
my %probs = (
	     insert    =>.1,
	     remove    =>.2,
	     duplicate =>.4,
	     minor     =>.5,
	     major     =>.6,
	     overwrite =>.7,
	     reverse   =>.75,
	     switch    =>.8,
	     shuffle   =>1,
	    );

sub mutate {
  my $self = shift;
  my $num_mutates = +$_[0] || 1;
  my $rt = 0;
  my ($hr_probs, $muts);
  if (ref $_[1] eq 'HASH') { # use non standard mutations or probs
    $hr_probs = $self->_normalise($_[1]);
    $muts = [keys %{$hr_probs}];
  MUT_CYCLE: for (1..$num_mutates) {
      my $rand = rand;
      foreach my $mutation (@{$muts}) {
	next unless $rand < $hr_probs->{$mutation};
	$rt += eval "\$self->mutate_$mutation(1)";
	next MUT_CYCLE;
      }
    } 
  }
  else {                     # use standard mutations and probs
    foreach (1..$num_mutates) {
      my $rand = rand;
      if ($rand < $probs{insert}) {
	$rt += $self->mutate_insert(1);
      }      
      elsif ($rand < $probs{remove}) {
	$rt += $self->mutate_remove(1);
      }
      elsif ($rand < $probs{duplicate}) {
	$rt += $self->mutate_duplicate(1,undef, undef,0); # random length
      }
      elsif ($rand < $probs{minor}) {
	$rt += $self->mutate_minor(1);
      }
      elsif ($rand < $probs{major}) {
	$rt += $self->mutate_major(1);
      }
      elsif ($rand < $probs{overwrite}) {
	$rt += $self->mutate_overwrite(1,undef,undef,0);
      }
      elsif ($rand < $probs{switch}) {
	$rt += $self->mutate_switch(1,undef,undef,0,0);
      }
      elsif ($rand < $probs{shuffle} ) {
	$rt += $self->mutate_shuffle(1,undef,undef,0);
      }
    }
  }


  return $rt;
}

1;
