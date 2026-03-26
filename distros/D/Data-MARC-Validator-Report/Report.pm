package Data::MARC::Validator::Report;

use strict;
use warnings;

use Mo qw(build default is);
use Mo::utils 0.08 qw(check_isa check_required);
use Mo::utils::Array qw(check_array_object);

our $VERSION = 0.03;

has datetime => (
	is => 'ro',
);

has plugins => (
	default => [],
	is => 'ro',
);

sub BUILD {
	my $self = shift;

	# Check 'datetime'.
	check_required($self, 'datetime');
	check_isa($self, 'datetime', 'DateTime');

	# Check 'plugins'.
	check_array_object($self, 'plugins', 'Data::MARC::Validator::Report::Plugin');

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Data::MARC::Validator::Report - Data object for MARC validator report.

=head1 SYNOPSIS

 use Data::MARC::Validator::Report;

 my $obj = Data::MARC::Validator::Report->new(%params);
 my $datetime = $obj->datetime;
 my $plugins_ar = $obj->plugins;

=head1 METHODS

=head2 C<new>

 my $obj = Data::MARC::Validator::Report->new(%params);

Constructor.

=over 8

=item * C<datetime>

Datetime of report. Must be a L<DataTime> instance.

Parameter is required.

=item * C<plugins>

List of plugins data objects. Each one must be a
L<Data::MARC::Validator::Report::Plugin> instance.

Default value is [].

=back

Returns instance of object.

=head2 C<datetime>

 my $datetime = $obj->datetime;

Get datetime of report.

Returns L<DateTime> object.

=head2 C<plugins>

 my $plugins_ar = $obj->plugins;

Get plugin reports.

Return reference to array with L<Data::MARC::Validator::Report::Plugin> objects.

=head1 ERRORS

 new():
         From Mo::utils:
                 Parameter 'datetime' is required.
                 Parameter 'datetime' must be a 'DateTime' object.
                         Value: %s
                         Reference: %s

         From Mo::utils::Array:
                 Parameter 'plugins' must be a array.
                         Value: %s
                         Reference: %s
                 Parameter 'plugins' with array must contain 'Data::MARC::Validator::Report::Plugin' objects.
                         Value: %s
                         Reference: %s


=head1 EXAMPLE

=for comment filename=create_and_dump_validator_report.pl

 use strict;
 use warnings;

 use Data::Printer;
 use Data::MARC::Validator::Report;
 use Data::MARC::Validator::Report::Error;
 use Data::MARC::Validator::Report::Plugin;
 use Data::MARC::Validator::Report::Plugin::Errors;
 use DateTime;

 # Create data object for validator report.
 my $report = Data::MARC::Validator::Report->new(
         'datetime' => DateTime->now,
         'plugins' => [
                 Data::MARC::Validator::Report::Plugin->new(
                        'errors' => [
                                Data::MARC::Validator::Report::Plugin::Errors->new(
                                        'errors' => [
                                                Data::MARC::Validator::Report::Error->new(
                                                        'error' => 'Error #1',
                                                        'params' => {
                                                                'key' => 'value',
                                                        },
                                                ),
                                                Data::MARC::Validator::Report::Error->new(
                                                        'error' => 'Error #2',
                                                        'params' => {
                                                                'key' => 'value',
                                                        },
                                                ),
                                        ],
                                        'filters' => ['filter1', 'filter2'],
                                        'record_id' => 'id1',
                                ),
                        ],
                        'module_name' => 'MARC::Validator::Plugin::Foo',
                        'name' => 'foo',
                        'version' => '0.01',
                 ),
         ],
 );

 # Dump out.
 p $report;

 # Output:
 # Data::MARC::Validator::Report  {
 #     parents: Mo::Object
 #     public methods (4):
 #         BUILD
 #         Mo::utils:
 #             check_isa, check_required
 #         Mo::utils::Array:
 #             check_array_object
 #     private methods (0)
 #     internals: {
 #         datetime   2026-02-22T11:16:24 (DateTime),
 #         plugins    [
 #             [0] Data::MARC::Validator::Report::Plugin
 #         ]
 #     }
 # }

=head1 DEPENDENCIES

L<Mo>,
L<Mo::utils>,
L<Mo::utils::Array>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Data-MARC-Validator-Report>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.03

=cut
