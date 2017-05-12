package Acme::ButFirst;

use 5.006;
use strict;
use warnings;

use Filter::Simple;

our $VERSION = '1.00';

# Yes, this is a recursive regexp. ;)

my $block;

$block = qr{
	{					# An open-curly
		(?:
			(?> [^{}]+ )		# Non-curlies no backtracking.
			|
			(??{ $block })		# An embedded block
		)*
	}					# Close-curly
}x;

sub _butfirstify {

	# Continue to re-write our code until no more butfirst
	# sections exist.

	# We enclose each pair of blocks transposed inside their
	# own block.  This allows chained but-firsts and
	# butfirst modifiers on loops to work 'correctly'.

	1 while s{ ($block) \s* but \s* first \s* ($block) }
                 {{$2\n$1}}gxs;

};

# We have to use 'executable' rather than code, as Filter::Simple
# sometimes thinks that 'but \s* first' is a bareword string.
#
# The downside of this is that we may modify some *real* strings
# as well as code.


FILTER_ONLY executable => \&_butfirstify;

1;
__END__

=head1 NAME

Acme::ButFirst - Do something, but first do something else.

=head1 SYNOPSIS

	use Acme::ButFirst;

	# Print a greeting, but first find caffiene.

	{
		print "Good morning!\n";
	} but first {
		print "I need a coffee\n";
	}

	# Count from 1 to 10, but first print a statement
	# about our counting skills.

	foreach my $count (1..10) {
		print "$count\n";
	} but first {
		print "I can count to...";
	}

	# Print our lines, but first reverse them, but first convert
	# them into upper case.

	while (<>) {
		print;
	} butfirst {
		$_ = reverse $_;
	} butfirst {
		$_ = uc $_;
	}

=head1 DESCRIPTION

C<Acme::ButFirst> allows you to execute a block of code, but first do
something else.  Perfect for when you wish to add to the start
of a long block of code, but don't have the energy to scroll
upwards in your editor.

C<Acme::ButFirst> recognises both C<butfirst> and C<but first> as
keywords.

Usage of C<Acme::ButFirst> is lexically scoped.  ButFirstification
can be explicitly disabled by using C<no Acme::ButFirst>.

=head1 SEE ALSO

L<http://lists.slug.org.au/archives/slug/2005/09/msg00346.html>

L<Acme::Dont::t>, L<Acme::ComeFrom>, L<Acme::Goto::Line>

=head1 BUGS

Any use of this module should be considered a bug.

Strings in the form of C<" { work } but first { coffee } "> may
sometimes be incorrectly munged.

=head1 AUTHOR

Paul Fenwick E<lt>pjf@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Paul Fenwick

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
