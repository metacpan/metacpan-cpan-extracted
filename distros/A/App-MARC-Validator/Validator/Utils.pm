package App::MARC::Validator::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Cpanel::JSON::XS;
use Cpanel::JSON::XS::Type;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(obj_to_json);

our $VERSION = 0.09;

sub obj_to_json {
	my ($self, $report) = @_;

	my $struct_hr = {};
	foreach my $plugin (@{$report->plugins}) {
		$struct_hr->{$plugin->name} = {
			'checks' => {
				'not_valid' => {},
			},
			'datetime' => $report->datetime->iso8601,
			'module_name' => $plugin->module_name,
			'module_version' => $plugin->version,
			'name' => $plugin->name,
		},
		my $not_valid_hr = $struct_hr->{$plugin->name}->{'checks'}->{'not_valid'};
		foreach my $plugin_errors (@{$plugin->plugin_errors}) {
			$not_valid_hr->{$plugin_errors->record_id} = [];
			foreach my $error (@{$plugin_errors->errors}) {
				push @{$not_valid_hr->{$plugin_errors->record_id}}, {
					'error' => $error->error,
					'params' => $error->params,
				};
			}
		}
	}

	# JSON output.
	my $j = Cpanel::JSON::XS->new;
	if ($self->{'_opts'}->{'p'}) {
		$j = $j->pretty;
	}
	my $json = $j->canonical(1)->encode($struct_hr);

	return $json;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::MARC::Validator::Utils - Utilities for App::MARC::Validator.

=head1 SYNOPSIS

 use App::MARC::Validator::Utils qw(obj_to_json);

 my $json = obj_to_json($app, $report);

=head1 SUBROUTINES

=head2 C<obj_to_json>

 my $json = obj_to_json($app, $report);

Convert validation report object to JSON string.

Returns string with JSON.

=head1 EXAMPLE

=for comment filename=obj_to_json.pl

 use strict;
 use warnings;

 use App::MARC::Validator::Utils qw(obj_to_json);
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
                        'module_name' => 'MARC::Validator::Plugin::Foo',
                        'name' => 'foo',
                        'plugin_errors' => [
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
                        'version' => '0.01',
                 ),
         ],
 );

 my $self = {
         '_opts' => {
                 'p' => 1,
         },
 };
 my $json = obj_to_json($self, $report);

 print $json;

 # Output:
 # {
 #    "foo" : {
 #       "checks" : {
 #          "not_valid" : {
 #             "id1" : [
 #                {
 #                   "error" : "Error #1",
 #                   "params" : {
 #                      "key" : "value"
 #                   }
 #                },
 #                {
 #                   "error" : "Error #2",
 #                   "params" : {
 #                      "key" : "value"
 #                   }
 #                }
 #             ]
 #          }
 #       },
 #       "datetime" : "2026-05-21T11:20:09",
 #       "module_name" : "MARC::Validator::Plugin::Foo",
 #       "module_version" : "0.01",
 #       "name" : "foo"
 #    }
 # }

=head1 DEPENDENCIES

L<Cpanel::JSON::XS>,
L<Cpanel::JSON::XS::Type>,
L<Exporter>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-MARC-Validator>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.09

=cut
