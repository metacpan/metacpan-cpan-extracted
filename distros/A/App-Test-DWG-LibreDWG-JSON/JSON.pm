package App::Test::DWG::LibreDWG::JSON;

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use Capture::Tiny qw(capture);
use File::Copy;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Getopt::Std;
use IO::Barf qw(barf);
use Readonly;

Readonly::Hash our %REL => (
	'MC0.0' => 'r1.1',
	'AC1.2' => 'r1.2',
	'AC1.40' => 'r1.4',
	'AC1.50' => 'r2.0',
	'AC2.10' => 'r2.10',
	'AC1001' => 'r2.4',
	'AC1002' => 'r2.5',
	'AC1003' => 'r2.6',
	'AC1004' => 'r9',
	'AC1006' => 'r10',
	'AC1009' => 'r11',
	'AC1012' => 'r13',
	'AC1013' => 'r13c3',
	'AC1014' => 'r14',
	'AC1015' => 'r2000',
	'AC1018' => 'r2004',
	'AC1021' => 'r2007',
	'AC1024' => 'r2010',
	'AC1027' => 'r2013',
	'AC1032' => 'r2018',
);
Readonly::Scalar our $DR => 'dwgread';
Readonly::Scalar our $DW => 'dwgwrite';

our $VERSION = 0.05;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'd' => undef,
		'h' => 0,
		'i' => 0,
		'v' => 0,
	};
	if (! getopts('d:hiv:', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d test_dir] [-h] [-i] [-v level] [--version] dwg_file\n";
		print STDERR "\t-d test_dir\tTest directory (default is directory in system tmp).\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-i\t\tIgnore errors.\n";
		print STDERR "\t-v level\tVerbosity level (default 0, max 9).\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tdwg_file\tAutoCAD DWG file to test.\n";
		return 1;
	}
	$self->{'_dwg_file'} = shift @ARGV;

	my $tmp_dir = $self->{'_opts'}->{'d'};
	if (defined $tmp_dir && ! -d $tmp_dir) {
		mkpath($tmp_dir);
	}
	if (! defined $tmp_dir || ! -d $tmp_dir) {
		$tmp_dir = tempdir(CLEANUP => 1);
	}
	$self->{'_tmp_dir'} = $tmp_dir;

	# Copy original file to dir.
	my $dwg_file_first = catfile($tmp_dir, 'first.dwg');
	copy($self->{'_dwg_file'}, $dwg_file_first);

	# Get magic string.
	my $magic = detect_dwg_file($dwg_file_first);
	if (! exists $REL{$magic}) {
		print STDERR "dwgwrite for magic '$magic' doesn't supported.\n";
		return 1;
	}
	my $dwgwrite_version = $REL{$magic};

	# Verbose level.
	my $v = '-v'.$self->{'_opts'}->{'v'};

	my $dwgread = $ENV{'DWGREAD'} || $DR;
	my $dwgwrite = $ENV{'DWGWRITE'} || $DW;

	# Convert dwg file to JSON.
	my $json_file_first = catfile($tmp_dir, 'first.json');
	my $dwg_to_json_first = "$dwgread $v -o $json_file_first $dwg_file_first";
	if ($self->_exec($dwg_to_json_first, 'dwg_to_json')) {
		return 1;
	}

	# Convert JSON to dwg file.
	my $dwg_file_second = catfile($tmp_dir, 'second.dwg');
	my $json_to_dwg_first = "$dwgwrite --as $dwgwrite_version $v -o $dwg_file_second $json_file_first";
	if ($self->_exec($json_to_dwg_first, 'json_to_dwg')) {
		return 1;
	}

	# Convert new dwg file to JSON.
	my $json_file_second = catfile($tmp_dir, 'second.json');
	my $dwg_to_json_second = "$dwgread $v -o $json_file_second $dwg_file_second";
	if ($self->_exec($dwg_to_json_second, 'dwg_to_json_second')) {
		return 1;
	}

	# Compare JSON files.
	my $diff = "diff $json_file_first $json_file_second";
	system($diff);

	return 0;
}

sub _exec {
	my ($self, $command, $log_prefix) = @_;

	my ($stdout, $stderr, $exit_code) = capture {
		system($command);
	};

	if (defined $log_prefix) {
		if ($stdout) {
			my $stdout_file = catfile($self->{'_tmp_dir'},
				$log_prefix.'-stdout.log');
			barf($stdout_file, $stdout);
		}
		if ($stderr) {
			my $stderr_file = catfile($self->{'_tmp_dir'},
				$log_prefix.'-stderr.log');
			barf($stderr_file, $stderr);

			# Report errors.
			if (! $self->{'_opts'}->{'i'}) {
				if (my @num = ($stderr =~ m/ERROR/gms)) {
					print STDERR "Command '$command' has ".scalar @num." ERRORs\n";
				}
			}
		}
	}

	if ($exit_code) {
		print STDERR "Command '$command' exit with $exit_code.\n";
		return 1;
	}

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Test::DWG::LibreDWG::JSON - Base class for test-dwg-libredwg-json script.

=head1 SYNOPSIS

 use App::Test::DWG::LibreDWG::JSON;

 my $app = App::Test::DWG::LibreDWG::JSON->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Test::DWG::LibreDWG::JSON->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

=for comment filename=test_dwg_file_without_issue.pl

 use strict;
 use warnings;

 use App::Test::DWG::LibreDWG::JSON;
 use File::Temp qw(tempfile);
 use IO::Barf qw(barf);
 use MIME::Base64;

 my $dwg_in_base64 = <<'END';
 QUMxLjQwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIAAAAAAAAAAAAAAAAAAAAAAAAA
 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAChA
 AAAAAAAAIkAAAAAAAAAYQKEoVK4NihJAAAAAAAAAAAChKFSuDYoiQAAAAAAAAAAA8D8AAAAAAAAA
 AAAAAAABAAEAmJmZmZmZyT+YmZmZmZmpPwEADwAAAA8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A
 /wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/
 AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A
 /wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/
 AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A/wD/AP8A
 AAAAAAAAAAAffplKebb0PwIABAABAAEAAAAAAAAAAAAAAAAAAAAAANA/mJmZmZmZuT8AAAAAAAAA
 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 AAAAAAAAAAAAAAAAAA==
 END

 my (undef, $tmp_file) = tempfile();
 barf($tmp_file, decode_base64($dwg_in_base64));

 # Arguments.
 @ARGV = (
         '-v9',
         $tmp_file,
 );

 # Run.
 my $exit_code = App::Test::DWG::LibreDWG::JSON->new->run;

 # Print out.
 print "Exit code: $exit_code\n";

 # Output like:
 # Exit code: 0

=head1 DEPENDENCIES

L<Capture::Tiny>,
L<File::Copy>,
L<File::Path>,
L<File::Spec::Functions>,
L<File::Temp>,
L<Getopt::Std>,
L<IO::Barf>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Test-DWG-LibreDWG-JSON>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.05

=cut
