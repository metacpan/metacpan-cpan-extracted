package App::MARC::Validator;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Cpanel::JSON::XS;
use English;
use Getopt::Std;
use IO::Barf qw(barf);
use MARC::Validator;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use Unicode::UTF8 qw(encode_utf8);

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
		'd' => 0,
		'h' => 0,
		'l' => 0,
		'o' => undef,
		'p' => 0,
		'v' => 0,
	};
	if (! getopts('dhlo:pv', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}) {

		$self->_usage;
		return 1;
	}
	if (! $self->{'_opts'}->{'l'}) {
		if (@ARGV < 1) {
			$self->_usage;
			return 1;
		}
		$self->{'_marc_xml_files'} = [@ARGV];
	}

	my $exit_code;
	if ($self->{'_opts'}->{'l'}) {
		$exit_code = $self->_list_plugins;
	} else {
		$exit_code = $self->_process_validation;
	}

	return $exit_code;
}

sub _init_plugins {
	my $self = shift;

	$self->{'_plugins'} = [];
	foreach my $plugin (MARC::Validator::plugins) {
		my $plugin_obj = $plugin->new(
			'debug' => $self->{'_opts'}->{'d'},
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
	my $ret_hr = {};
	foreach my $marc_xml_file (@{$self->{'_marc_xml_files'}}) {
		my $marc_file = MARC::File::XML->in($marc_xml_file);
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

	my $output_struct_hr = {};
	foreach my $plugin_obj (@{$self->{'_plugins'}}) {
		$output_struct_hr->{$plugin_obj->name} = $plugin_obj->struct;
	}

	# JSON output.
	my $j = Cpanel::JSON::XS->new;
	if ($self->{'_opts'}->{'p'}) {
		$j = $j->pretty;
	}
	my $json = $j->canonical(1)->encode($output_struct_hr);

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

	print STDERR "Usage: $0 [-d] [-h] [-l] [-o output_file] [-p] [-v] [--version] marc_xml_file..\n";
	print STDERR "\t-d\t\tDebug mode.\n";
	print STDERR "\t-h\t\tPrint help.\n";
	print STDERR "\t-l\t\tList of plugins.\n";
	print STDERR "\t-o output_file\tOutput file (default is STDOUT).\n";
	print STDERR "\t-p\t\tPretty print JSON output.\n";
	print STDERR "\t-v\t\tVerbose mode.\n";
	print STDERR "\t--version\tPrint version.\n";
	print STDERR "\tmarc_xml_file..\tMARC XML file(s).\n";

	return;
}

1;
