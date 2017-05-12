package PDL::SV;
$PDL::SV::VERSION = '0.003';
use strict;
use warnings;

use Moo;
use PDL::Lite;
use MooX::InsideOut;
use Data::Rmap qw(rmap_array);
use Storable qw(dclone);
use List::AllUtils ();

extends 'PDL';
with qw(PDL::Role::Stringifiable);

# after stringifiable role is added, the string method will exist
eval q{
	use overload ( '""'   =>  \&PDL::SV::string );
};

has _internal => ( is => 'rw', default => sub { [] } );

around new => sub {
	my $orig = shift;
	my ($class, @args) = @_;
	my $data = shift @args; # first arg

	my $faked_data = dclone($data);
	rmap_array { $_ = [ (0)x@$_ ] } $faked_data;

	unshift @args, _data => $faked_data;

	my $self = $orig->($class, @args);

	$self .= $self->sequence( $self->dims );

	my $nelem = $self->nelem;
	for my $idx (0..$nelem-1) {
		my @where = PDL::Core::pdl($self->one2nd($idx))->list;
		$self->_internal()->[$idx] = $self->_array_get( $data, @where );
	}

	$self;
};

#sub initialize {
	#bless { PDL => null }, shift;
#}

# code modified from <https://metacpan.org/pod/Hash::Path>
sub _array_get {
	my ($self, $array, @indices) = @_;
	return $array unless scalar @indices;
	my $return_value = $array->[ $indices[0] ];
	for (1 .. (scalar @indices - 1)) {
		$return_value = $return_value->[ $indices[$_] ];
	}
	return $return_value;
}

around qw(slice dice uniq) => sub {
	my $orig = shift;
	my ($self) = @_;
	my $ret = $orig->(@_);
	# TODO _internal needs to be copied
	$ret->_internal( $self->_internal );
	$ret;
};

around qw(sever) => sub {
	# TODO
	# clone the contents of _internal
	# renumber the elements
};


sub FOREIGNBUILDARGS {
	my ($self, %args) = @_;
	( $args{_data} );
}

around at => sub {
	my $orig = shift;
	my ($self) = @_;

	my $data = $orig->(@_);
	$self->_internal->[$data];
};

around unpdl => sub {
	my $orig = shift;
	my ($self) = @_;

	my $data = $orig->(@_);
	Data::Rmap::rmap_scalar(sub {
		$_ = $self->_internal->[$_];
	}, $data);
	$data;
};

sub element_stringify_max_width {
	my ($self, $element) = @_;
	my @where = @{ $self->uniq->SUPER::unpdl };
	my @which = @{ $self->_internal }[@where];
	my @lengths = map { length $_ } @which;
	List::AllUtils::max( @lengths );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::SV

=head1 VERSION

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
