package Acme::Undead;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

  Acme::Undead - The Undead is not die!

=head1 SYNOPSIS

  use Acme::Undead;
  die('undead is not die');
  print 'Hell world';

  #Hell world

  no Acme::Undead;

  die() #died;

=head1 DESCRIPTION

  Acme::Undead is export routines, die(), bless() and sleep().
  Use Acme::Undead when dont die at die(), die at bless() and not sleep at sleep().

=head1 OVERRIDE METHODS

=head2 die

  undead is not die!

=head2 sleep

  undead is not sleeping

=head2 bless

  the god bless clean undead auras.

=cut

our @EXPORT  = qw/die sleep bless/;
our $IS_UNDEAD = 0;

sub import {
  my $class = shift;
  my $caller = shift;
  $^H{acme_undead} = 1;
  $IS_UNDEAD = 1;
  {
    no strict 'refs';
    no warnings;
    for my $func (@EXPORT) {
      my $local_func = "_" . $func;
      *{"${caller}::$func"} = *{"Acme::Undead::$local_func"};
    }
  }
}

sub unimport {
  $^H{acme_undead} = 0;
  $IS_UNDEAD = 0;
}

sub _die {
  my $class    = shift;
  my $hinthash = (caller(0))[10];
  return $hinthash->{acme_undead} ? undef : die(shift);
}

sub _sleep {
  my $hinthash = (caller(0))[10];
  return $hinthash->{acme_undead} ? undef : sleep(shift);
}

sub _bless {
  my $hinthash = (caller(0))[10];
  return $hinthash->{acme_undead} ? die('blessed') : do {
    my $arg = shift;
    my $pkg = shift;
    bless($arg, $pkg);
  }
}

sub END {
  return unless $IS_UNDEAD;
  my @signals = keys %SIG;
  my $pid = fork();
  if ($pid){
    local %SIG;
    for my $sig (@signals){
      $SIG{$sig} = sub {
        warn 'undead is die';
      };
    }
    $SIG{USR1} = sub {
      $IS_UNDEAD = 0;
    };
    while($IS_UNDEAD){ sleep 1; }
  }
  else {
    exit;
  }
}

1;
__END__

=head1 LICENSE

Copyright (C) likkradyus.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  likkradyus E<lt>perl {at} li {dot} que {dot} jpE<gt>

=cut
