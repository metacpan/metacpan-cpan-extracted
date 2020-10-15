package App::SimpleBackuper::DB::Packer;

use strict;
use warnings;
use Const::Fast;
use Carp;

const my %LENGTH => ( map { $_ => length(pack $_.8, 1)/8 } qw(J H a C) );

sub new {
	my($class, $data) = @_;
	
	return bless {
		data	=> $data || '',
		offset	=> 0,
	} => $class;
}

sub at_end { $_[0]->{offset} >= length( $_[0]->{data} ) }

sub unpack {
	my($self, $type, $count) = @_;
	
	if($count ne '*') {
		croak "Too much count ($count)" if $count >= 2147483648;
		confess "At end of data" if $self->at_end;
		my $length = $LENGTH{$type} * $count;
		my $res = unpack( $type.$count, substr( $self->{data}, $self->{offset}, $length ) );
		$self->{offset} += $length;
		return $res;
	} else {
		my $res = unpack( $type.$count, substr( $self->{data}, $self->{offset} ) );
		$self->{offset} = length( $self->{data} );
		return $res;
	}
}

sub pack {
	my($self, $type, $count, @values) = @_;
	
	croak "Not at end of data" if ! $self->at_end;
	confess "Undefined count (type=$type)" if ! defined $count;
	croak "Too much count ($count)" if $count ne '*' and $count >= 2147483648;
	confess "Undefined value" if grep {! defined} @values;
	confess "Is not a number" if $type eq 'J' and grep { /\D/ } @values;
	croak "Can't pack a* with multiple values" if $type eq 'a' and $count eq '*' and @values > 1;
	
	my $value = pack($type.$count, (@values));
	$self->{offset} += length $value;
	$self->{data} .= $value;
	
	return $self;
}

sub data {shift->{data}}

sub print_state {
	my $self = shift;
	for my $q (0 .. length($self->{data}) - 1) {
		print "->" if $q == $self->{offset};
		printf "\\x%02x", ord(substr( $self->{data}, $q, 1 ));
	}
	print "\n";
	return $self;
}

1;
