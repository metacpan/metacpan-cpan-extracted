
=head1 DESCRIPTION

This file tests the L<CPAN::Testers::Schema::Result::TestReport> class.

=head1 SEE ALSO

L<CPAN::Testers::Schema>, L<DBIx::Class>

=cut

use CPAN::Testers::Schema::Base 'Test';
use Scalar::Util qw( looks_like_number );
my $schema = prepare_temp_schema;
my $HEX = qr{[A-Fa-f0-9]};

subtest 'column defaults' => sub {
    my $row = $schema->resultset( 'TestReport' )->create( { report => {} } );
    like $row->id, qr{${HEX}{8}-${HEX}{4}-${HEX}{4}-${HEX}{4}-${HEX}{12}},
        'GUID is created automatically';
    like $row->created, qr{\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z},
        'row created in Y-M-DTH:M:S';
    is $row->report->{id}, $row->id, 'id field added to report';
    is $row->report->{created}, $row->created, 'created field added to report';
};

done_testing;
