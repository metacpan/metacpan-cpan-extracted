=pod

=encoding utf-8

=head1 PURPOSE

Simple integration tests for L<Data::OptList::Object>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0 -target => 'Data::OptList::Object';
use Data::Dumper;

my $o = $CLASS->new( qw/ foo bar baz/, quux => undef, quuux => [] );
ok $o->quux->exists;
ok !$o->not_exists->exists;
is $o->quuux->value, [];

done_testing;
