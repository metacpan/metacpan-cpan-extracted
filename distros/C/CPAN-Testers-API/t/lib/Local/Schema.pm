use utf8;
package Local::Schema;
# ABSTRACT: Create a local schema for testing the schema modules

=head1 SYNOPSIS

    use Local::Schema qw( prepare_temp_schema );
    my $schema = prepare_temp_schema();

=head1 DESCRIPTION

This module prepares a local CPAN Testers database schema for testing
the API.

=head1 SEE ALSO

=over

=item L<DBD::SQLite>

=back

=cut

use CPAN::Testers::API::Base;
use CPAN::Testers::Schema;
use Exporter qw( import );
our @EXPORT_OK = qw(
    prepare_temp_schema
);

=sub prepare_temp_schema

    my $schema = prepare_temp_schema();

Prepare and deploy a schema in memory for testing purposes.

=cut

sub prepare_temp_schema {
    my $schema = CPAN::Testers::Schema->connect( 'dbi:SQLite:dbname=:memory:' );
    $schema->deploy;
    return $schema;
}

1;

