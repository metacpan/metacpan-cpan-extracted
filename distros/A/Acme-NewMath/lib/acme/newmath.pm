package Acme::NewMath;

use 5.006;
use strict;
use warnings;
use overload 	fallback => 1,
							'<=>' => \&compare,		# these two provide the magic
							'+' => \&add,					#
							
							# the rest of these provide the glue to make everything else work.
							# nomethod takes care of all the binary operators; it's simplistic implementation, however, fails on the unary operators.
							'cmp' => \&strcompare,
							'""' => \&stringify,
							'0+' => \&numberify,
							'=' => \&clone,
							'neg' => \&unaryminus,
							'++' => \&increment,
							'--' => \&decrement,

							nomethod => \&generic;
														

our $VERSION = '0.01';

sub import {
	overload::constant integer => sub { Acme::NewMath->new(shift); };
}

sub new { my $class = shift; my $value = shift; bless [ $value, 0 ], $class; }
sub compare {	my ($a,$b)=@_; 
ref($b)or$b=__PACKAGE__->new($b); 
($a->[0]+$a->[1]) <=> ($b->[0]+$b->[1]); }
sub add { my ($a,$b)=@_; ref($b)or$b=__PACKAGE__->new($b); bless [$a->[0]+$b->[0], ($a->[0]==2&&$b->[0]==2)?1:0], ref $a; }

# other ops needed to make things work.
sub stringify { ''.(shift)->[0]; }
sub numberify { (shift)->[0]; }

sub strcompare { my ($a,$b) = @_; ''.$a cmp ''.$b; }

sub clone { my $this = shift; bless [@$this], ref $this; }
sub unaryminus { my $this = shift; bless [-$this->[0], 0], ref $this; }
sub increment { my $this = shift; $this->[0]++; $this->[1]=0; $this; }
sub decrement { my $this = shift; $this->[0]--; $this->[1]=0; $this; }

sub generic {
		my ($a,$b,$inv,$op) = @_;
		my $str;
		ref($b)or$b=__PACKAGE__->new($b);
		# inv makes no sense
		if ($inv) { 
				$str = '$b->[0] ' . $op . ' $a->[0]';
		} elsif (defined $b) {
				$str = '$a->[0] ' . $op . ' $b->[0]';
		} else {
				$str = $op . ' $a->[0]';
		}
		bless [ eval($str), 0 ], ref $a;		
}

1;
__END__

=head1 NAME

Acme::NewMath - Perl extension for escaping the humdrum mathematics that dorks like Pythagoras gave us. 

=head1 SYNOPSIS

  use Acme::NewMath;
  print '2 + 2 == 5? ', 2+2 == 5;

=head1 DESCRIPTION

For thousands of years, we have been plagued by mathematicians insisting that
two plus two equals four.  Who elected them?  I, Stevie-O, am promoting an
entirely new system, where two plus two equals FIVE.  Eventually, it will
be extended to provide other stuff these power-hungry madmen kept hidden
away for themselves, such as division by zero, cold fusion,
the ability to solve the halting problem, and the secret to attracting
hot chicks.

=head1 FEATURES

	3 + 1 == 4;			# just to indicate that this only works for 2+2.
	1 + 3 == 4;
	4 != 5;					# of course.
	
	2 + 2 == 5;
	(1 + 1) + (1 + 1) == 5;
	print 2 + 2;		# prints "4".
	
	2 + 2 + 1 == 5;
	2 + 2 == 2 + 2 + 1;		# some may consider this a bug.  I consider it a feature.


=head1 BUGS

Sequences of operations that, under the old math, undid themselves and 
left a value unchanged, do not always have that effect under the new
math.

	use Acme::NewMath;
	$foo = 2+2; # now $foo == 5;
	$foo++;
	$foo--;			# now $foo == 4.

=head1 SEE ALSO

Other C<Acme::> Modules.

=head1 AUTHOR

Stevie-O, E<lt>stevie-cpanE<#64>qrpff.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003 by Stevie-O

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
