#! perl

use strict;
use warnings;

BEGIN {
  eval "use Smart::Comments;";
}

use Algorithm::RabinKarp;
use Algorithm::RabinKarp::Util qw(filter_regexp stream_fh);

use File::Find::Rule;
use IO::Handle;
use Fcntl qw(:seek);

my @rec;

my %occurances;
my $rule = File::Find::Rule->new;
my @files = $rule->or($rule->new
                             ->directory
                             ->name(qr/(blib6?|inc)/)
                             ->prune
                             ->discard, 
                        $rule->new->file->name(shift @ARGV))->in(@ARGV);
                        
for my $file ( @files ) { ### Hashing ===[%]     done
   open my $fh, '<', $file;

  my $kgram = Algorithm::RabinKarp->new( 80, filter_regexp( qr/[\s;#]/, stream_fh($fh) ) );

  # Create hash data for each kgram inside the document
  while (my ($hash, @pos) = $kgram->next) {
    $occurances{$hash}++;
    push @rec, [$hash, $file, @pos];
  }
  close $fh;
}

use constant HASH       => 0;
use constant FILE       => 1;
use constant HASH_START => 2; 
use constant HASH_END   => 3; 
use constant KGRAMS     => 4;

@rec  = sort {        $a->[FILE]  cmp $b->[FILE] 
              or $a->[HASH_START] <=> $b->[HASH_START] } 
        grep{ $occurances{ $_->[HASH] } > 1 }  # at least one appearance.
        @rec;

# If the previous line has the same count and same file, and
# the start of the next line is before the end of the previous line
# merge them together.
my @newrec = shift @rec; # enforce invariant that there is always a previous
                         # element
for my $curr (@rec) { ### Joining ranges ===[%]      done
  my $prev = $newrec[-1] or die "Something evil has happened";
  if ($occurances{ $curr->[HASH] } == $occurances{ $prev->[HASH] }
      && $curr->[FILE]             eq $prev->[FILE]
      && $curr->[HASH_START]       <= $prev->[HASH_END] 
  ) {
    $prev->[HASH_END] = $curr->[HASH_END];
  } else {
    push @newrec, $curr;
  }
}

my %chunks;
my $last = '';
sub dumpit {
    for my $text (keys %chunks) {
      my @files = keys %{ $chunks{$text} };
      next unless @files > 1;
      print "====\n";
      for my $file ( @files) {
        for my $pos (@{ $chunks{$text}{$file} }) {
          print "  $file lines ".$pos->[0][-1].':'.$pos->[1][-1]."\n";
        }
      }
      print ">>>>\n$text\n----\n";
    }
    %chunks = ();
}

for my $rec (sort {  
                     $occurances{ $b->[HASH] } <=> $occurances{ $a->[HASH] }
                  or $a->[HASH]                <=> $b->[HASH]
                  or span($b)                  <=> span($a)
                 } @newrec) { ### Emitting Report ===[%]       done
  my ($hash, $file_name, $start_offset, $end_offset, $s, $e) = @$rec;
  dumpit() if ($last ne $hash);
  $last = $hash;
  push @{ $chunks{emit_fragment($file_name,$start_offset,$end_offset)}{$file_name}}, [$s,$e];
}
dumpit();

sub span {
  my $rec = shift;
  $rec->[HASH_END] - $rec->[HASH_START] + 1
}

use Fcntl qw(SEEK_SET);

sub emit_fragment {
  my ($file, $start, $end) = @_;
  open(my $fh, '<', $file)
    or die "Can't open $file: $!";
  my $bytes = $end - $start + 1;
  my $buf;
  seek($fh, $start, SEEK_SET);
  read $fh, $buf, $bytes;
  close $fh;
  return $buf;
}

sub hash {
  my $val = shift;

  return {
  COUNT => $occurances{ $val->[HASH] },
  FILE => $val->[FILE],
  HASH_START => $val->[HASH_START],
  HASH_END => $val->[HASH_END],
  };
}

