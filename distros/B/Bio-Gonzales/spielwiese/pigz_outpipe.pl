#!/usr/bin/env perl
# created on 2013-11-11

use warnings;
use strict;
use 5.010;

my @data = ( 'A' .. 'Z' );
my $fh   = opengz('/tmp/test.gz');
for my $d (@data) {
  say $fh $d;
  say "ERROR";
  say STDERR "ERROR";

}
sleep 3;
close $fh;

sub opengz {
  my $f = shift;

  my ( $r, $w );

  pipe( $r, $w ) || die "pipe failed: $!";
  my $pid = fork();
  defined($pid) || die "first fork failed: $!";
  if ($pid) {
    close $r;
    return $w;
  } else {
    open( STDIN, "<&", $r ) || die "can't reopen STDIN: $!";
    close($w) || die "can't close WRITER: $!";
    open STDOUT, '>', $f or die "Can't open filehandle: $!";
    exec( 'pigz', '-c' );
    exit(0);
  }
}
