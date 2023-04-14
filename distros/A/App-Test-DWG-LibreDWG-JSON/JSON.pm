package App::Test::DWG::LibreDWG::JSON;

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Copy;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Getopt::Std;
use IO::Barf qw(barf);
use Readonly;

Readonly::Scalar our $DR => 'dwgread';
Readonly::Scalar our $DW => 'dwgwrite';

our $VERSION = 0.01;

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
		'v' => 0,
	};
	if (! getopts('d:hv:', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d test_dir] [-h] [-v level] [--version] dwg_file\n";
		print STDERR "\t-d test_dir\tTest directory (default is directory in system tmp).\n";
		print STDERR "\t-h\t\tPrint help.\n";
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

	# Verbose level.
	my $v = '-v'.$self->{'_opts'}->{'v'};

	# Convert dwg file to JSON.
	my $json_file_first = catfile($tmp_dir, 'first.json');
	my $dwg_to_json_first = "$DR $v -o $json_file_first $dwg_file_first";
	if ($self->_exec($dwg_to_json_first, 'dwg_to_json')) {
		return 1;
	}

	# Convert JSON to dwg file.
	my $dwg_file_second = catfile($tmp_dir, 'second.dwg');
	my $json_to_dwg_first = "$DW $v -o $dwg_file_second $json_file_first";
	if ($self->_exec($json_to_dwg_first, 'json_to_dwg')) {
		return 1;
	}

	# Convert new dwg file to JSON.
	my $json_file_second = catfile($tmp_dir, 'second.json');
	my $dwg_to_json_second = "$DR $v -o $json_file_second $dwg_file_second";
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

App::Test::DWG::LibreDWG::JSON - Base class for cpan-search script.

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

=for comment filename=test_dwg_file.pl

 use strict;
 use warnings;

 use App::Test::DWG::LibreDWG::JSON;

 # Arguments.
 @ARGV = (
         '-v9',
         'TODO_DWG_FILE',
 );

 # Run.
 exit App::Test::DWG::LibreDWG::JSON->new->run;

 # Output like:
 # TODO

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

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
