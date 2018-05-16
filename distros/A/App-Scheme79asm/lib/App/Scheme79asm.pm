package App::Scheme79asm;

use 5.014000;
use strict;
use warnings;
use re '/s';
use Carp qw/croak/;

use Data::Dumper qw/Dumper/;
use Data::SExpression qw/consp scalarp/;
use Scalar::Util qw/looks_like_number/;

our $VERSION = '1.000';

our %TYPES = (
	LIST => 0,
	SYMBOL => 1,
	NUMBER => 1,
	VAR => 2,
	VARIABLE => 2,
	CLOSURE => 3,
	PROC => 4,
	PROCEDURE => 4,
	IF => 5,
	COND => 5,
	CONDITIONAL => 5,
	CALL => 6,
	QUOTE => 7,
	QUOTED => 7,

	MORE => 0,
	CAR => 1,
	CDR => 2,
	CONS => 3,
	ATOM => 4,
	PROGN => 5,
	'REVERSE-LIST' => 6,
	FUNCALL => 7,
);

*consp = *Data::SExpression::consp;
*scalarp = *Data::SExpression::scalarp;

sub process {
	my ($self, $sexp, $location) = @_;
	die 'Toplevel is not a list: ', Dumper($sexp), "\n" unless ref $sexp eq 'ARRAY';
	my ($type, @addrs) = @$sexp;
	my $addr;

	die 'Type of toplevel is not atom: '. Dumper($type), "\n" unless scalarp($type);

	if (@addrs > 1) {
		$addr = $self->{freeptr} + 1;
		$self->{freeptr} += @addrs;
		$self->process($addrs[$_], $addr + $_) for 0 .. $#addrs;
	} else {
		$addr = $addrs[0];
	}

	$addr = $self->process($addr) if ref $addr eq 'ARRAY';
	die 'Addr of toplevel is not atom: ', Dumper($addr), "\n" unless scalarp($addr);
	my ($comment_type, $comment_addr) = ($type, $addr);
	die 'Computed addr is not a number: ', Dumper($addr), "\n" unless looks_like_number $addr;

	if (!looks_like_number $type) {
		die "No such type: $type\n" unless exists $TYPES{$type};
		$type = $TYPES{$type};
	}

	$addr += (1 << $self->{addr_bits}) if $addr < 0;
	die "Type too large: $type\n" if $type >= (1 << $self->{type_bits});
	die "Addr too large: $addr\n" if $addr >= (1 << $self->{addr_bits});
	my $result = ($type << $self->{addr_bits}) + $addr;

	unless ($location) {
		$self->{freeptr}++;
		$location = $self->{freeptr}
	}
	$self->{memory}[$location] = $result;
	$self->{comment}[$location] = "$comment_type $comment_addr";
	$location
}

sub parse {
	my ($self, $string) = @_;
	my $ds = Data::SExpression->new({symbol_case => 'up', use_symbol_class => 1, fold_lists => 1});

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
	$self->{comment}[5] = $self->{comment}[$self->{freeptr}];
	$self->{memory}[4] = $self->{freeptr};
	delete $self->{memory}[$self->{freeptr}]
}

sub new {
	my ($class, %args) = @_;
	$args{type_bits} //= 3;
	$args{addr_bits} //= 8;
	$args{freeptr} //= 6;
	$args{memory} //= [0, 0, (1<<$args{addr_bits}), (1<<$args{addr_bits}), 0, 0, 0];
	my @default_comments = ('(cdr part of NIL)', '(car part of NIL)', '(cdr part of T)', '(car part of T)', '(free storage pointer)', '', '(result of computation)');
	for (0 .. $#default_comments) {
		$args{comment}[$_] = $default_comments[$_]
	}
	bless \%args, $class
}

sub print_binary16 {
	my ($self, $fh) = @_;
	$fh //= \*STDOUT; # uncoverable condition right

	die "addr_bits + type_bits >= 16\n"if $self->{addr_bits} + $self->{type_bits} > 16;

	my $length = @{$self->{memory}};
	print $fh pack 'n', $length or croak "Failed to print memory size: $!"; # uncoverable branch true
	for (@{$self->{memory}}) {
		print $fh pack 'n', $_ or croak "Failed to print memory: $!" # uncoverable branch true
	}
}

sub print_verilog {
	my ($self, $fh) = @_;
	$fh //= \*STDOUT; # uncoverable condition right

	my $bits = $self->{type_bits} + $self->{addr_bits};
	my $index_length = length $#{$self->{memory}};
	my $index_format = '%' . $index_length . 'd';
	for my $index (0 .. $#{$self->{memory}}) {
		my $val = $self->{memory}[$index];
		my $comment = $self->{comment}[$index];
		if ($index == 4) {
			$val = "${bits}'d$val"
		} else {
			$val = $val ? sprintf "%d'b%0${bits}b", $bits, $val : '0';
		}
		my $spaces = ' ' x ($bits + 5 - (length $val));
		$index = sprintf $index_format, $index;

		my $string = "mem[$index] <= $val;";
		$string .= "$spaces // $comment" if defined $comment;
		say $fh $string or croak "Failed to print verilog: $!"; # uncoverable branch true
	}

}
sub parse_and_print_binary16 {
	my ($self, $string, $fh) = @_;
	$self->parse($string);
	$self->finish;
	$self->print_binary16($fh);
}

