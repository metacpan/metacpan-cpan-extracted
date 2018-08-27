
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::ResultSet::PerlVersion> module which
queries for L<CPAN::Testers::Schema::Result::PerlVersion> objects.

=head1 SEE ALSO

=over

=item L<DBIx::Class::ResultSet>

=back

=cut

use CPAN::Testers::Schema::Base 'Test';

my $schema = prepare_temp_schema;
my $rs = $schema->resultset( 'PerlVersion' );
$rs->find_or_create({ version => '5.9.5' });
$rs->find_or_create({ version => '5.5.1' });
$rs->find_or_create({ version => '5.23.5 patch 12' });
$rs->find_or_create({ version => '5.24.0 RC0' });
$rs->find_or_create({ version => '5.11.2' });
$rs->find_or_create({ version => '5.10.1' });

subtest 'maturity' => sub {
    my $rs = $schema->resultset( 'PerlVersion' )->maturity( 'stable' );
    is_deeply [ sort map { $_->perl } $rs->all ], [qw( 5.10.1 5.5.1 )];
    $rs = $schema->resultset( 'PerlVersion' )->maturity( 'dev' );
    is_deeply [ sort map { $_->perl } $rs->all ], [qw( 5.11.2 5.23.5 5.24.0 5.9.5 )];
};

done_testing;

