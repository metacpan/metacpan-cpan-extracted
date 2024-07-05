package App::MARC::Filter;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use Getopt::Std;
use List::MoreUtils qw(none);
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use Readonly;
use Unicode::UTF8 qw(encode_utf8 decode_utf8);

Readonly::Array our @OUTPUT_FORMATS => qw(ascii xml);

our $VERSION = 0.03;

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
		'h' => 0,
		'o' => 'xml',
		'r' => 0,
	};
	if (! getopts('ho:r', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 4) {

		print STDERR "Usage: $0 [-h] [-o format] [-r] [--version] marc_xml_file field subfield value\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-o format\tOutput MARC format. Possible formats are ascii, xml.\n";
		print STDERR "\t-r\t\tUse value as Perl regexp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tmarc_xml_file\tMARC XML file.\n";
		print STDERR "\tfield\t\tMARC field.\n";
		print STDERR "\tsubfield\tMARC subfield.\n";
		print STDERR "\tvalue\t\tMARC field/subfield value to filter.\n";
		return 1;
	}
	$self->{'_marc_xml_file'} = shift @ARGV;
	$self->{'_marc_field'} = shift @ARGV;
	$self->{'_marc_subfield'} = shift @ARGV;
	$self->{'_marc_value'} = decode_utf8(shift @ARGV);

	# Check output format.
	if (none { $self->{'_opts'}->{'o'} eq $_ } @OUTPUT_FORMATS) {
		err "Output format '$self->{'_opts'}->{'o'}' doesn't supported.";
	}

	my $marc_file = MARC::File::XML->in($self->{'_marc_xml_file'});
	my @ret;
	my $num = 1;
	my $previous_record;
	while (1) {
		my $record = eval {
			$marc_file->next;
		};
		if ($EVAL_ERROR) {
			print STDERR "Cannot process '$num' record. ".
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

		my @fields = $record->field($self->{'_marc_field'});
		foreach my $field (@fields) {
			my @subfield_values = $field->subfield($self->{'_marc_subfield'});
			foreach my $subfield_value (@subfield_values) {
				if (defined $subfield_value) {
					my $match = 0;
					if ($self->{'_opts'}->{'r'}) {
						if ($subfield_value =~ m/$self->{'_marc_value'}/ms) {
							$match = 1;
						}
					} else {
						if ($subfield_value eq $self->{'_marc_value'}) {
							$match = 1;
						}
					}
					if ($match) {
						push @ret, $record;
					}
				}
			}
		}

		$num++;
	}

	# Print out.
	$num = 0;
	foreach my $ret (@ret) {
		if (! $num) {
			if ($self->{'_opts'}->{'o'} eq 'xml') {
				print MARC::File::XML::header()."\n";
			}
		}

		if ($self->{'_opts'}->{'o'} eq 'xml') {
			print encode_utf8(MARC::File::XML::record($ret))."\n";
		} elsif ($self->{'_opts'}->{'o'} eq 'ascii') {
			print encode_utf8($ret->as_formatted)."\n";
		}

		$num++;
	}
	if ($num) {
		if ($self->{'_opts'}->{'o'} eq 'xml') {
			print MARC::File::XML::footer()."\n";
		}
	}
	
	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::MARC::Filter - Base class for marc-count script.

=head1 SYNOPSIS

 use App::MARC::Filter;

 my $app = App::MARC::Filter->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::MARC::Filter->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 run():
         Output format '%s' doesn't supported.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::MARC::Filter;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);
 use MIME::Base64;

 # Content.
 my $marc_xml_example = <<'END';
 PD94bWwgdmVyc2lvbiA9ICIxLjAiIGVuY29kaW5nID0gIlVURi04Ij8+CiAgPGNvbGxlY3Rpb24g
 eG1sbnM9Imh0dHA6Ly93d3cubG9jLmdvdi9NQVJDMjEvc2xpbSIKeG1sbnM6eHNpPSJodHRwOi8v
 d3d3LnczLm9yZy8yMDAxL1hNTFNjaGVtYS1pbnN0YW5jZSIKeHNpOnNjaGVtYUxvY2F0aW9uPSJo
 dHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0KaHR0cDovL3d3dy5sb2MuZ292L3N0YW5kYXJk
 cy9tYXJjeG1sL3NjaGVtYS9NQVJDMjFzbGltLnhzZCI+CiAgICA8cmVjb3JkIHhtbG5zPSJodHRw
 Oi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iCnhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcv
 MjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCnhzaTpzY2hlbWFMb2NhdGlvbj0iaHR0cDovL3d3dy5s
 b2MuZ292L01BUkMyMS9zbGltCmh0dHA6Ly93d3cubG9jLmdvdi9zdGFuZGFyZHMvbWFyY3htbC9z
 Y2hlbWEvTUFSQzIxc2xpbS54c2QiPgogICAgICA8bGVhZGVyPiAgICAgbmFtIGEyMiAgICAgICAg
 NDUwMDwvbGVhZGVyPgogICAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDAxIj5jazgzMDAwNzg8L2Nv
 bnRyb2xmaWVsZD4KICAgICAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMyI+Q1ogUHJOSzwvY29udHJv
 bGZpZWxkPgogICAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDA1Ij4yMDIxMDMwOTEyMTk1MS4wPC9j
 b250cm9sZmllbGQ+CiAgICAgIDxjb250cm9sZmllbGQgdGFnPSIwMDciPnR1PC9jb250cm9sZmll
 bGQ+CiAgICAgIDxjb250cm9sZmllbGQgdGFnPSIwMDgiPjgzMDMwNHMxOTgyICAgIHhyIGEgICAg
 ICAgICB1MHwwIHwgY3plPC9jb250cm9sZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIwMTUi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5jbmIwMDAwMDAw
 OTY8L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjAy
 MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9InEiPihCcm/Fvi4p
 IDo8L3N1YmZpZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJjIj45IEvEjXM8L3N1YmZpZWxk
 PgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjAzNSIgaW5kMT0iICIg
 aW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPihPQ29MQykzOTU2MDY2NDwvc3Vi
 ZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iMDQwIiBpbmQx
 PSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+QUJBMDAxPC9zdWJmaWVs
 ZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVsZD4KICAgICAgICA8c3Vi
 ZmllbGQgY29kZT0iZCI+QUJBMDAxPC9zdWJmaWVsZD4KICAgICAgPC9kYXRhZmllbGQ+CiAgICAg
 IDxkYXRhZmllbGQgdGFnPSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICAgIDxzdWJmaWVs
 ZCBjb2RlPSJhIj4zNTIvMzUzPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iMiI+
 dW5kZWY8L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9
 IjA4MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPjMzOC40
 Njwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4K
 ICAgICAgPC9kYXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIxMDAiIGluZDE9IjEiIGlu
 ZDI9IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5HYWJyaWVsLCBWbGFkaXNsYXY8L3N1
 YmZpZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSI3Ij5temsyMDE0ODUyNzIzPC9zdWJmaWVs
 ZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iNCI+YXV0PC9zdWJmaWVsZD4KICAgICAgPC9kYXRh
 ZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSIyNDUiIGluZDE9IjEiIGluZDI9IjAiPgogICAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5TbHXFvmJ5IHYgc3lzdMOpbXUgbsOhcm9kbsOtY2ggdsO9
 Ym9yxa8gOjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPnZ5YnJhbsOpIGth
 cGl0b2x5IDogdXLEjWVubyBwcm8gcG9zbC4gZmFrLiBvYmNob2Ruw60sIG9ib3IgRWtvbm9taWth
 IHNsdcW+ZWIgYSBjZXN0b3Zuw61obyBydWNodSAvPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmll
 bGQgY29kZT0iYyI+VmxhZGlzbGF2IEdhYnJpZWwsIExhZGlzbGF2IFphcGFkbG88L3N1YmZpZWxk
 PgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjI1MCIgaW5kMT0iICIg
 aW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPjEuIHZ5ZC48L3N1YmZpZWxkPgog
 ICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9IjI2MCIgaW5kMT0iICIgaW5k
 Mj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPlByYWhhIDo8L3N1YmZpZWxkPgogICAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5TUE4sPC9zdWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQg
 Y29kZT0iYyI+MTk4Mjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImUiPihQxZnD
 rWJyYW0gOjwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImYiPlRaIDY2KTwvc3Vi
 ZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iMzAwIiBpbmQx
 PSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+MTkyIHMuIDo8L3N1YmZp
 ZWxkPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5zY2jDqW1hdGEgOzwvc3ViZmllbGQ+CiAg
 ICAgICAgPHN1YmZpZWxkIGNvZGU9ImMiPjMwIGNtPC9zdWJmaWVsZD4KICAgICAgPC9kYXRhZmll
 bGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICAg
 IDxzdWJmaWVsZCBjb2RlPSJhIj5Sb3ptbi48L3N1YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4K
 ICAgICAgPGRhdGFmaWVsZCB0YWc9IjUwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1
 YmZpZWxkIGNvZGU9ImEiPjMwMCB2w710Ljwvc3ViZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgog
 ICAgICA8ZGF0YWZpZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgICAgICA8c3Vi
 ZmllbGQgY29kZT0iYSI+S2FwLiA0LiBuYXBzLiBSxa/FvmVuYSBEdWRvdsOhLCBrYXAuIDguIGpl
 IHNlc3QuIHogcMWZw61zcMSbdmvFryByxa96LiBhdXRvcsWvPC9zdWJmaWVsZD4KICAgICAgPC9k
 YXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI1NTAiIGluZDE9IiAiIGluZDI9IiAiPgog
 ICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5WeWRhdmF0ZWw6IFbFoEUgdiBQcmF6ZTwvc3ViZmll
 bGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iNjU1IiBpbmQxPSIg
 IiBpbmQyPSI3Ij4KICAgICAgICA8c3ViZmllbGQgY29kZT0iYSI+dcSNZWJuaWNlIHZ5c29rw71j
 aCDFoWtvbDwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjciPmZkMTMzNzcyPC9z
 dWJmaWVsZD4KICAgICAgICA8c3ViZmllbGQgY29kZT0iMiI+Y3plbmFzPC9zdWJmaWVsZD4KICAg
 ICAgPC9kYXRhZmllbGQ+CiAgICAgIDxkYXRhZmllbGQgdGFnPSI3MDAiIGluZDE9IjEiIGluZDI9
 IiAiPgogICAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5aYXBhZGxvLCBMYWRpc2xhdjwvc3ViZmll
 bGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjQiPmF1dDwvc3ViZmllbGQ+CiAgICAgIDwvZGF0
 YWZpZWxkPgogICAgICA8ZGF0YWZpZWxkIHRhZz0iNzEwIiBpbmQxPSIyIiBpbmQyPSIgIj4KICAg
 ICAgICA8c3ViZmllbGQgY29kZT0iYSI+Vnlzb2vDoSDFoWtvbGEgZWtvbm9taWNrw6EgdiBQcmF6
 ZTwvc3ViZmllbGQ+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9IjciPmtuMjAwMTA3MDk0MDM8L3N1
 YmZpZWxkPgogICAgICA8L2RhdGFmaWVsZD4KICAgICAgPGRhdGFmaWVsZCB0YWc9Ijk5OCIgaW5k
 MT0iICIgaW5kMj0iICI+CiAgICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPmh0dHA6Ly9hbGVwaC5u
 a3AuY3ovRi8/ZnVuYz1kaXJlY3QmYW1wO2RvY19udW1iZXI9MDAwMDAwMDk2JmFtcDtsb2NhbF9i
 YXNlPUNOQjwvc3ViZmllbGQ+CiAgICAgIDwvZGF0YWZpZWxkPgogICAgPC9yZWNvcmQ+Cgo8cmVj
 b3JkIHhtbG5zPSJodHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iCnhtbG5zOnhzaT0iaHR0
 cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiCnhzaTpzY2hlbWFMb2NhdGlv
 bj0iaHR0cDovL3d3dy5sb2MuZ292L01BUkMyMS9zbGltCmh0dHA6Ly93d3cubG9jLmdvdi9zdGFu
 ZGFyZHMvbWFyY3htbC9zY2hlbWEvTUFSQzIxc2xpbS54c2QiPgogIDxsZWFkZXI+ICAgICBuYW0g
 YTIyICAgICAgICA0NTAwPC9sZWFkZXI+CiAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMSI+Y2s4MzAw
 MDgwPC9jb250cm9sZmllbGQ+CiAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMyI+Q1ogUHJOSzwvY29u
 dHJvbGZpZWxkPgogIDxjb250cm9sZmllbGQgdGFnPSIwMDUiPjIwMDUwNTE3MDk0MjEyLjA8L2Nv
 bnRyb2xmaWVsZD4KICA8Y29udHJvbGZpZWxkIHRhZz0iMDA3Ij50dTwvY29udHJvbGZpZWxkPgog
 IDxjb250cm9sZmllbGQgdGFnPSIwMDgiPjgzMDMxNnMxOTgzICAgIHhyICAgICAgICAgICB1MHww
 ICAgY3plPC9jb250cm9sZmllbGQ+CiAgPGRhdGFmaWVsZCB0YWc9IjAxNSIgaW5kMT0iICIgaW5k
 Mj0iICI+CiAgICA8c3ViZmllbGQgY29kZT0iYSI+Y25iMDAwMDAwMDk4PC9zdWJmaWVsZD4KICA8
 L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMDIwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAg
 IDxzdWJmaWVsZCBjb2RlPSJxIj4oQnJvxb4uKSA6PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBj
 b2RlPSJjIj4zMCBLxI1zPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRh
 Zz0iMDM1IiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj4oT0NvTEMp
 Mzk1NjA2ODg8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSIwNDAi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPkFCQTAwMTwvc3ViZmll
 bGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBj
 b2RlPSJkIj5BQkEwMDE8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFn
 PSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPjMzOS45MjM8
 L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4KICA8L2Rh
 dGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMDgwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxz
 dWJmaWVsZCBjb2RlPSJhIj4zMzguNDU8L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9IjIi
 PnVuZGVmPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iMTAwIiBp
 bmQxPSIxIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5WbGFkeWthLCBKb3NlZjwv
 c3ViZmllbGQ+CiAgICA8c3ViZmllbGQgY29kZT0iNyI+angyMDA1MDYyODAzNjwvc3ViZmllbGQ+
 CiAgICA8c3ViZmllbGQgY29kZT0iNCI+YXV0PC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8
 ZGF0YWZpZWxkIHRhZz0iMjQ1IiBpbmQxPSIxIiBpbmQyPSIwIj4KICAgIDxzdWJmaWVsZCBjb2Rl
 PSJhIj5Ww712b2ogYSBwbMOhbnkgcm96dm9qZSBwcsWvbXlzbHUgZXZyb3Bza8O9Y2ggemVtw60g
 UlZIUCAxOTc2LTE5ODUgLzwvc3ViZmllbGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYyI+dnlwcmFj
 LiBKb3NlZiBWbGFkeWthPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRh
 Zz0iMjYwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5QcmFoYSA6
 PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBjb2RlPSJiIj7DmlZURUksPC9zdWJmaWVsZD4KICAg
 IDxzdWJmaWVsZCBjb2RlPSJjIj4xOTgzPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0
 YWZpZWxkIHRhZz0iMzAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJh
 Ij41NSBzLiA6PC9zdWJmaWVsZD4KICAgIDxzdWJmaWVsZCBjb2RlPSJiIj50Yi4gOzwvc3ViZmll
 bGQ+CiAgICA8c3ViZmllbGQgY29kZT0iYyI+MzAgY208L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxk
 PgogIDxkYXRhZmllbGQgdGFnPSI0OTAiIGluZDE9IjEiIGluZDI9IiAiPgogICAgPHN1YmZpZWxk
 IGNvZGU9ImEiPlB1Ymxpa2FjZSBTSVZPIDs8L3N1YmZpZWxkPgogICAgPHN1YmZpZWxkIGNvZGU9
 InYiPjE4OTQ8L3N1YmZpZWxkPgogIDwvZGF0YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSI1MDAi
 IGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1YmZpZWxkIGNvZGU9ImEiPlDFmWVobC4gbGl0PC9z
 dWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZpZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBp
 bmQyPSIgIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Sb3ptbi48L3N1YmZpZWxkPgogIDwvZGF0
 YWZpZWxkPgogIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgPHN1
 YmZpZWxkIGNvZGU9ImEiPlBvem4uPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KICA8ZGF0YWZp
 ZWxkIHRhZz0iODMwIiBpbmQxPSIgIiBpbmQyPSIwIj4KICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Q
 dWJsaWthY2UgU0lWTzwvc3ViZmllbGQ+CiAgPC9kYXRhZmllbGQ+CiAgPGRhdGFmaWVsZCB0YWc9
 Ijk5OCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICA8c3ViZmllbGQgY29kZT0iYSI+aHR0cDovL2Fs
 ZXBoLm5rcC5jei9GLz9mdW5jPWRpcmVjdCZhbXA7ZG9jX251bWJlcj0wMDAwMDAwOTgmYW1wO2xv
 Y2FsX2Jhc2U9Q05CPC9zdWJmaWVsZD4KICA8L2RhdGFmaWVsZD4KPC9yZWNvcmQ+Cgo8L2NvbGxl
 Y3Rpb24+Cg==
 END

 my ($temp_file, $temp_file_fh) = tempfile();

 barf($temp_file_fh, decode_base64($marc_xml_example));

 # Arguments.
 @ARGV = (
         $temp_file,
         '015',
         'a',
         'cnb000000096',
 );

 # Run.
 exit App::MARC::Filter->new->run;

 # Output:
 # <?xml version="1.0" encoding="UTF-8"?>
 # <collection
 #   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
 #   xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
 #   xmlns="http://www.loc.gov/MARC21/slim">
 # 
 # <record>
 #   <leader>     nam a22        4500</leader>
 #   <controlfield tag="001">ck8300078</controlfield>
 #   <controlfield tag="003">CZ PrNK</controlfield>
 #   <controlfield tag="005">20210309121951.0</controlfield>
 #   <controlfield tag="007">tu</controlfield>
 #   <controlfield tag="008">830304s1982    xr a         u0|0 | cze</controlfield>
 #   <datafield tag="015" ind1=" " ind2=" ">
 #     <subfield code="a">cnb000000096</subfield>
 #   </datafield>
 #   <datafield tag="020" ind1=" " ind2=" ">
 #     <subfield code="q">(Brož.) :</subfield>
 #     <subfield code="c">9 Kčs</subfield>
 #   </datafield>
 #   <datafield tag="035" ind1=" " ind2=" ">
 #     <subfield code="a">(OCoLC)39560664</subfield>
 #   </datafield>
 #   <datafield tag="040" ind1=" " ind2=" ">
 #     <subfield code="a">ABA001</subfield>
 #     <subfield code="b">cze</subfield>
 #     <subfield code="d">ABA001</subfield>
 #   </datafield>
 #   <datafield tag="080" ind1=" " ind2=" ">
 #     <subfield code="a">352/353</subfield>
 #     <subfield code="2">undef</subfield>
 #   </datafield>
 #   <datafield tag="080" ind1=" " ind2=" ">
 #     <subfield code="a">338.46</subfield>
 #     <subfield code="2">undef</subfield>
 #   </datafield>
 #   <datafield tag="100" ind1="1" ind2=" ">
 #     <subfield code="a">Gabriel, Vladislav</subfield>
 #     <subfield code="7">mzk2014852723</subfield>
 #     <subfield code="4">aut</subfield>
 #   </datafield>
 #   <datafield tag="245" ind1="1" ind2="0">
 #     <subfield code="a">Služby v systému národních výborů :</subfield>
 #     <subfield code="b">vybrané kapitoly : určeno pro posl. fak. obchodní, obor Ekonomika služeb a cestovního ruchu /</subfield>
 #     <subfield code="c">Vladislav Gabriel, Ladislav Zapadlo</subfield>
 #   </datafield>
 #   <datafield tag="250" ind1=" " ind2=" ">
 #     <subfield code="a">1. vyd.</subfield>
 #   </datafield>
 #   <datafield tag="260" ind1=" " ind2=" ">
 #     <subfield code="a">Praha :</subfield>
 #     <subfield code="b">SPN,</subfield>
 #     <subfield code="c">1982</subfield>
 #     <subfield code="e">(Příbram :</subfield>
 #     <subfield code="f">TZ 66)</subfield>
 #   </datafield>
 #   <datafield tag="300" ind1=" " ind2=" ">
 #     <subfield code="a">192 s. :</subfield>
 #     <subfield code="b">schémata ;</subfield>
 #     <subfield code="c">30 cm</subfield>
 #   </datafield>
 #   <datafield tag="500" ind1=" " ind2=" ">
 #     <subfield code="a">Rozmn.</subfield>
 #   </datafield>
 #   <datafield tag="500" ind1=" " ind2=" ">
 #     <subfield code="a">300 výt.</subfield>
 #   </datafield>
 #   <datafield tag="500" ind1=" " ind2=" ">
 #     <subfield code="a">Kap. 4. naps. Růžena Dudová, kap. 8. je sest. z příspěvků růz. autorů</subfield>
 #   </datafield>
 #   <datafield tag="550" ind1=" " ind2=" ">
 #     <subfield code="a">Vydavatel: VŠE v Praze</subfield>
 #   </datafield>
 #   <datafield tag="655" ind1=" " ind2="7">
 #     <subfield code="a">učebnice vysokých škol</subfield>
 #     <subfield code="7">fd133772</subfield>
 #     <subfield code="2">czenas</subfield>
 #   </datafield>
 #   <datafield tag="700" ind1="1" ind2=" ">
 #     <subfield code="a">Zapadlo, Ladislav</subfield>
 #     <subfield code="4">aut</subfield>
 #   </datafield>
 #   <datafield tag="710" ind1="2" ind2=" ">
 #     <subfield code="a">Vysoká škola ekonomická v Praze</subfield>
 #     <subfield code="7">kn20010709403</subfield>
 #   </datafield>
 #   <datafield tag="998" ind1=" " ind2=" ">
 #     <subfield code="a">http://aleph.nkp.cz/F/?func=direct&amp;doc_number=000000096&amp;local_base=CNB</subfield>
 #   </datafield>
 # </record>
 # 
 # </collection>

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<List::MoreUtils>,
L<MARC::File::XML>,
L<Readonly>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-MARC-Filter>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
