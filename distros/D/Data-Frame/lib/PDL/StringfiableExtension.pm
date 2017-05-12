package PDL::StringfiableExtension;
$PDL::StringfiableExtension::VERSION = '0.003';
use strict;
use warnings;
use PDL::Lite;
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
		my $string = $_pdl_stringify_temp->set(0,0, $element)->string;
		( $_pdl_stringify_temp->string =~ /\[(.*)\]/ )[0];
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

version 0.003

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
