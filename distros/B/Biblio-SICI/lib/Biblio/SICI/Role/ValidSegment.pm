package Biblio::SICI::Role::ValidSegment;
{
  $Biblio::SICI::Role::ValidSegment::VERSION = '0.04';
}

# ABSTRACT: Role to provide common validation error handling functionality to the segments

use strict;
use warnings;

use Moo::Role;


has validationErrors => ( is => 'lazy', );

sub _build_validationErrors {
	return {};
}


sub log_problem_on {
	my ( $self, $attr, $desc ) = @_;

	if ( defined($attr) and $attr and defined($desc) and $desc ) {
		$self->validationErrors->{$attr} = $desc;
	}
	return;
}


sub clear_problem_on {
	my ( $self, $attr ) = @_;

	delete $self->validationErrors->{$attr} if exists $self->validationErrors->{$attr};
	return;
}


sub list_problems {
	my $self = shift;
	return %{ $self->validationErrors };
}


sub is_valid {
	my $self    = shift;
	my $invalid = 0;

	my %problems = %{ $self->validationErrors };

	foreach my $attr ( keys %problems ) {
		if ( exists $problems{$attr} and defined $problems{$attr} and $problems{$attr} ne '' ) {
			$invalid++;
		}
	}
	return 0 if $invalid;
	return 1;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI::Role::ValidSegment - Role to provide common validation error handling functionality to the segments

=head1 VERSION

version 0.04

=head1 DESCRIPTION

A role that provides an attribute and some methods used for validation error
handling functionality in the three SICI segments.

=head1 ATTRIBUTES

=over 4

=item validationErrors

Stores the problem reports that are gathered when any attribute is set.
Do not access this directly - use the methods below.

=back

=head1 METHODS

=over 4

=item C<log_problem_on>( STRING, ARRAYREF )

Stores an array ref of problem descriptions for a particular attribute.

=item C<clear_problem_on>( STRING )

Removes the problem report for a particular attribute.

=item HASH C<list_problems>()

Returns a hash structure with all error reports.

=item BOOL C<is_valid>()

Checks if any problem reports were recorded for any attribute.
If yes, returns I<FALSE>; otherwise, returns I<TRUE>.

Does not yet do extended verification; e.g. checking if all
required data is present or if there are any conflicts within
the stored SICI data!

=back

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
