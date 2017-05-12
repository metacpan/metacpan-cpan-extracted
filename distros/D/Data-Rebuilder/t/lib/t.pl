package main;
use strict;
use warnings;
use Data::Rebuilder;
use Path::Class;
require lib;

sub dumpsrc($) {
  my $src =shift;
  my $c = 1;
  $src =~ s/^/sprintf('#% 3d:',$c++)/emg;
  print "$src\n";
}

sub Data::Rebuilder::_t {
  my $b = shift;
  my $a = shift;
  my $icy = $b->rebuilder($a);
  dumpsrc $icy;
  my $code = eval($icy);
  return $code->(@_) unless $@;
  print $@;
}

sub init {
  strict->import();
  warnings->import();
  lib->import( file(file(__FILE__)->dir )->stringify );
}


1
__END__
