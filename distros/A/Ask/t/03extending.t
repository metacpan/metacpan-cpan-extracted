=head1 PURPOSE

Make sure it's possible to extend Ask with Moo roles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

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

BEGIN {
	package AskX::Method::Password;
	use Moo::Role;
	sub password {
		my ($self, %o) = @_;
		$o{hide_text} //= 1;
		$o{text}      //= "please enter your password";
		$self->entry(%o);
	}
};

sub flush_buffers {
	@input = @output = ();
}

my $ask = Ask->detect(
	traits          => ['AskX::Method::Password'],
	input_callback  => sub { shift @input },
	output_callback => sub { push @output, $_[0] },
);

{
	@input = 's3cr3t';
	is(
		$ask->password,
		's3cr3t',
	);
	flush_buffers();
}

done_testing;
