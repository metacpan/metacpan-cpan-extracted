use warnings;
use strict;

our $VERSION = '0.0.2';


package Data::SExpression::Xen;

=head1 NAME

Data::SExpression::Xen - Lisp-style S-Expression parser compatable with Xen

=head1 VERSION

This documentation refers to Data::SExpression::Xen version 0.0.1

=head1 SYNOPSIS

Most users will wish to create a hash reference as such:

  use Data::SExpression::Xen;
  my $sxp = Data::SExpression::Xen->new();
  my $hashref = $sxp->as_hash($string);

It is also possible to create an array reference: 

  use Data::SExpression::Xen;
  my $sxp = Data::SExpression::Xen->new();
  my @array = $sxp->as_array($string);

=head1 METHODS

=head2 new

Returns a new Data::SExpression::Xen object.

=cut

sub new {
	my $self={};
	bless $self;
	return $self;
}

sub _format {
	my $self=shift;
	$_=shift;

	s/(\(|\))/ \1 /g;
	s/(\S+)/'\1',/g;
	s/'(\(|\))'/\1/g;
	
	s/\s+/ /g;
	s/\(/, \(/g;
	s/\(/[/g;
	s/\)/]/g;
	s/, ]/]/g;
	s/\[,/\n[/g;
	s/, ,/,/g;
	s/,\s+$//;

	s/(,|\[|])\s?''/\1 "'/g;
	s/''\s?(,|\[|])/'" \1/g;
	s/^\s+,//;
	return $_;
}

sub _array2hash {
	my $self=shift;
	my $a=shift;
	my $hash={};
	my $count=0;
	my $key;

	foreach (@{$a}) {
		$count++;

		if ($_ =~ /ARRAY/) {
			# We're going recursive...
			$hash->{@{$_}[0]}=$self->_array2hash($_);
		}
		else {
			$key=$_;
			unless (@{$a}[$count] =~ /ARRAY/) {
				# We are a value, not a hash tree.
				$hash=@{$a}[$count];
				last;
			}
			else {
				# We're starting a new keyed hashref.
				$hash->{$key}={};
			}
		}
	}

	return $hash;
}

=head2 as_array (SCALAR)

Accepts string argument representing an S-Expression.  Returns an array reference.

=cut

sub as_array {
	my $self=shift;
	my $input=shift;
	return eval $self->_format($input);
}

=head2 as_hash (SCALAR)

Accepts string argument representing an S-Expression.  Returns a hash reference.

=cut

sub as_hash {
	my $self=shift;
	my $input=shift;
	return $self->_array2hash(
		$self->as_array($input)
	);
}

1;