sub parse_and_print_verilog {
	my ($self, $string, $fh) = @_;
	$self->parse($string);
	$self->finish;
	$self->print_verilog($fh);
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Scheme79asm - assemble sexp to Verilog ROM for SIMPLE processor

=head1 SYNOPSIS

  use App::Scheme79asm;
  my $asm = App::Scheme79asm->new(type_bits => 3, addr_bits => 5);
  $asm->parse_and_print_verilog('(number 70)');

=head1 DESCRIPTION

SIMPLE is a LISP processor defined in the 1979
B<Design of LISP-Based Processors> paper by Steele and Sussman.

The SIMPLE processor expects input in a particular tagged-pointer
format. This module takes a string containing a sequence of
S-expressions. Each S-expression is a list of one of three types:

C<(tag value)>, for example C<(symbol 2)>, represents a value to be
put in memory (for example a number, or a symbol, or a variable
reference). The value must be a number.

C<(tag list)>, where C<list> is of one of these three types,
represents a tagged pointer. In this case, C<list> is (recursively)
laid out in memory as per these rules, and a pointer to that location
(and tagged C<tag>) is put somewhere in memory.

C<(tag list1 list2)>, where C<list1> and C<list2> are of one of these
three types (not necessarily the same type). In this case, C<list1>
and C<list2> are (recursively) laid out in memory such that C<list1>
is at position X and C<list2> is at position X+1, and a pointer of
type tag and value X is put somewhere in memory.

After this process the very last pointer placed in memory is moved to
the special location 5 (which is where SIMPLE expects to find the
expression to be evaluated).

In normal use a single S-expression will be supplied, representing an
entire program.

The C<tag> is either a number, a type, or a primitive.
The available types are:

=over

=item LIST

=item SYMBOL (syn. NUMBER)

=item VAR (syn. VARIABLE)

=item CLOSURE

=item PROC (syn. PROCEDURE)

=item IF (syn. COND, CONDITIONAL)

=item CALL

=item QUOTE (syn. QUOTED)

=back

The available primitives are:

=over

=item MORE

=item CAR

=item CDR

=item CONS

=item ATOM

=item PROGN

=item REVERSE-LIST

=item FUNCALL

=back

The following methods are available:

=over

=item App::Scheme79asm->B<new>([key => value, key => value, ...])

Create a new assembler object. Takes a list of keys and values, here
are the possible keys:

=over

=item type_bits

=item address_bits

A word is made of a type and an address, with the type occupying the
most significant C<type_bits> (default 3) bits, and the address
occupying the least significant C<address_bits> (default 8) bits.
Therefore the word size is C<type_bits + address_bits> (default 11).

=item freeptr

A pointer to the last used byte in memory (default 6). The program
will be laid out starting with location C<freeptr + 1>.

=item memory

The initial contents of the memory. Note that locations 4, 5, 6 will
be overwritten, as will every location larger than the value of
C<freeptr>.

=item comment

The initial comments for memory entries. C<< $comment->[$i] >> is the
comment for C<< $memory->[$i] >>. Note that the first 7 entries of
this array will be overwritten with the default comments. This is
useful when using custom initial memory contents and freeptr, because
this key can be used to provide comments for the extra reserved
locations in memory.

=back

=item $asm->B<parse>(I<$string>)

Parse a sequence of S-expressions and lay it out in memory.
Can be called multiple times to lay out multiple sequences of
S-expressions one after another.

=item $asm->B<process>(I<$sexp>)

Given an already-parsed sexp (meaning a
L<Data::SExpression> object), lay it out in memory.
Can be called multiple times to lay out multiple sequences of
S-expressions one after another.

=item $asm->B<finish>

Move the last pointer to position 5, and put the free pointer at
position 4. After all sequences of S-expressions have been given to
B<parse>, this method should be called.

=item $asm->B<print_binary16>([I<$fh>])

Print the length of the memory (as a big-endian 16-bit value),
followed by the memory contents as a sequence of big-endian 16-bit
values to the given filehandle (default STDOUT). Dies if
C<addr_bits + type_bits> is more than 16.

Big-endian 16-bit values can be decoded with C<unpack 'n', $value>.

=item $asm->B<print_verilog>([I<$fh>])

Print a block of Verilog code assigning the memory contents to an
array named C<mem> to the given filehandle (default STDOUT).

=item $asm->B<parse_and_print_binary16>(I<$string>[, I<$fh>])

Convenience method that calls B<parse>($string), B<finish>, and then
B<print_binary16>($fh).

=item $asm->B<parse_and_print_verilog>(I<$string>[, I<$fh>])

Convenience method that calls B<parse>($string), B<finish>, and then
B<print_verilog>($fh).

=back

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
