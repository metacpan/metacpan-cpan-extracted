package App::MARC::Leader;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Getopt::Std;
use MARC::File::XML (BinaryEncoding => 'utf8', RecordFormat => 'MARC21');
use MARC::Leader;
use MARC::Leader::Print;

our $VERSION = 0.05;

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
		'a' => undef,
		'd' => 0,
		'f' => undef,
		'h' => 0,
	};
	if (! getopts('adf:h', $self->{'_opts'}) || (! $self->{'_opts'}->{'f'}
		&& @ARGV < 1) || $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-a] [-d] [-f marc_xml_file] [-h] [--version] [leader_string]\n";
		print STDERR "\t-a\t\t\tPrint with ANSI colors (or use NO_COLOR/COLOR env variables).\n";
		print STDERR "\t-d\t\t\tDon't print description.\n";
		print STDERR "\t-f marc_xml_file\tMARC XML file.\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tleader_string\t\tMARC Leader string.\n";
		return 1;
	}

	my $marc_leader;
	if (! $self->{'_opts'}->{'f'}) {
		$marc_leader = $ARGV[0];
	} else {
		my $marc_file = MARC::File::XML->in($self->{'_opts'}->{'f'});
		# XXX Check
		$marc_leader = $marc_file->next->leader;
	}

	# Parse MARC leader.
	my $leader = MARC::Leader->new->parse($marc_leader);

	# Print information.
	print scalar MARC::Leader::Print->new(
		'mode_ansi' => $self->{'_opts'}->{'a'},
		'mode_desc' => ! $self->{'_opts'}->{'d'},
	)->print($leader);
	print "\n";

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::MARC::Leader - Base class for marc-leader script.

=head1 SYNOPSIS

 use App::MARC::Leader;

 my $app = App::MARC::Leader->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::MARC::Leader->new;

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

=head1 EXAMPLE1

