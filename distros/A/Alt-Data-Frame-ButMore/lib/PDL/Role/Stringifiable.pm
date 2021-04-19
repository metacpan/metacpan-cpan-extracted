package PDL::Role::Stringifiable;

use strict;
use warnings;
use Role::Tiny;

requires 'element_stringify';
requires 'element_stringify_max_width';

sub element_stringify {
		my($self, $element) = @_;
		"$element";
}

sub string {
	# TODO
	my ($self) = @_;

    if ($self->nelem > $PDL::toolongtoprint) {
        return "TOO LONG TO PRINT";
    }

    my $ndims = $self->ndims;
	if( $ndims == 0 ) {
		return $self->element_stringify( $self->at() );
	}
	elsif( $ndims == 1 ) {
		return $self->string1d;
	}
	# TODO string2d, stringNd
	...
}

sub string1d {
	my ($self) = @_;
	my $str = "[";

	for my $w (0..$self->nelem-1) {
		$str .= " ";
		$str .= $self->element_stringify( $self->at($w) );
	}
	$str .= " " if ($self->nelem > 0);
	$str .= "]";
	$str;
}

sub string2d {
	...
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::Role::Stringifiable

=head1 VERSION

version 0.0056

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2020 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
