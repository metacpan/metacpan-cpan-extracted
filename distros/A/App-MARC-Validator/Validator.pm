package App::MARC::Validator;

use strict;
use warnings;

use App::MARC::Validator::Utils qw(obj_to_json);
use Class::Utils qw(set_params);
use Data::MARC::Validator::Report;
use DateTime;
use English;
use Getopt::Std;
use IO::Barf qw(barf);
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Validator 0.06;
use MARC::Validator::Filter;
use Unicode::UTF8 qw(encode_utf8);

our $VERSION = 0.06;

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
		'd' => 0,
		'f' => 0,
		'h' => 0,
		'i' => '001',
		'l' => 0,
		'o' => undef,
		'p' => 0,
		'r' => 0,
		'v' => 0,
	};
	if (! getopts('dfhi:lo:prv', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}) {

		$self->_usage;
		return 1;
	}
	if (! $self->{'_opts'}->{'f'}
		&& ! $self->{'_opts'}->{'l'}) {

		if (@ARGV < 1) {
			$self->_usage;
			return 1;
		}
		$self->{'_marc_xml_files'} = [@ARGV];
	}

	my $exit_code;
	if ($self->{'_opts'}->{'l'}) {
		$exit_code = $self->_list_plugins;
	} elsif ($self->{'_opts'}->{'f'}) {
		$exit_code = $self->_list_filter_plugins;
	} else {
		$exit_code = $self->_process_validation;
	}

	return $exit_code;
}

sub _list_filter_plugins {
	my $self = shift;

	my @plugins = MARC::Validator::Filter::plugins;

	print "List of filter plugins:\n";
	print map { '- '.$_ } join "\n- ", @plugins;
	print "\n";

	return 0;
}

sub _init_plugins {
	my $self = shift;

	$self->{'_plugins'} = [];
	foreach my $plugin (MARC::Validator::plugins) {
		my $plugin_obj = $plugin->new(
			'debug' => $self->{'_opts'}->{'d'},
			'record_id_def' => $self->{'_opts'}->{'i'},
			'recommendation' => $self->{'_opts'}->{'r'},
			'verbose' => $self->{'_opts'}->{'v'},
		);
		$plugin_obj->init;
		push @{$self->{'_plugins'}}, $plugin_obj;
	}

	return;
}

sub _list_plugins {
	my $self = shift;

	my @plugins = MARC::Validator::plugins;

	print "List of plugins:\n";
	print map { '- '.$_ } join "\n- ", @plugins;
	print "\n";

	return 0;
}

sub _process_validation {
	my $self = shift;

	$self->_init_plugins;
	foreach my $marc_xml_file (@{$self->{'_marc_xml_files'}}) {
		my $marc_file = MARC::File::XML->in($marc_xml_file);
		if (! defined $marc_file) {
			print STDERR "Cannot open MARC file '$marc_xml_file'.\n";
			print STDERR "Error: $MARC::File::ERROR\n";
			return 1;
		}
		my $num = 0;
		my $previous_record;
		while (1) {
			$num++;
			my $record = eval {
				$marc_file->next;
			};
			if ($EVAL_ERROR) {
				print STDERR "Cannot process file '$marc_xml_file', record '$num'.".
					(
						defined $previous_record
						? "Previous record is ".encode_utf8($previous_record->title)."\n"
						: ''
					);
				print STDERR "Error: $EVAL_ERROR\n";
				next;
			}
			if (! defined $record) {
				last;
			}
			$previous_record = $record;

			# Collect statistics.
			foreach my $plugin_obj (@{$self->{'_plugins'}}) {
				$plugin_obj->process($record);
			}
		}
	}
	$self->_postprocess_plugins;

	my @plugin_reports;
	foreach my $plugin_obj (@{$self->{'_plugins'}}) {
		push @plugin_reports, $plugin_obj->struct;
	}
	my $report = Data::MARC::Validator::Report->new(
		'datetime' => DateTime->now,
		'plugins' => \@plugin_reports,
	);

	my $json = obj_to_json($self, $report);

	# Save to file.
	if (defined $self->{'_opts'}->{'o'}) {
		barf($self->{'_opts'}->{'o'}, encode_utf8($json));

	# Print to STDOUT.
	} else {
		print encode_utf8($json);
	}

	return 0;
}

sub _postprocess_plugins {
	my $self = shift;

	foreach my $plugin_obj (@{$self->{'_plugins'}}) {
		$plugin_obj->postprocess;
	}

	return;
}

sub _usage {
	my $self = shift;

	print STDERR "Usage: $0 [-d] [-f] [-h] [-i id] [-l] [-o output_file] [-p] [-r] [-v] [--version] marc_xml_file..\n";
	print STDERR "\t-d\t\tDebug mode.\n";
	print STDERR "\t-f\t\tList of filter plugins.\n";
	print STDERR "\t-h\t\tPrint help.\n";
	print STDERR "\t-i id\t\tRecord identifier (default value is 001).\n";
	print STDERR "\t-l\t\tList of plugins.\n";
	print STDERR "\t-o output_file\tOutput file (default is STDOUT).\n";
	print STDERR "\t-p\t\tPretty print JSON output.\n";
	print STDERR "\t-r\t\tRecommendations.\n";
	print STDERR "\t-v\t\tVerbose mode.\n";
	print STDERR "\t--version\tPrint version.\n";
	print STDERR "\tmarc_xml_file..\tMARC XML file(s).\n";

	return;
}

1;
