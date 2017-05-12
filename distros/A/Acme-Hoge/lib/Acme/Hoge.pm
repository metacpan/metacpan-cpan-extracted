package Acme::Hoge;

use warnings;
use strict;

use Output::Rewrite (
	rewrite_rule => {
		'(?<=\b)foo(?=\b)' => qq/hoge/,
		'(?<=\b)FOO(?=\b)' => qq/HOGE/,
		'(?<=\b)Foo(?=\b)' => qq/Hoge/,
		'(?<=\b)bar(?=\b)' => qq/fuga/,
		'(?<=\b)BAR(?=\b)' => qq/FUGA/,
		'(?<=\b)Bar(?=\b)' => qq/Fuga/,
		'(?<=\b)baz(?=\b)' => qq/piyo/,
		'(?<=\b)BAZ(?=\b)' => qq/PIYO/,
		'(?<=\b)Baz(?=\b)' => qq/Piyo/,
		'(?<=\b)foobar(?=\b)' => qq/hogefuga/,
		'(?<=\b)FOOBAR(?=\b)' => qq/HOGEFUGA/,
		'(?<=\b)FooBar(?=\b)' => qq/HogeFuga/,
		'(\d)' => '$1!',
	},
);

=head1 NAME

Acme::Hoge - Replace "foo" in output with "hoge".

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

    use Acme::Hoge;

    print "foo bar baz foobar\n";
    # hoge fuga piyo hogefuga

    print "sidebar\n";
    # sidebar
    # (not be rewritten)

=head1 DESCRIPTION

Acme::Hoge replaces some words in output.

If you output "foo", it will be rewritten as "hoge".

And "bar" will be "fuga", "baz" will be "piyo" and so on.

=head1 FUNCTIONS

There is no function.

=head1 AUTHOR

Hogeist, C<< <mahito at cpan.org> >>, L<http://www.ornithopter.jp/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-acme-hoge at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Hoge>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Hoge

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Hoge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Hoge>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Hoge>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Hoge>

=back

=head1 ACKNOWLEDGEMENTS

=head1 SEE ALSO

Output::Rewrite

=head1 COPYRIGHT & LICENSE

Copyright 2006 Hogeist, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Acme::Hoge
