use 5.012;
use strict;
use warnings;
use Keyword::Simple ();

{
	package Acme::Loopy;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
		
	sub import
	{
		Keyword::Simple::define loop => sub {
			my ($ref) = @_;
			my $rand = 99_999 + int rand 900_000;
			substr($$ref, 0, 0) =
				q{ local ${^_LOOP_OLD}     = ${^LOOP}; } .
				q{ local ${^_LOOP_CURRENT} = -1; } .
				q{ while ( ${^LOOP} = ++${^_LOOP_CURRENT}, my $__guard_}.$rand.q{ = Acme::Loopy::Guard->new(${^_LOOP_OLD}, \${^LOOP}) )};
		};
	}
	
	sub unimport
	{
		Keyword::Simple::undefine loop => ();
	}
}

{
	package Acme::Loopy::Guard;

	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.004';
	
	sub new
	{
		my $class = shift;
		bless \@_, $class;
	}
	
	sub DESTROY
	{
		${$_[0][1]} = $_[0][0];
	}
}

1;

__END__

=head1 NAME

Acme::Loopy - loop keyword

=head1 SYNOPSIS

	loop {
		my @row = get_data() or last;
		
		# First iteration only
		print table_headers(\@row) unless ${^LOOP};
		
		# All iterations
		print table_row(\@row);
	}

=head1 DESCRIPTION

This is really just a test/experiment with L<Keyword::Simple>. It gives
you a keyword C<loop> which acts like a C<< while(1) >> loop - that is, it
loops infinitely until an explicit C<last>. This is quite similar to
ikegami's L<Syntax::Feature::Loop>.

Within the loop, the variable C<< ${^LOOP} >> can be used to obtain the
current iteration count. This is a zero-based count, so is zero (false)
on the first journey around the loop.

L<Keyword::Simple> made defining the C<loop> keyword itself so easy that
C<< ${^LOOP} >> became the tricky part. (Or rather making it work with
nested loops did!)

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Acme-Loopy>.

=head1 SEE ALSO

L<Keyword::Simple>, L<Syntax::Feature::Loop>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

