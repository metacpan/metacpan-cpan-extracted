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
use Path::Tiny 'path';

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
	@input = 'Bob';
	is(
		$ask->entry(text => 'Bob, what is your name?'),
		'Bob',
	);
	flush_buffers();
}

{
	@input = 'y';
	is(
		!!$ask->question(text => 'Will this test pass?'),
		!!1,
	);
	flush_buffers();
}

{
	@input = qw( file1.txt file2.txt file3.txt file4.txt );
	my $got = $ask->file_selection(text => 'Enter "file1.txt"');
	isa_ok( $got, 'Path::Tiny' );
	is(
		$got,
		path 'file1.txt',
	);
	is_deeply(
		[ $ask->file_selection(
			text     => 'Enter "file2.txt", "file3.txt" and "file4.txt"',
			multiple => 1,
		) ],
		[ map path($_), qw( file2.txt file3.txt file4.txt ) ],
	);
	flush_buffers();
}

{
	$ask->info(text => 'Argh!');
	is(
		$output[0],
		'Argh!',
	);
	flush_buffers();
}

{
	$ask->warning(text => 'Argh!');
	is(
		$output[0],
		'WARNING: Argh!',
	);
	flush_buffers();
}

{
	$ask->error(text => 'Argh!');
	is(
		$output[0],
		'ERROR: Argh!',
	);
	flush_buffers();
}

done_testing;
