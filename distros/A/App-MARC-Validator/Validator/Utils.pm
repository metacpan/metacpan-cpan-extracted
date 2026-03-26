package App::MARC::Validator::Utils;

use base qw(Exporter);
use strict;
use warnings;

use Cpanel::JSON::XS;
use Cpanel::JSON::XS::Type;
use Readonly;

Readonly::Array our @EXPORT_OK => qw(obj_to_json);

our $VERSION = 0.07;

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
