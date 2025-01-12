package CPAN::UnsupportedFinder;

# FIXME: magic dates should be configurable

use strict;
use warnings;

use Carp;
use HTTP::Tiny;
use Log::Log4perl;
use JSON::MaybeXS;
use Scalar::Util;

=head1 NAME

CPAN::UnsupportedFinder - Identify unsupported or poorly maintained CPAN modules

=head1 DESCRIPTION

CPAN::UnsupportedFinder analyzes CPAN modules for test results and maintenance status, flagging unsupported or poorly maintained distributions.

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use CPAN::UnsupportedFinder;

    # Note use of hyphens not colons
    my $finder = CPAN::UnsupportedFinder->new(verbose => 1);
    my $results = $finder->analyze('Some-Module', 'Another-Module');

    for my $module (@$results) {
	  print "Module: $module->{module}\n";
	  print "Failure Rate: $module->{failure_rate}\n";
	  print "Last Update: $module->{last_update}\n";
    }

=head1 METHODS

=head2 new

Creates a new instance. Accepts the following arguments:

=over 4

=item * verbose

Enable verbose output.

=item * api_url

metacpan URL, defaults to L<https://fastapi.metacpan.org/v1>

=item * cpan_testers

CPAN testers URL, detaults to L<https://api.cpantesters.org/api/v1>

=item * logger

Where to log messages, defaults to L<Log::Log4perl>

=back

=cut

sub new {
	my $class = shift;

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		%args = @_;
	} else {
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	if(!defined($class)) {
		if((scalar keys %args) > 0) {
			# Using CPAN::UnsupportedFinder::new(), not CPAN::UnsupportedFinder->new()
			carp(__PACKAGE__, ' use ->new() not ::new() to instantiate');
			return;
		}
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class}, %args }, ref($class);
	}

	my $self = {
		api_url => 'https://fastapi.metacpan.org/v1',
		cpan_testers => 'https://api.cpantesters.org/api/v1',
		verbose => 0,
		%args
	};

	if(!defined($self->{logger})) {
		Log::Log4perl->easy_init($self->{verbose} ? $Log::Log4perl::DEBUG : $Log::Log4perl::ERROR);
		$self->{logger} = Log::Log4perl->get_logger();
	}

	# Return the blessed object
	return bless $self, $class;
}

=head2 analyze(@modules)

Analyzes the provided modules. Returns an array reference of unsupported modules.

=cut

sub analyze {
	my ($self, @modules) = @_;
	croak('No modules provided for analysis') unless(@modules);

	my @results;
	for my $module (@modules) {
		$self->{logger}->debug("Analyzing module $module");

		my $test_data = $self->_fetch_testers_data($module);
		my $release_data = $self->_fetch_release_data($module);

		my $unsupported = $self->_evaluate_support($module, $test_data, $release_data);
		push @results, $unsupported if($unsupported);
	}

	return \@results;
}

=head2 output_results

    $report = $object->output_results($results, $format);

Generates a report in the specified format.

=over 4

=item * C<$results> (ArrayRef)

An array reference containing hashrefs with information about modules (module name, failure rate, last update)
as created by the analyze() method.

=item * C<$format> (String)

A string indicating the desired format for the report. Can be one of the following:

=over 4

=item C<text> (default)

Generates a plain text report.

=item C<html>

Generates an HTML report.

=item C<json>

Generates a JSON report.

=back

=back

=cut

sub output_results {
	my ($self, $results, $format) = @_;
	$format ||= 'text'; # Default to plain text

	if($format eq 'json') {
		return encode_json($results);
	} elsif($format eq 'html') {
		return $self->_generate_html_report($results);
	} else {
		return $self->_generate_text_report($results);
	}
}

sub _generate_text_report {
	my ($self, $results) = @_;
	my $report = '';

	for my $module (@{$results}) {
		$report .= "Module: $module->{module}\n";
		$report .= "\tFailure Rate: $module->{failure_rate}\n";
		$report .= "\tLast Update: $module->{last_update}\n";
		$report .= "\tHas Recent Tests: $module->{recent_tests}\n";
		$report .= "\tReverse Dependencies: $module->{reverse_deps}\n";
		$report .= "\tHas Unsupported Dependencies: $module->{has_unsupported_deps}\n";
	}

	return $report;
}

sub _generate_html_report {
	my ($self, $results) = @_;

	my $html = '<html><head><title>Unsupported Modules Report</title></head><body><h1>Unsupported Modules Report</h1><ul>';

	for my $module (@{$results}) {
		$html .= "<li><strong>$module->{module}</strong>:<br>";
		$html .= "Failure Rate: $module->{failure_rate}<br>";
		$html .= "Last Update: $module->{last_update}<br>";
		$html .= "Has Recent Tests: $module->{recent_tests}<br>";
		$html .= "Reverse Dependencies: $module->{reverse_deps}<br>";
		$html .= "Has Unsupported Dependencies: $module->{has_unsupported_deps}<br></li>";
	}

	$html .= '</ul></body></html>';
	return $html;
}

sub _fetch_testers_data {
	my ($self, $module) = @_;

	my $url = "$self->{cpan_testers}/summary/$module";
	return $self->_fetch_data($url);
}

sub _fetch_release_data {
	my ($self, $module) = @_;

	my $url = "$self->{api_url}/release/_search?q=distribution:$module&size=1&sort=date:desc";
	return $self->_fetch_data($url);
}

