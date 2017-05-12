use 5.008;
use strict;
use warnings;

package Crypt::Role::CheckerboardCipher;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.003';

use Moo::Role;
use Const::Fast;
use POSIX qw( ceil );
use Type::Params;
use Types::Common::Numeric qw( PositiveInt SingleDigit );
use Types::Standard qw( ArrayRef HashRef Str );
use namespace::sweep;

has square_size => (
	is       => 'lazy',
	isa      => PositiveInt & SingleDigit,
	init_arg => undef,
);

requires 'alphabet';

sub _build_square_size {
	my $self = shift;
	my $letters = @{ $self->alphabet };
	return ceil(sqrt($letters));
}

has square => (
	is       => 'lazy',
	isa      => ArrayRef[ ArrayRef[Str] ],
	init_arg => undef,
);

sub _build_square
{
	my $self = shift;
	
	my @alphabet = @{ $self->alphabet };
	my $size = $self->square_size;
	
	const my @rows => map {
		my @letters = (
			splice(@alphabet, 0, $size),
			('') x $size,
		);
		const my @row => @letters[0..$size-1];
		\@row;
	} 1..$size;
	
	\@rows;
}

my $_build_hashes = sub
{
	my $self = shift;
	my ($want) = @_;
	
	my (%enc, %dec);
	my $square = $self->square;
	my $size   = $self->square_size;
	for my $i (0 .. $size-1)
	{
		my $row = $square->[$i];
		for my $j (0 .. $size-1)
		{
			my $clear  = $row->[$j];
			my $cipher = sprintf('%s%s', $i+1, $j+1);
			$enc{$clear}  = $cipher;
			$dec{$cipher} = $clear;
		}
	}
	
	const my $enc => \%enc;
	const my $dec => \%dec;
	$self->_set_encipher_hash($enc);
	$self->_set_decipher_hash($dec);
	$self->$want;
};

has encipher_hash => (
	is       => 'lazy',
	isa      => HashRef[Str],
	writer   => '_set_encipher_hash',
	default  => sub { shift->$_build_hashes('encipher_hash') },
	init_arg => undef,
);

has decipher_hash => (
	is       => 'lazy',
	isa      => HashRef[Str],
	writer   => '_set_decipher_hash',
	default  => sub { shift->$_build_hashes('decipher_hash') },
	init_arg => undef,
);

requires 'preprocess';

my $_check_encipher;
sub encipher
{
	$_check_encipher ||= compile(Str);

	my $self = shift;
	my ($input) = $_check_encipher->(@_);
	
	my $str = $self->preprocess($input);
	my $enc = $self->encipher_hash;
	$str =~ s/(.)/exists $enc->{$1} ? $enc->{$1}." " : ""/eg;
	chop $str;
	return $str;
}

my $_check_decipher;
sub decipher
{
	$_check_decipher ||= compile(Str);

	my $self = shift;
	my ($input) = $_check_decipher->(@_);
	
	my $str = $input;
	my $dec = $self->decipher_hash;
	$str =~ s/[^0-9]//g; # input should be entirely numeric
	$str =~ s/([0-9]{2})/$dec->{$1}/eg;
	return $str;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Crypt::Role::CheckerboardCipher - guts of the Polybius square cipher implementation

=head1 DESCRIPTION

=head2 Attributes

The following attributes exist. All of them have defaults, and should
not be provided to the constructors of consuming classes.

=over

=item C<< square >>

An arrayref of arrayrefs of letters.

=item C<< square_size >>

The length of one side of the square, as an integer.

=item C<< encipher_hash >>

Hashref used by the C<encipher> method.

=item C<< decipher_hash >>

Hashref used by the C<decipher> method.

=back

=head2 Object Methods

=over

=item C<< encipher($str) >>

Enciphers a string and returns the ciphertext.

=item C<< decipher($str) >>

Deciphers a string and returns the plaintext.

=item C<< _build_square_size >>

Calculates the optimum square size for the alphabet. An alphabet of 25
letters can fill a five by five square, so this method would return 5.
An alphabet of 26 characters would partly fill a six by six square, so
this method would return 6.

This method is not expected to be called by end-users but is documented
for people writing classes consuming this role.

=item C<< _build_square >>

Allocates the letters of the alphabet into a square (an arrayref of
arrayrefs of letters), returning the square.

This method is not expected to be called by end-users but is documented
for people writing classes consuming this role.

=back

=head2 Required Methods

Classes consuming this role must provide the following methods:

=over

=item C<< preprocess($str) >>

Expected to return a string more suitable for enciphering.

=item C<< alphabet >>

Expected to returns an arrayref of the known alphabet.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Crypt-Polybius>.

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Polybius_square>.

L<Crypt::Polybius>,
L<Crypt::Polybius::Greek>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

