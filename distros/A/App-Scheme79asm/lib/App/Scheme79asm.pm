package App::Scheme79asm;

use 5.014000;
use strict;
use warnings;

use Data::SExpression qw/consp scalarp/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '0.001';

our %TYPES = (
	LIST => 0,
	SYMBOL => 1,
	VAR => 2,
	VARIABLE => 2,
	CLOSURE => 3,
	PROC => 4,
	PROCEDURE => 4,
	COND => 5,
	CONDITIONAL => 5,
	CALL => 6,
	FUNCALL => 6,
	QUOTE => 7,
	QUOTED => 7,
);

*consp = *Data::SExpression::consp;
*scalarp = *Data::SExpression::scalarp;

sub process {
	my ($self, $sexp) = @_;
	die "Toplevel is not a cons: $sexp\n " unless consp($sexp);
	my $type = $sexp->car;
	my $addr = $sexp->cdr;

	die "Type of toplevel is not atom: $type\n" unless scalarp($type);
	$addr = $self->process($addr) if consp($addr);
	die "Addr of toplevel is not atom: $addr\n" unless scalarp($addr);

	die "Computed addr is not a number: $addr\n" unless looks_like_number $addr;

	if (ref $type eq 'Data::SExpression::Symbol') {
		die "No such type: $type\n" unless exists $TYPES{$type};
		$type = $TYPES{$type};
	} elsif (!looks_like_number $type) {
		die "Type is not a number or symbol: $type\n"
	}

	die "Type too large: $type\n" unless $type < (1 << $self->{type_bits});
	die "Addr too large: $addr\n" unless $addr < (1 << $self->{addr_bits});
	my $result = ($type << $self->{addr_bits}) + $addr;
	$self->{freeptr}++;
	$self->{memory}[$self->{freeptr}] = $result;
	$self->{freeptr}
}

sub parse {
	my ($self, $string) = @_;
	my $ds = Data::SExpression->new({symbol_case => 'up', use_symbol_class => 1, fold_lists => 0});

	my $sexp;
	while () {
		last if $string =~ /^\s*$/;
		($sexp, $string) = $ds->read($string);
		$self->process($sexp)
	}
}

sub finish {
	my ($self) = @_;
	$self->{memory}[5] = $self->{memory}[$self->{freeptr}];
	$self->{memory}[4] = $self->{freeptr};
	delete $self->{memory}[$self->{freeptr}]
}

sub new {
	my ($class, %args) = @_;
	$args{type_bits} //= 3;
	$args{addr_bits} //= 8;
	$args{freeptr} //= 6;
	$args{memory} //= [0, 0, (1<<$args{addr_bits}), (1<<$args{addr_bits}), 0, 0, 0];
	bless \%args, $class
}

sub print {
	my ($self, $fh) = @_;
	$fh //= \*STDOUT;

	my $bits = $self->{type_bits} + $self->{addr_bits};
	for my $index (0 .. $#{$self->{memory}}) {
		my $val = $self->{memory}[$index];
		if ($index == 4) {
			$val = "${bits}'d$val"
		} else {
			$val = $val ? sprintf "%d'b%0${bits}b", $bits, $val : '0';
		}
		say $fh "mem[$index] <= $val;"
	}
}

sub parse_and_print {
	my ($self, $string, $fh) = @_;
	$self->parse($string);
	$self->finish;
	$self->print($fh);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Scheme79asm - assemble sexp to Verilog ROM for SIMPLE processor

=head1 SYNOPSIS

  use App::Scheme79asm;
  my $asm = App::Scheme79asm->new(type_bits => 3, addr_bits => 5);
  $asm->parse_and_print('(number . 70)');

=head1 DESCRIPTION

B<NOTE:> this module does not do much at the moment.

SIMPLE is a LISP processor defined in the 1979
B<Design of LISP-Based Processors> paper by Steele and Sussman.

The SIMPLE processor expects input in a particular tagged-pointer
format. This module takes a string containing a sequence of
S-expressions of the form C<(tag . value)> representing a tagged
pointer. Here the tag is either a number or one of several predefined
values (see the source for a full list), and the value is either a
number or another tagged pointer. These values are laid out in memory
and a block of verilog code assigning the memory contents to an array
named C<mem> is printed.

More documentation and features to follow.

=head1 SEE ALSO

L<http://repository.readscheme.org/ftp/papers/ai-lab-pubs/AIM-514.pdf>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
