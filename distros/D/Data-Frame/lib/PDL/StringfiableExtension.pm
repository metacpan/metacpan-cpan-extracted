package PDL::StringfiableExtension;
$PDL::StringfiableExtension::VERSION = '0.006004';
use strict;
use warnings;
use PDL::Lite ();
use List::AllUtils ();


{
	# This is a hack.
	# This gets PDL to stringify the single element and then gets the
	# element out of that string.
	my $_pdl_stringify_temp = PDL::Core::pdl([[0]]);
	my $_pdl_stringify_temp_single = PDL::Core::pdl(0);
	sub PDL::element_stringify {
		my ($self, $element) = @_;
		if( $self->ndims == 0 ) {
			return $_pdl_stringify_temp_single->set(0, $element)->string;
		}
		# otherwise
		( $_pdl_stringify_temp->set(0,0, $element)->string =~ /\[(.*)\]/ )[0];
	}
}

sub PDL::element_stringify_max_width {
	my ($self) = @_;
	my @vals = @{ $self->uniq->unpdl };
	my @lens = map { length $self->element_stringify($_) } @vals;
	List::AllUtils::max( @lens );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::StringfiableExtension

=head1 VERSION

version 0.006004

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2022 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
