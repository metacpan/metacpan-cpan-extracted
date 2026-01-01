=pod

=encoding utf-8

=head1 PURPOSE

Print version numbers, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;

my @modules = qw(
	AI::Chat
	App::Cmd
	Carp
	Cwd
	Path::Tiny
	Term::ANSIColor
	Term::Spinner::Color
	utf8::all
	YAML::XS
	Test2::V0
);

diag "\n####";
for my $mod ( sort @modules ) {
	eval "require $mod;";
	diag sprintf( '%-20s %s', $mod, $mod->VERSION // 'undef' );
}
diag "####";

pass;

done_testing;

