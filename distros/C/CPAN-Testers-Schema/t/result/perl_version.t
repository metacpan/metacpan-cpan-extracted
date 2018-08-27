
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::PerlVersion> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';

subtest 'fill in data' => sub {
    my $schema = prepare_temp_schema;

    subtest 'stable perl' => sub {
        my $row = $schema->resultset( 'PerlVersion' )->create({ version => '5.5.1' });
        is $row->perl, '5.5.1', 'parsed Perl version is correct';
        is $row->patch, 0, 'not a patch perl';
        is $row->devel, 0, 'not a devel perl';
    };

    subtest 'devel perl' => sub {
        my $row = $schema->resultset( 'PerlVersion' )->create({ version => '5.7.1' });
        is $row->perl, '5.7.1', 'parsed Perl version is correct';
        is $row->patch, 0, 'not a patch perl';
        is $row->devel, 1, 'a devel perl';
    };

    subtest 'patch perl' => sub {
        my $row = $schema->resultset( 'PerlVersion' )->create({ version => '5.9.6 patch 31753' });
        is $row->perl, '5.9.6', 'parsed Perl version is correct';
        is $row->patch, 1, 'a patch perl';
        is $row->devel, 1, 'a devel perl';

        $row = $schema->resultset( 'PerlVersion' )->create({ version => '5.10.0 patch GitLive-maint-5.10-1462-g178839f' });
        is $row->perl, '5.10.0', 'parsed Perl version is correct';
        is $row->patch, 1, 'a patch perl';
        is $row->devel, 0, 'not a devel perl';
    };

    subtest 'leading v' => sub {
        my $row = $schema->resultset( 'PerlVersion' )->create({ version => 'v5.15.0' });
        is $row->perl, '5.15.0', 'parsed Perl version is correct';
        is $row->patch, 0, 'not a patch perl';
        is $row->devel, 1, 'a devel perl';
    };

    subtest 'release candidates' => sub {
        my $row = $schema->resultset( 'PerlVersion' )->create({ version => '5.20.0 RC0' });
        is $row->perl, '5.20.0', 'parsed Perl version is correct';
        is $row->patch, 0, 'not a patch perl';
        is $row->devel, 1, 'a devel perl';
    };
};

done_testing;