=for comment filename=print_marc_leader_from_marc_xml_file.pl

 use strict;
 use warnings;

 use App::MARC::Leader;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);
 use MIME::Base64;

 # Content.
 my $marc_xml_example = <<'END';
 PD94bWwgdmVyc2lvbiA9ICIxLjAiIGVuY29kaW5nID0gIlVURi04Ij8+Cjxjb2xsZWN0aW9uIHht
 bG5zPSJodHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iIHhtbG5zOnhzaT0iaHR0cDovL3d3
 dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhzaTpzY2hlbWFMb2NhdGlvbj0iaHR0
 cDovL3d3dy5sb2MuZ292L01BUkMyMS9zbGltIGh0dHA6Ly93d3cubG9jLmdvdi9zdGFuZGFyZHMv
 bWFyY3htbC9zY2hlbWEvTUFSQzIxc2xpbS54c2QiPgogIDxyZWNvcmQgeG1sbnM9Imh0dHA6Ly93
 d3cubG9jLmdvdi9NQVJDMjEvc2xpbSIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAx
 L1hNTFNjaGVtYS1pbnN0YW5jZSIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vd3d3LmxvYy5n
 b3YvTUFSQzIxL3NsaW0gaHR0cDovL3d3dy5sb2MuZ292L3N0YW5kYXJkcy9tYXJjeG1sL3NjaGVt
 YS9NQVJDMjFzbGltLnhzZCI+CiAgICA8bGVhZGVyPiAgICAgbmFtIGEyMiAgICAgICAgNDUwMDwv
 bGVhZGVyPgogICAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMSI+Y2s4MzAwMDc4PC9jb250cm9sZmll
 bGQ+CiAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDAzIj5DWiBQck5LPC9jb250cm9sZmllbGQ+CiAg
 ICA8Y29udHJvbGZpZWxkIHRhZz0iMDA1Ij4yMDIxMDMwOTEyMTk1MS4wPC9jb250cm9sZmllbGQ+
 CiAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDA3Ij50dTwvY29udHJvbGZpZWxkPgogICAgPGNvbnRy
 b2xmaWVsZCB0YWc9IjAwOCI+ODMwMzA0czE5ODIgICAgeHIgYSAgICAgICAgIHUwfDAgfCBjemU8
 L2NvbnRyb2xmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSIwMTUiIGluZDE9IiAiIGluZDI9IiAi
 PgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+Y25iMDAwMDAwMDk2PC9zdWJmaWVsZD4KICAgIDwv
 ZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9IjAyMCIgaW5kMT0iICIgaW5kMj0iICI+CiAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJxIj4oQnJvxb4uKSA6PC9zdWJmaWVsZD4KICAgICAgPHN1YmZp
 ZWxkIGNvZGU9ImMiPjkgS8SNczwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRh
 ZmllbGQgdGFnPSIwMzUiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0i
 YSI+KE9Db0xDKTM5NTYwNjY0PC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFm
 aWVsZCB0YWc9IjA0MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJh
 Ij5BQkEwMDE8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVs
 ZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImQiPkFCQTAwMTwvc3ViZmllbGQ+CiAgICA8L2RhdGFm
 aWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8
 c3ViZmllbGQgY29kZT0iYSI+MzUyLzM1Mzwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2Rl
 PSIyIj51bmRlZjwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFn
 PSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+MzM4LjQ2
 PC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4KICAg
 IDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9IjEwMCIgaW5kMT0iMSIgaW5kMj0iICI+
 CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5HYWJyaWVsLCBWbGFkaXNsYXY8L3N1YmZpZWxkPgog
 ICAgICA8c3ViZmllbGQgY29kZT0iNyI+bXprMjAxNDg1MjcyMzwvc3ViZmllbGQ+CiAgICAgIDxz
 dWJmaWVsZCBjb2RlPSI0Ij5hdXQ8L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0
 YWZpZWxkIHRhZz0iMjQ1IiBpbmQxPSIxIiBpbmQyPSIwIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9
 ImEiPlNsdcW+YnkgdiBzeXN0w6ltdSBuw6Fyb2Ruw61jaCB2w71ib3LFryA6PC9zdWJmaWVsZD4K
 ICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPnZ5YnJhbsOpIGthcGl0b2x5IDogdXLEjWVubyBwcm8g
 cG9zbC4gZmFrLiBvYmNob2Ruw60sIG9ib3IgRWtvbm9taWthIHNsdcW+ZWIgYSBjZXN0b3Zuw61o
 byBydWNodSAvPC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImMiPlZsYWRpc2xhdiBH
 YWJyaWVsLCBMYWRpc2xhdiBaYXBhZGxvPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAg
 PGRhdGFmaWVsZCB0YWc9IjI1MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBj
 b2RlPSJhIj4xLiB2eWQuPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVs
 ZCB0YWc9IjI2MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Q
 cmFoYSA6PC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPlNQTiw8L3N1YmZpZWxk
 PgogICAgICA8c3ViZmllbGQgY29kZT0iYyI+MTk4Mjwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVs
 ZCBjb2RlPSJlIj4oUMWZw61icmFtIDo8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0i
 ZiI+VFogNjYpPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9
 IjMwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj4xOTIgcy4g
 Ojwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5zY2jDqW1hdGEgOzwvc3ViZmll
 bGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJjIj4zMCBjbTwvc3ViZmllbGQ+CiAgICA8L2RhdGFm
 aWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8
 c3ViZmllbGQgY29kZT0iYSI+Um96bW4uPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAg
 PGRhdGFmaWVsZCB0YWc9IjUwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBj
 b2RlPSJhIj4zMDAgdsO9dC48L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0YWZp
 ZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImEi
 PkthcC4gNC4gbmFwcy4gUsWvxb5lbmEgRHVkb3bDoSwga2FwLiA4LiBqZSBzZXN0LiB6IHDFmcOt
 c3DEm3Zrxa8gcsWvei4gYXV0b3LFrzwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxk
 YXRhZmllbGQgdGFnPSI1NTAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29k
 ZT0iYSI+VnlkYXZhdGVsOiBWxaBFIHYgUHJhemU8L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+
 CiAgICA8ZGF0YWZpZWxkIHRhZz0iNjU1IiBpbmQxPSIgIiBpbmQyPSI3Ij4KICAgICAgPHN1YmZp
 ZWxkIGNvZGU9ImEiPnXEjWVibmljZSB2eXNva8O9Y2ggxaFrb2w8L3N1YmZpZWxkPgogICAgICA8
 c3ViZmllbGQgY29kZT0iNyI+ZmQxMzM3NzI8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29k
 ZT0iMiI+Y3plbmFzPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0
 YWc9IjcwMCIgaW5kMT0iMSIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5aYXBh
 ZGxvLCBMYWRpc2xhdjwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSI0Ij5hdXQ8L3N1
 YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0YWZpZWxkIHRhZz0iNzEwIiBpbmQxPSIy
 IiBpbmQyPSIgIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPlZ5c29rw6EgxaFrb2xhIGVrb25v
 bWlja8OhIHYgUHJhemU8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0iNyI+a24yMDAx
 MDcwOTQwMzwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSI5
 OTgiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+aHR0cDovL2Fs
 ZXBoLm5rcC5jei9GLz9mdW5jPWRpcmVjdCZhbXA7ZG9jX251bWJlcj0wMDAwMDAwOTYmYW1wO2xv
 Y2FsX2Jhc2U9Q05CPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogIDwvcmVjb3JkPgo8L2Nv
 bGxlY3Rpb24+Cg==
 END

 my (undef, $temp_file) = tempfile();

 barf($temp_file, decode_base64($marc_xml_example));

 # Arguments.
 @ARGV = (
         '-f',
         $temp_file,
 );

 # Run.
 exit App::MARC::Leader->new->run;

 # Output (ANSI colors are used with set COLOR env variable):
 # Record length: 0
 # Record status: New
 # Type of record: Language material
 # Bibliographic level: Monograph/Item
 # Type of control: No specified type
 # Character coding scheme: UCS/Unicode
 # Indicator count: Number of character positions used for indicators
 # Subfield code count: Number of character positions used for a subfield code (2)
 # Base address of data: 0
 # Encoding level: Full level
 # Descriptive cataloging form: Non-ISBD
 # Multipart resource record level: Not specified or not applicable
 # Length of the length-of-field portion: Number of characters in the length-of-field portion of a Directory entry (4)
 # Length of the starting-character-position portion: Number of characters in the starting-character-position portion of a Directory entry (5)
 # Length of the implementation-defined portion: Number of characters in the implementation-defined portion of a Directory entry (0)
 # Undefined: Undefined

