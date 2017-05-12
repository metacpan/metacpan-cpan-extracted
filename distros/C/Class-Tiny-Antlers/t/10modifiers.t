=pod

=encoding utf-8

=head1 PURPOSE

Test that C<before>, C<after> and C<around> work.

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
use Test::Requires { 'Class::Method::Modifiers' => '1.05' };

{
	package XXX;
	use Class::Tiny;
	sub xxx { ${$_[1]} .= ".in" };
}

{
	package YYY;
	use Class::Tiny::Antlers -all;
	extends 'XXX';
	before xxx => sub { ${$_[1]} .= ".before" };
	after  xxx => sub { ${$_[1]} .= ".after" };
	around xxx => sub {
		my $orig = shift;
		my $self = shift;
		my $str  = $_[0];
		$$str .= ".around1";
		my $r = $self->$orig($str);
		$$str .= ".around2";
		return $r;
	};
}

my $yyy = YYY->new;
my $str = 'orig';
$yyy->xxx(\$str);

is($str, 'orig.before.around1.in.around2.after');

done_testing;
