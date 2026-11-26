=head1 NAME

AtteanX::Endpoint::Error - Error classes for use with AtteanX::Endpoint

=head1 VERSION

This document describes AtteanX::Endpoint::Error version 0.004

=head1 SYNOPSIS

  use AtteanX::Endpoint::Error

=head1 DESCRIPTION

The AtteanX::Endpoint::Error class and its subclasses define a set of errors
that are used by AtteanX::Endpoint to signal various client and server errors
that will be translated into appropriate HTTP responses.

=head1 ATTRIBUTES

=over 4

=item C<< message >>

=item C<< details >>

=item C<< uri >>

=item C<< code >>

=back

=cut

use v5.14;
use warnings;

package AtteanX::Endpoint::Error 0.004 {
	use Moo;
	use Types::Standard qw(Str Int HashRef);
	use namespace::clean;

	has 'message'	=> (is => 'ro', isa => Str, required => 1);
	has 'details'	=> (is => 'ro', isa => HashRef, default => sub { +{} });
	has 'uri'		=> (is => 'ro', isa => Str);
	has 'code' => (is => 'ro', isa => Int, required => 1);
}

package AtteanX::Endpoint::ClientError {
	use Moo;
	extends 'AtteanX::Endpoint::Error';
	use Types::Standard qw(Int);
	use namespace::clean;

	has 'code' => (is => 'ro', isa => Int, default => 400);
}

package AtteanX::Endpoint::ServerError {
	use Moo;
	extends 'AtteanX::Endpoint::Error';
	use Types::Standard qw(Int Str);
	use Carp qw(longmess);
	use namespace::clean;

	has 'code' => (is => 'ro', isa => Int, default => 500);
	has 'stacktrace'	=> (is => 'rw', isa => Str);
	
	sub BUILD {
		my $self	= shift;
		$self->stacktrace(longmess('stack trace'));
	}
	
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/kasei/atteanx-endpoint/issues>.

=head1 AUTHOR

Gregory Todd Williams  C<< <gwilliams@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) Gregory Todd Williams.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
