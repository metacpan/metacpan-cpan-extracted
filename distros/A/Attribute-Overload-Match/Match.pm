# $Id: Match.pm,v 1.1.1.1 2007/02/28 11:49:47 dk Exp $

package Attribute::Overload::Match;

use strict;
use warnings;
use Attribute::Handlers;
our ( %ops, $VERSION);
$VERSION = '0.01';

sub handle
{
	my ( $pkg, $op) = ( shift, shift );
	NEXTARG: for my $arg ( @{$ops{$pkg}{$op}}) {
		my $sym = $$arg[0];
		next if $#$arg > @_;
		for ( my $x = 1; $x < @$arg; $x++) {
			next NEXTARG unless $arg-> [$x]->( $_[$x - 1]);
		}
		goto $sym;

	}
	die "Nothing matches $op in $pkg";
	
}

sub parse
{
	my @r;
	for my $v ( @_) {
		$v =~ s/^\s*//;
		$v =~ s/\s*$//;
		if ( $v eq '') {
			push @r, sub { 1 };
		} elsif ( $v =~ /^\d/) {
			push @r, sub { defined $_[0] and $_[0] == $v };
		} elsif ( $v =~ /^'(.*)'$/ ) {
			$v = $1;
			push @r, sub { defined $_[0] and $_[0] eq $v };
		} elsif ( $v =~ /^[A-Z]/) {
			push @r, sub { defined $_[0] and ref($_[0]) and $_[0]->isa($v) };
		} elsif ( $v eq '//') {
			push @r, sub { defined $_[0] };
		} elsif ( $v =~ /^(<|>|lt|gt|eq|==)\s*(.*)$/) {
			$v = eval "sub { defined \$_[0] and \$_[0] $v ;}";
			die $@ if $@;
			push @r, $v;
		} elsif ( $v =~ /^(ne|!=)\s*(.*)$/) {
			$v = eval "sub { not defined \$_[0] or \$_[0] $v ;}";
			die $@ if $@;
			push @r, $v;
		} else {
			$v = eval "sub { $v }";
			die $@ if $@;
			push @r, $v;
		}
	}
	@r;
}

sub UNIVERSAL::op : ATTR(CODE,RAWDATA) {
	my ($pkg, $sub, $data) = @_[0,2,4];
	require overload;
	my ($op, @arg) = split( ',', $data);
	overload::OVERLOAD( $pkg, $op, sub { handle( $pkg, $op, @_ ) } )
		unless exists $ops{$pkg}{$op};
	push @{$ops{$pkg}{$op}}, [ $sub, parse @arg ];
}

1;

=pod

=head1 NAME

Attribute::Overload::Match - argument-dependent handlers for overloaded operators 

=head1 DESCRIPTION

The module is a wrapper for L<overload>, that provides a simple syntax for
calling different operator handlers for different passed arguments. The idea is
a curious ( but probably not a very practical ) mix of L<Attribute::Overload>
and L<Sub::PatMat> .

=head1 SYNOPSIS

   use Attribute::Overload::Match;

Suppose we declare a class that overloads operations on integers:

   sub new($)               { my $x = $_[0]; bless \$x, __PACKAGE__ }
   sub val($)               { ${$_[0]} }
   sub eq       : op(==)    { val(shift) == shift }
   sub subtract : op(-)     { new val(shift) - shift }
   sub mul      : op(*)     { new val(shift) * shift }
   sub add      : op(+)     { new val(shift) + shift }
   sub qq       : op("")    { val(shift) }
   sub le       : op(<)     { val(shift) < shift }
   ...

then we can change meaning of some operators with a touch of functional style:

   no warnings 'redefine';
   sub fac      : op(!,1)   { new 1 }
   sub fac      : op(!)     { !($_[0] - 1) * $_[0] }

or

   sub fib      : op(~,<2)  { new 1 }
   sub fib      : op(~)     { ~( $_[0] - 1) + ~($_[0] - 2) }

(if you don't like C<no warnings 'redefine'>, just use different sub names for C<fac> etc)
thus

   my $x = !new(10);
   print "$x\n";
   3628800    

and 

   my $x = ~new(10);
   print "$x\n";
   89

=head1 SYNTAX

The only syntax available here is syntax that is passed to C<op> attributes,
which is in general C<sub mysub : op(OPERATOR,CODE[,CODE[,CODE ...]])>, where
C<OPERATOR> belongs to strings defined in L<overload> ( such as C<+>, C<[]>,
C<""> etc), and C<CODE> strings are perl code, matching a parameter. However,
for the sake of readability, C<CODE> can be also one of the following
signatures:

=over

=item Empty string

Parameter is never checked

=item String starting with a digit

Pataremeter must be defined and be equal (C<==>) to the value if the string

=item Single-quoted string

Parameter must be defined and be equal (C<eq>) to the value if the string

=item Non-quoted string beginning with a capital letter

The string defined as a class name. Parameter must be defined and be an instance
of the class (or its descendant).

=item C<//>

Parameter must be defined.

=item One of C<< <,>,lt,gt,eq,==,ne,!= >> followed by an expression

Parameter must be defined and return true when compared with the expression
using given comparison operator

=item Anything else

Anything else is passed directly to C<eval> and is treated in a boolean context
thereafter.

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Anton Berezin for ideas on L<Sub::PatMat> .
Thanks to H. Merijn Brandt for C<//>.

=head1 SEE ALSO

L<Attribute::Overload>, L<Sub::PatMat>, L<overload>.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 AUTHOR

Dmitry Karasik <dmitry@karasik.eu.org>

=cut
