package Acme::Beatnik;

use Filter::Simple;
use strict;
use vars qw($VERSION $ip @stack @numbers %reftable %scrabble $debug);

$debug = 0;

%reftable = 
 (5, \&_push,
  6, \&_pop,
  7, \&_add,
  8, \&_input,
  9, \&_output,
  10, \&_subtract,
  11, \&_swap,
  12, \&_duplicate,
  13, \&_jump_forward_if_zero,
  14, \&_jump_forward_if_not_zero,
  15, \&_jump_back_if_zero,
  16, \&_jump_back_if_not_zero,
  17, \&_halt
 );

%scrabble = 
('A',1,'B',3,'C',3,'D',2,'E',1,'F',4,'G',2,'H',4,'I',1,'J',8,'K',5,'L',1,'M',3,'N',1,'O',1,'P',3,'Q',10,'R',1,'S',1,'T',1,'U',1,'V',4,'W',4,'X',8,'Y',4,'Z',10);

$VERSION = '0.02';

sub _push
{ $ip++;
  print "pushing $numbers[$ip]\n" if $debug;
  push(@stack,$numbers[$ip]);
}

sub _pop
{ my $foo = pop @stack;
  print "popping $foo\n" if $debug;
  return $foo;
}

sub _add
{ my($first,$second) = (pop @stack,pop @stack);
  my $sum = $first + $second;
  push(@stack,$sum);
  print "adding $first and $second and pushing $sum on stack \n" if $debug;
}

sub _input
{ print "accepting user input and pushing onto stack\n" if $debug;
  push(@stack,ord(getc));
}

sub _output
{ my $foo = pop @stack;
  print "outputting ",chr($foo),"\n" if $debug;
  print(chr($foo));
}

sub _subtract
{ my ($first,$second) = (pop @stack,pop @stack);
  my $diff = $first - $second;
  print "subtraction $first and $second and pushing $diff on stack\n" if $debug;
  push(@stack,$diff)
}

sub _swap
{ my $a = pop(@stack);
  my $b = pop(@stack);
  print "swapping $a and $b\n"if $debug;
  push(@stack,$a,$b);
}

sub _duplicate
{ print "duplicating $stack[$#stack]\n" if $debug;
  push(@stack,$stack[$#stack]);
}

sub _jump_forward_if_zero
{ my $n = pop(@stack);
  $ip++;
  if($n == 0)
  { $ip += $numbers[$ip]; print "jump $n words forward\n" if $debug; }
}

sub _jump_forward_if_not_zero
{ my $n = pop(@stack);
  $ip++;
  if($n != 0)
  { $ip += $numbers[$ip]; print "jump $n words forward\n" if $debug; }
}

sub _jump_back_if_zero
{ my $n = pop(@stack);
  $ip++;
  if($n == 0) { $ip -= $numbers[$ip]; print "jump $n words backward\n" if $debug; }
}

sub _jump_back_if_not_zero
{ my $n = pop(@stack);
  $ip++;
  if($n != 0) { $ip -= $numbers[$ip]; print "jump $n words backward\n" if $debug; }
}
 
sub _halt
{ $ip = $#numbers+1;
  print "halting...\n" if $debug;
  exit;
}

FILTER
{ $_ =~ s/[^\w\s]//g;
  my @words = split(/\s+/,$_);
  for my $word (@words)
  { my $number = 0;
    for(split(//,$word))
    { $number += $scrabble{uc $_}; }
    push(@numbers,$number);
  }
  for($ip = 0; $ip <= $#numbers ; $ip++)
  { if (exists( $reftable{$numbers[$ip]} ) )
    { &{ $reftable{$numbers[$ip]} }; }
  }
}

1;
__END__
=head1 NAME

Acme::Beatnik - Source Filter to implement the Beatnik language

=head1 SYNOPSIS

  use Acme::Beatnik;
  blah blah blah

=head1 ABSTRACT

The Beatnik language is a based on scrabble word values. Each value points to a different instruction.
The language is stack based and has a rather reduced instruction set.

=head1 DESCRIPTION

Beatnik is an esoteric programming language based on scrabble word values in the code.
Each word value is linked to a certain instruction. The number of instructions is limited
since there are only a certain number of values possible in Scrabble. Beatnik is a stack based
programming language.

=head1 INSTRUCTION TABLE

Beatnik has the following word values linked to the instructions.

  5   Push the next word value onto stack
  6   Pop the first value from stack
  7   Add the two topmost values from stack and push the result on stack
  8   Read a character from input and push the ASCII value on stack
  9   Read the first value from stack and print the character value
  10  Subtract the two topmost values from stack and push the result back on stack
  11  Swap the two topmost values from stack
  12  Duplicate the first value from stack and push it onto stack
  13  Move the Instruction Pointer X values forward if the first value on stack is zero (X being the next word value)
  14  Move the Instruction Pointer X values forward if the first value on stack is not zero (X being the next word value)
  15  Move the Instruction Pointer X values backward if the first value on stack is zero (X being the next word value)
  16  Move the Instruction Pointer X values backward if the first value on stack is not zero (X being the next word value)
  17  Halt the program

=head1 ENGLISH TILESET

Since Scrabble has different letter values for different countries, there is a problem. Acme::Beatnik uses the English based tileset.
Future versions might include the possibility to have other tilesets as well.

 A=1  B=3  C=3  D=2  E=1  F=4  G=2  H=4  I=1  J=8  K=5  L=1  M=3  N=1  O=1  P=3  Q=10  R=1  S=1  T=1  U=1  V=4  W=4  X=8  Y=4  Z=10

=head1 EXAMPLE

  use Acme::Beatnik
  Foo Bar Baz

Foo has word value 6, Bar has word value 5, Baz has word value 14. This does the following..

  Pop the first value from stack
  Push 14 on stack

=head1 AUTHOR

Hendrik Van Belleghem, E<lt>hendrik@ldl48.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Hendrik Van Belleghem

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
