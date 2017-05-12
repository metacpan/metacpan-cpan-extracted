package Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker;
$Bot::Cobalt::Plugin::RDB::AsyncSearch::Worker::VERSION = '0.021003';
use strict; use warnings;

use Storable ();

use bytes;

use Bot::Cobalt::DB;

sub worker {
  binmode STDOUT;
  binmode STDIN;
  
  select(STDOUT);
  $|++;
  
  my $buf = '';
  my $read_bytes;
  
  while (1) {
    if (defined $read_bytes) {
      if (length $buf >= $read_bytes) {
        my $input = Storable::thaw( substr($buf, 0, $read_bytes, '') );
        $read_bytes = undef;
        my ($dbpath, $tag, $regex) = @$input;

        my $db = Bot::Cobalt::DB->new($dbpath);

        $SIG{$_} = sub {
          $db->dbclose if $db->is_open;
          die "Terminal signal, closed cleanly"
        } for qw/INT TERM QUIT HUP/;

        die "Failed database open" 
          unless $db->dbopen(ro => 1, timeout => 30);

        $regex = qr/$regex/i;
        my @matches;
        KEY: while (my ($dbkey, $ref) = each %{ $db->Tied }) {
          next KEY unless $ref;
          my $str = ref $ref eq 'HASH' ? $ref->{String} : $ref->[0] ;
          push @matches, $dbkey if $str =~ $regex;
        }
        
        $db->dbclose;

        ## Return:
        ##  - DB path
        ##  - Unique ID
        ##  - List of matching item IDs
        my $frozen = Storable::nfreeze( [ $dbpath, $tag, @matches ] );
        my $stream  = length($frozen) . chr(0) . $frozen ;
        my $written = syswrite(STDOUT, $stream);
        die $! unless $written == length $stream;
        exit 0
      }
    } elsif ($buf =~ s/^(\d+)\0//) {
      $read_bytes = $1;
      next
    }

    my $readb = sysread(STDIN, $buf, 4096, length $buf);
    last unless $readb;
  }
  
  exit 0
}

1;
