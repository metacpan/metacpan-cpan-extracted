#!/usr/bin/perl
use strict;
use warnings;
use FindBin;  use lib "$FindBin::Bin/../lib";
use Data::BitStream::XS;

sub string_of {
  my $encoding = lc shift;
  my $p;  $p = $1 if $encoding =~ s/\((.+)\)$//;
  my $d = shift;
  my $stream = Data::BitStream::XS->new;
  if    ($encoding eq 'unary')  { $stream->put_unary($d);    }
  elsif ($encoding eq 'gamma')  { $stream->put_gamma($d);    }
  elsif ($encoding eq 'delta')  { $stream->put_delta($d);    }
  elsif ($encoding eq 'omega')  { $stream->put_omega($d);    }
  elsif ($encoding eq 'fib')    { $stream->put_fib($d);      }
  elsif ($encoding eq 'fibc2')  { $stream->put_fib_c2($d);   }
  elsif ($encoding eq 'lev')    { $stream->put_levenstein($d);     }
  elsif ($encoding eq 'g1')     { $stream->put_goldbach_g1($d);     }
  elsif ($encoding eq 'g2')     { $stream->put_goldbach_g2($d);     }
  elsif ($encoding =~ /btaboo/) { $stream->put_blocktaboo($p, $d); }
  elsif ($encoding =~ /bvzeta/) { $stream->put_boldivigna($p, $d); }
  elsif ($encoding =~ /baer/)   { $stream->put_baer($p, $d); }
  elsif ($encoding =~ /escape/) { $stream->put_escape([split('-',$p)],$d); }
  elsif ($encoding =~ /sss/)    {$stream->put_startstepstop([split('-',$p)],$d)}
  elsif ($encoding =~ /ss/)     { $stream->put_startstop([split('-',$p)],$d); }
  elsif ($encoding =~ /eg/)     { $stream->put_expgolomb($p, $d);  }
  elsif ($encoding =~ /gol/)    { $stream->put_golomb($p, $d);     }
  elsif ($encoding =~ /rice/)   { $stream->put_rice($p, $d);       }
  else  { die "Unknown encoding: $encoding"; }
  my $str = $stream->to_string();
  $str;
}

if (1) {
  my @encodings = qw|Gamma Delta Omega Fib Lev|;
  printf "%5s  " . (" %-11s" x scalar @encodings) . "\n", 'N', @encodings;
  printf "%5s  ", '-' x 5;
  printf " %-11s", '-' x 11 for (@encodings);
  print "\n";
  foreach my $n (0 .. 20) {
  #foreach my $n (0..16, 99, 999, 999_999) {
    printf "%5d  ", $n;
    foreach my $encoding (@encodings) {
      my $str = string_of($encoding, $n);
      printf " %-11s", $str;
    }
    print "\n";
  }
}
