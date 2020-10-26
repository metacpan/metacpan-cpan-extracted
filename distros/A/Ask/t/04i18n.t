=head1 PURPOSE

Check some basic IO works with L<Ask::Callback>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;

BEGIN { $ENV{PERL_ASK_BACKEND} = 'Ask::Callback' };

use Ask;

my @input;
my @output;

sub flush_buffers {
	@input = @output = ();
}

my $ask = Ask->detect(
	input_callback  => sub { shift @input },
	output_callback => sub { push @output, $_[0] },
);

{
	@input = 'oui';
	is(
		!!$ask->question(text => 'Ca va bien?', lang => "fr"),
		!!1,
	);
	flush_buffers();
}

{
	@input = 'tidak';
	is(
		!!$ask->question(text => 'Anda ok?', lang => "ms"),
		!!0,
	);
	flush_buffers();
}

done_testing;