sub _fetch_data {
	my ($self, $url) = @_;

	$self->{logger}->debug("Fetching data from $url");

	my $response = HTTP::Tiny->new()->get($url);

	if($response->{success}) {
		$self->{logger}->debug("Data fetched successfully from $url");
		return eval { decode_json($response->{content}) };
	}
	$self->{logger}->debug("Status = $response->{status}");
	if(($response->{'status'} != 200) && ($url =~ /::/)) {
		# Some modules use hyphens as delineators
		$url =~ s/::/-/g;
		return $self->_fetch_data($url);
	}
	$self->{logger}->error("Failed to fetch data from $url: $response->{status}");
	return;
}

sub _fetch_reverse_dependencies {
	my ($self, $module) = @_;

	my $url = "$self->{api_url}/reverse_dependencies/$module";

	return $self->_fetch_data($url);
}

# Evaluate the support status of a module.

# Evaluates the module's failure rate, last update date, test history, and dependencies.

# $module: The name of the module being evaluated.
# $test_data: Test results data for the module.
# $release_data: Release metadata for the module.

# Returns a hashref containing the module's evaluation details if it's flagged as unsupported,
# undef if the module is considered supported.

sub _evaluate_support {
	my ($self, $module, $test_data, $release_data) = @_;

	my $failure_rate = $self->_calculate_failure_rate($test_data);
	my $last_update = $self->_get_last_release_date($release_data) || 'Unknown';

	# Reverse Dependencies: Modules with many reverse dependencies have higher priority for support.
	my $reverse_deps = $self->_fetch_reverse_dependencies($module);

	# Check if there are any test results in the last 6 months
	my $has_recent_tests = $self->_has_recent_tests($test_data);

	# Check if the module has dependencies marked as deprecated or unsupported
	my $has_unsupported_dependencies = $self->_has_unsupported_dependencies($module);

	# Check if the module is unsupported based on the criteria
	# Flag module as unsupported if:
	# - High failure rate (> 50%)
	# - No recent updates
	# - No recent test results in the last 6 months
	# - Has unsupported dependencies
	if(($failure_rate > 0.5) || ($last_update eq 'Unknown') || ($last_update lt '2022-01-01') || !$has_recent_tests || $has_unsupported_dependencies) {
		return {
			module	=> $module,
			failure_rate => $failure_rate,
			last_update => $last_update,
			recent_tests => $has_recent_tests ? 'Yes' : 'No',
			reverse_deps => $reverse_deps->{total} || 0,
			has_unsupported_deps => $has_unsupported_dependencies ? 'Yes' : 'No',
		};
	}

	return;	# Module is considered supported
}

# Helper function to calculate the date six months ago
sub _six_months_ago {
	my @time = localtime(time - 6 * 30 * 24 * 60 * 60);	# Approximate six months in seconds
	return sprintf "%04d-%02d-%02d", $time[5] + 1900, $time[4] + 1, $time[3];
}

sub _has_recent_tests
{
	# FIXME
	return 1;	# The API is currently unavailable

	my ($self, $test_data) = @_;

	# Assume $test_data contains test reports with a timestamp field
	my $six_months_ago = $self->_six_months_ago();

	foreach my $test(@{$test_data}) {
		::diag(__LINE__);
		::diag($test->{timestamp});
		::diag($six_months_ago);
		if($test->{timestamp} && ($test->{timestamp} > $six_months_ago)) {
			return 1;	# Recent test found
		}
	}

	return 0;	# No recent tests found
}


# The API is currently unavailable
sub _calculate_failure_rate {
	my ($self, $test_data) = @_;

	return 0 unless $test_data && $test_data->{results};

	my $total_tests = $test_data->{results}{total};
	my $failures = $test_data->{results}{fail};

	return $total_tests ? $failures / $total_tests : 1;
}

sub _get_last_release_date {
	my ($self, $release_data) = @_;
	return unless $release_data && $release_data->{hits}{hits}[0];

	return $release_data->{hits}{hits}[0]{_source}{date};
}

sub _has_unsupported_dependencies {
	my ($self, $module) = @_;

	my $url = "$self->{api_url}/release/$module";

	my $release_data = $self->_fetch_data($url);
	if(!$release_data) {
		$self->{'logger'}->warn("Failed to parse MetaCPAN response for $module");
		return 0;
	}

	# Extract dependencies
	my $dependencies = $release_data->{dependency} || [];
	foreach my $dependency (@$dependencies) {
		# Skip if the dependency is marked as optional
		next if $dependency->{phase} && $dependency->{phase} eq 'develop';

		my $dep_module = $dependency->{module};
		my $dep_status = $self->_check_module_status($dep_module);

		if ($dep_status->{deprecated} || $dep_status->{backpan_only}) {
			return 1; # Found an unsupported dependency
		}
	}

	return 0; # No unsupported dependencies found
}

sub _check_module_status {
	my ($self, $module) = @_;

	my $url = "$self->{api_url}/module/$module";

	my $module_data = $self->_fetch_data($url);
	# my $module_data = eval { decode_json($response->{content}) };
	if (!$module_data) {
		$self->{'logger'}->warn("Failed to parse MetaCPAN response for $module");
		return {};
	}

	return {
		deprecated => $module_data->{status} && $module_data->{status} eq 'deprecated',
		backpan_only => $module_data->{maturity} && $module_data->{maturity} eq 'backpan',
	};
}

1;

__END__

=head1 AUTHOR

Nigel Horne <njh@bandsman.co.uk>

=head1 BUGS

The cpantesters API, L<https://api.cpantesters.org/>, is currently unavailable,
so the routine _has_recent_tests() currently always returns 1.

=head1 LICENCE

This program is released under the following licence: GPL2