=head1 EXAMPLE2

=for comment filename=print_marc_leader_from_marc_xml_file_with_ansi.pl

 use strict;
 use warnings;

 use App::MARC::Leader;
 use IO::Barf qw(barf);
 use File::Temp qw(tempfile);
 use MIME::Base64;

 # Content.
 my $marc_xml_example = <<'END';
 PD94bWwgdmVyc2lvbiA9ICIxLjAiIGVuY29kaW5nID0gIlVURi04Ij8+Cjxjb2xsZWN0aW9uIHht
 bG5zPSJodHRwOi8vd3d3LmxvYy5nb3YvTUFSQzIxL3NsaW0iIHhtbG5zOnhzaT0iaHR0cDovL3d3
 dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhzaTpzY2hlbWFMb2NhdGlvbj0iaHR0
 cDovL3d3dy5sb2MuZ292L01BUkMyMS9zbGltIGh0dHA6Ly93d3cubG9jLmdvdi9zdGFuZGFyZHMv
 bWFyY3htbC9zY2hlbWEvTUFSQzIxc2xpbS54c2QiPgogIDxyZWNvcmQgeG1sbnM9Imh0dHA6Ly93
 d3cubG9jLmdvdi9NQVJDMjEvc2xpbSIgeG1sbnM6eHNpPSJodHRwOi8vd3d3LnczLm9yZy8yMDAx
 L1hNTFNjaGVtYS1pbnN0YW5jZSIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vd3d3LmxvYy5n
 b3YvTUFSQzIxL3NsaW0gaHR0cDovL3d3dy5sb2MuZ292L3N0YW5kYXJkcy9tYXJjeG1sL3NjaGVt
 YS9NQVJDMjFzbGltLnhzZCI+CiAgICA8bGVhZGVyPiAgICAgbmFtIGEyMiAgICAgICAgNDUwMDwv
 bGVhZGVyPgogICAgPGNvbnRyb2xmaWVsZCB0YWc9IjAwMSI+Y2s4MzAwMDc4PC9jb250cm9sZmll
 bGQ+CiAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDAzIj5DWiBQck5LPC9jb250cm9sZmllbGQ+CiAg
 ICA8Y29udHJvbGZpZWxkIHRhZz0iMDA1Ij4yMDIxMDMwOTEyMTk1MS4wPC9jb250cm9sZmllbGQ+
 CiAgICA8Y29udHJvbGZpZWxkIHRhZz0iMDA3Ij50dTwvY29udHJvbGZpZWxkPgogICAgPGNvbnRy
 b2xmaWVsZCB0YWc9IjAwOCI+ODMwMzA0czE5ODIgICAgeHIgYSAgICAgICAgIHUwfDAgfCBjemU8
 L2NvbnRyb2xmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSIwMTUiIGluZDE9IiAiIGluZDI9IiAi
 PgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+Y25iMDAwMDAwMDk2PC9zdWJmaWVsZD4KICAgIDwv
 ZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9IjAyMCIgaW5kMT0iICIgaW5kMj0iICI+CiAg
 ICAgIDxzdWJmaWVsZCBjb2RlPSJxIj4oQnJvxb4uKSA6PC9zdWJmaWVsZD4KICAgICAgPHN1YmZp
 ZWxkIGNvZGU9ImMiPjkgS8SNczwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRh
 ZmllbGQgdGFnPSIwMzUiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0i
 YSI+KE9Db0xDKTM5NTYwNjY0PC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFm
 aWVsZCB0YWc9IjA0MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJh
 Ij5BQkEwMDE8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0iYiI+Y3plPC9zdWJmaWVs
 ZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImQiPkFCQTAwMTwvc3ViZmllbGQ+CiAgICA8L2RhdGFm
 aWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8
 c3ViZmllbGQgY29kZT0iYSI+MzUyLzM1Mzwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2Rl
 PSIyIj51bmRlZjwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFn
 PSIwODAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+MzM4LjQ2
 PC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9IjIiPnVuZGVmPC9zdWJmaWVsZD4KICAg
 IDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9IjEwMCIgaW5kMT0iMSIgaW5kMj0iICI+
 CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5HYWJyaWVsLCBWbGFkaXNsYXY8L3N1YmZpZWxkPgog
 ICAgICA8c3ViZmllbGQgY29kZT0iNyI+bXprMjAxNDg1MjcyMzwvc3ViZmllbGQ+CiAgICAgIDxz
 dWJmaWVsZCBjb2RlPSI0Ij5hdXQ8L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0
 YWZpZWxkIHRhZz0iMjQ1IiBpbmQxPSIxIiBpbmQyPSIwIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9
 ImEiPlNsdcW+YnkgdiBzeXN0w6ltdSBuw6Fyb2Ruw61jaCB2w71ib3LFryA6PC9zdWJmaWVsZD4K
 ICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPnZ5YnJhbsOpIGthcGl0b2x5IDogdXLEjWVubyBwcm8g
 cG9zbC4gZmFrLiBvYmNob2Ruw60sIG9ib3IgRWtvbm9taWthIHNsdcW+ZWIgYSBjZXN0b3Zuw61o
 byBydWNodSAvPC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImMiPlZsYWRpc2xhdiBH
 YWJyaWVsLCBMYWRpc2xhdiBaYXBhZGxvPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAg
 PGRhdGFmaWVsZCB0YWc9IjI1MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBj
 b2RlPSJhIj4xLiB2eWQuPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVs
 ZCB0YWc9IjI2MCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5Q
 cmFoYSA6PC9zdWJmaWVsZD4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImIiPlNQTiw8L3N1YmZpZWxk
 PgogICAgICA8c3ViZmllbGQgY29kZT0iYyI+MTk4Mjwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVs
 ZCBjb2RlPSJlIj4oUMWZw61icmFtIDo8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0i
 ZiI+VFogNjYpPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0YWc9
 IjMwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj4xOTIgcy4g
 Ojwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJiIj5zY2jDqW1hdGEgOzwvc3ViZmll
 bGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJjIj4zMCBjbTwvc3ViZmllbGQ+CiAgICA8L2RhdGFm
 aWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSI1MDAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8
 c3ViZmllbGQgY29kZT0iYSI+Um96bW4uPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAg
 PGRhdGFmaWVsZCB0YWc9IjUwMCIgaW5kMT0iICIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBj
 b2RlPSJhIj4zMDAgdsO9dC48L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0YWZp
 ZWxkIHRhZz0iNTAwIiBpbmQxPSIgIiBpbmQyPSIgIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImEi
 PkthcC4gNC4gbmFwcy4gUsWvxb5lbmEgRHVkb3bDoSwga2FwLiA4LiBqZSBzZXN0LiB6IHDFmcOt
 c3DEm3Zrxa8gcsWvei4gYXV0b3LFrzwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxk
 YXRhZmllbGQgdGFnPSI1NTAiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29k
 ZT0iYSI+VnlkYXZhdGVsOiBWxaBFIHYgUHJhemU8L3N1YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+
 CiAgICA8ZGF0YWZpZWxkIHRhZz0iNjU1IiBpbmQxPSIgIiBpbmQyPSI3Ij4KICAgICAgPHN1YmZp
 ZWxkIGNvZGU9ImEiPnXEjWVibmljZSB2eXNva8O9Y2ggxaFrb2w8L3N1YmZpZWxkPgogICAgICA8
 c3ViZmllbGQgY29kZT0iNyI+ZmQxMzM3NzI8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29k
 ZT0iMiI+Y3plbmFzPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogICAgPGRhdGFmaWVsZCB0
 YWc9IjcwMCIgaW5kMT0iMSIgaW5kMj0iICI+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSJhIj5aYXBh
 ZGxvLCBMYWRpc2xhdjwvc3ViZmllbGQ+CiAgICAgIDxzdWJmaWVsZCBjb2RlPSI0Ij5hdXQ8L3N1
 YmZpZWxkPgogICAgPC9kYXRhZmllbGQ+CiAgICA8ZGF0YWZpZWxkIHRhZz0iNzEwIiBpbmQxPSIy
 IiBpbmQyPSIgIj4KICAgICAgPHN1YmZpZWxkIGNvZGU9ImEiPlZ5c29rw6EgxaFrb2xhIGVrb25v
 bWlja8OhIHYgUHJhemU8L3N1YmZpZWxkPgogICAgICA8c3ViZmllbGQgY29kZT0iNyI+a24yMDAx
 MDcwOTQwMzwvc3ViZmllbGQ+CiAgICA8L2RhdGFmaWVsZD4KICAgIDxkYXRhZmllbGQgdGFnPSI5
 OTgiIGluZDE9IiAiIGluZDI9IiAiPgogICAgICA8c3ViZmllbGQgY29kZT0iYSI+aHR0cDovL2Fs
 ZXBoLm5rcC5jei9GLz9mdW5jPWRpcmVjdCZhbXA7ZG9jX251bWJlcj0wMDAwMDAwOTYmYW1wO2xv
 Y2FsX2Jhc2U9Q05CPC9zdWJmaWVsZD4KICAgIDwvZGF0YWZpZWxkPgogIDwvcmVjb3JkPgo8L2Nv
 bGxlY3Rpb24+Cg==
 END

 my (undef, $temp_file) = tempfile();

 barf($temp_file, decode_base64($marc_xml_example));

 # Arguments.
 @ARGV = (
         '-a',
         '-f',
         $temp_file,
 );

 # Run.
 exit App::MARC::Leader->new->run;

 # Output:
 # Record length: 0
 # Record status: New
 # Type of record: Language material
 # Bibliographic level: Monograph/Item
 # Type of control: No specified type
 # Character coding scheme: UCS/Unicode
 # Indicator count: Number of character positions used for indicators
 # Subfield code count: Number of character positions used for a subfield code (2)
 # Base address of data: 0
 # Encoding level: Full level
 # Descriptive cataloging form: Non-ISBD
 # Multipart resource record level: Not specified or not applicable
 # Length of the length-of-field portion: Number of characters in the length-of-field portion of a Directory entry (4)
 # Length of the starting-character-position portion: Number of characters in the starting-character-position portion of a Directory entry (5)
 # Length of the implementation-defined portion: Number of characters in the implementation-defined portion of a Directory entry (0)
 # Undefined: Undefined

=head1 DEPENDENCIES

L<Class::Utils>,
L<Getopt::Std>,
L<MARC::File::XML>,
L<MARC::Leader>,
L<MARC::Leader::Print>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-MARC-Leader>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
