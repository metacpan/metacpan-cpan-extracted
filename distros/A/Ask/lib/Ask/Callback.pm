use 5.010;
use strict;
use warnings;

{
	package Ask::Callback;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	use Moo;
	use namespace::sweep;
	
	with 'Ask::API';
	
	has input_callback  => (is => 'ro', required => 1);
	has output_callback => (is => 'ro', required => 1);

	sub is_usable {
		my ($self) = @_;
		ref $self->output_callback eq 'CODE' and
		ref $self->input_callback  eq 'CODE';
	}

	sub quality {
		return 0;
	}

	sub entry {
		my ($self) = @_;
		return $self->input_callback->();
	}

	sub info {
		my ($self, %o) = @_;
		return $self->output_callback->($o{text});
	}
}

1;

__END__

=head1 NAME

Ask::Callback - interact with yourself via callbacks

=head1 SYNOPSIS

	my $ask = Ask::Callback->new(
		input_callback   => sub { ... },
		output_callback  => sub { ... },
	);

=head1 DESCRIPTION

Primarily for the test suite.

The input_callback is expected to return text which we pretend "the user
typed in".

The output_callback is passed text which we pretend to "show the user".

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

