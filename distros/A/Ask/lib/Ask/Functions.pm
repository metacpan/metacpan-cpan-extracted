use 5.010;
use strict;
use warnings;

{
	package Ask::Functions;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.007';
	
	our $ASK;
	
	sub _called {
		$ASK //= do { require Ask; Ask->detect };
		
		my $method = shift;
		unshift @_, 'text' if @_ % 2;
		return $ASK->$method(@_);
	}

	my @F;
	BEGIN {
		@F = qw(
			info warning error entry question file_selection
			single_choice multiple_choice
		);
		
		eval qq{
			sub $_ { unshift \@_, $_; goto \\&_called };
		} for @F;
	}

	use Sub::Exporter::Progressive -setup => { exports => \@F };
}

1;

__END__

=head1 NAME

Ask::Functions - guts behind Ask's exported functions

=head1 SYNOPSIS

	use Ask 'question';

=head1 DESCRIPTION

This module implements the exported functions for Ask. It is kept separate
to avoid the functions polluting the namespace of the C<Ask> package.

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

