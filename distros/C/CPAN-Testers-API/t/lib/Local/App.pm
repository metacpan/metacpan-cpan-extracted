use utf8;
package Local::App;
# ABSTRACT: Create a local app with a temp database for testing the app

=head1 SYNOPSIS

    use Local::App qw( prepare_test_app );
    my $t = prepare_test_app();

=head1 DESCRIPTION

This module prepares a local L<Test::Mojo> object ready to test the CPAN
Testers API.

=head1 SEE ALSO

=over

=item L<Test::Mojo>

=item C<t/lib/Local/Schema.pm>

=back

=cut

use CPAN::Testers::API::Base;
use Local::Schema qw( prepare_temp_schema );
use CPAN::Testers::API;
use Test::Mojo;
use Exporter qw( import );
our @EXPORT_OK = qw(
    prepare_test_app
);

=sub prepare_test_app

    my $t = prepare_test_app();

Prepare a L<Test::Mojo> object with a L<CPAN::Testers::API> application
hooked up to a local, temporary L<CPAN::Testers::Schema> schema.

=cut

sub prepare_test_app() {
    my $schema = prepare_temp_schema();
    my $app = CPAN::Testers::API->new(
        schema => $schema,
    );
    return Test::Mojo->new( $app );
}

1;

