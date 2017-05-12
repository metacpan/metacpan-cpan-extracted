=pod

=encoding utf-8

=head1 PURPOSE

Test that Acme::PPIx::MetaSyntactic works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use Acme::PPIx::MetaSyntactic;

my $code = <<'PERL';
use constant GREETING => "hello";

my $foo = 1;
my @bar = qw( 2 3 );
my %baz = ( hello => 4 );

$foo + $bar[0] + $bar[1] + $baz{ GREETING() };
PERL

my $new = "Acme::PPIx::MetaSyntactic"->new(document => \$code)->document;

is(
	eval("$new"),
	10,
	'yay!',
) ? note("$new") : diag("$new");

done_testing;

