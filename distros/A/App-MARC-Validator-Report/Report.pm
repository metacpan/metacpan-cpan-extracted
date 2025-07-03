package App::MARC::Validator::Report;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Cpanel::JSON::XS;
use Error::Pure qw(err);
use Getopt::Std;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'e' => 'all',
		'h' => 0,
		'l' => 0,
		'p' => 'all',
		'v' => 0,
	};
	if (! getopts('e:hlp:v', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		$self->_usage;
		return 1;
	}
	my $report_file = $ARGV[0];

	my $exit_code = $self->_process_report($report_file);
	if ($exit_code != 0) {
		return $exit_code;
	}

	if ($self->{'_opts'}->{'l'}) {
		$exit_code = $self->_process_list;
	} else {
		$exit_code = $self->_process_errors;
	}

	return $exit_code;
}

sub _process_errors {
	my $self = shift;

	foreach my $plugin (keys %{$self->{'_list'}}) {
		if ($self->{'_opts'}->{'p'} eq 'all' || $self->{'_opts'}->{'p'} eq $plugin) {
			if (keys %{$self->{'_list'}->{$plugin}} == 0) {
				next;
			}
			print "Plugin '$plugin':\n";
			foreach my $error (sort keys %{$self->{'_list'}->{$plugin}}) {
				if ($self->{'_opts'}->{'e'} eq 'all' || $self->{'_opts'}->{'e'} eq $error) {
					print "- $error\n";
					foreach my $id (sort @{$self->{'_list'}->{$plugin}->{$error}}) {
						my @err = @{$self->{'_report'}->{$plugin}->{'checks'}->{'not_valid'}->{$id}};
						my $struct_hr = {};
						foreach my $err_hr (@err) {
							if ($err_hr->{'error'} eq $error) {
								$struct_hr = $err_hr->{'params'};
							}
						}
						print "-- $id";
						my $i = 0;
						foreach my $param_key (keys %{$struct_hr}) {
							if ($i == 0) {
								print ': ';
							} else {
								print ', ';
							}
							print "$param_key: '".$struct_hr->{$param_key}."'";
							$i++;
						}
						print "\n";
					}
				}
			}
		}
	}

	return 0;
}

sub _process_list {
	my $self = shift;

	foreach my $plugin (keys %{$self->{'_list'}}) {
		if ($self->{'_opts'}->{'p'} eq 'all' || $self->{'_opts'}->{'p'} eq $plugin) {
			if (keys %{$self->{'_list'}->{$plugin}} == 0) {
				next;
			}
			print "Plugin '$plugin':\n";
			foreach my $error (sort keys %{$self->{'_list'}->{$plugin}}) {
				print "- $error\n";
			}
		}
	}

	return 0;
}

sub _process_report {
	my ($self, $report_file) = @_;

	my $report = slurp($report_file);

	# JSON output.
	my $j = Cpanel::JSON::XS->new;
	$self->{'_report'} = $j->decode($report);

	$self->{'_list'} = {};
	foreach my $plugin (keys %{$self->{'_report'}}) {
		if (! exists $self->{'_report'}->{$plugin}->{'checks'}) {
			err "Doesn't exist key '".$self->{'_report'}->{$plugin}->{'checks'}." in plugin $plugin.";
		}
		if (! exists $self->{'_report'}->{$plugin}->{'checks'}->{'not_valid'}) {
			err "Doesn't exist key '".$self->{'_report'}->{$plugin}->{'checks'}->{'not_valid'}." in plugin $plugin.";
		}
		if (! exists $self->{'_list'}->{$plugin}) {
			$self->{'_list'}->{$plugin} = {};
		}
		my $not_valid_hr = $self->{'_report'}->{$plugin}->{'checks'}->{'not_valid'};
		foreach my $record_id (keys %{$not_valid_hr}) {
			foreach my $error_hr (@{$not_valid_hr->{$record_id}}) {
				if (! exists $self->{'_list'}->{$plugin}->{$error_hr->{'error'}}) {
					$self->{'_list'}->{$plugin}->{$error_hr->{'error'}} = [$record_id];
				} else {
					push @{$self->{'_list'}->{$plugin}->{$error_hr->{'error'}}}, $record_id;
				}
			}
		}
	}

	return 0;
}

sub _usage {
	my $self = shift;

	print STDERR "Usage: $0 [-h] [-l] [-p plugin] [-v] [--version] report.json\n";
	print STDERR "\t-h\t\tPrint help.\n";
	print STDERR "\t-l\t\tList unique errors.\n";
	print STDERR "\t-p\t\tUse plugin (default all).\n";
	print STDERR "\t-v\t\tVerbose mode.\n";
	print STDERR "\t--version\tPrint version.\n";
	print STDERR "\treport.json\tmarc-validator JSON report.\n";

	return;
}

1;
