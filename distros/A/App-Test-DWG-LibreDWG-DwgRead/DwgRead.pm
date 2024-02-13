package App::Test::DWG::LibreDWG::DwgRead;

use strict;
use warnings;

use Capture::Tiny qw(capture);
use File::Copy;
use File::Find::Rule;
use File::Find::Rule::DWG;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Getopt::Std;
use IO::Barf qw(barf);
use Readonly;

Readonly::Scalar our $DR => 'dwgread';

our $VERSION = 0.04;

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
		'f' => 0,
		'h' => 0,
		'i' => 0,
		'm' => undef,
		'v' => 1,
	};
	if (! getopts('d:fhim:v:', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d test_dir] [-f] [-h] [-i] [-m match_string] [-v level] [--version] directory\n";
		print STDERR "\t-d test_dir\tTest directory (default is directory in system tmp).\n";
		print STDERR "\t-f\t\tPrint file.\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-i\t\tIgnore errors.\n";
		print STDERR "\t-m match_string\tMatch string (default is not defined).\n";
		print STDERR "\t-v level\tVerbosity level (default 1, min 0, max 9).\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tdirectory\tDirectory with DWG files to test.\n";
		return 1;
	}
	$self->{'_directory'} = shift @ARGV;

	if ($self->{'_opts'}->{'v'} == 0) {
		warn "Verbosity level 0 hasn't detection of ERRORs.\n";
	}

	my $tmp_dir = $self->{'_opts'}->{'d'};
	if (defined $tmp_dir && ! -d $tmp_dir) {
		mkpath($tmp_dir);
	}
	if (! defined $tmp_dir || ! -d $tmp_dir) {
		$tmp_dir = tempdir(CLEANUP => 1);
	}
	$self->{'_tmp_dir'} = $tmp_dir;

	# Verbose level.
	my $v = '-v'.$self->{'_opts'}->{'v'};

	my $file_num = 1;
	foreach my $dwg_file_in (File::Find::Rule->dwg->in($self->{'_directory'})) {

		# Copy DWG file to dir.
		my $dwg_file_out = catfile($tmp_dir, $file_num.'.dwg');
		copy($dwg_file_in, $dwg_file_out);

		# dwgread.
		my $dwgread = "$DR $v $dwg_file_out";
		$self->_exec($dwgread, $file_num.'-dwgread', $dwg_file_in);

		$file_num++;
	}

	return 0;
}

sub _exec {
	my ($self, $command, $log_prefix, $dwg_file) = @_;

	my ($stdout, $stderr, $exit_code) = capture {
		system($command);
	};

	if ($exit_code) {
		if (! $self->{'_opts'}->{'i'}) {
			print STDERR "Cannot dwgread '$dwg_file'.\n";
			print STDERR "\tCommand '$command' exit with $exit_code.\n";
		}
		return;
	}

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
				print STDERR "dwgread '$dwg_file' has ".scalar @num." ERRORs\n";
			}
		}

		if (defined $self->{'_opts'}->{'m'}) {
			foreach my $match_line ($self->_match_lines($stderr)) {
				if ($self->{'_opts'}->{'f'}) {
					print $dwg_file.': ';
				}
				print $match_line."\n";
			}
		}
	}

	return;
}

sub _match_lines {
	my ($self, $string) = @_;

	my @ret;
	foreach my $line (split m/\n/ms, $string) {
		if ($line =~ /$self->{'_opts'}->{'m'}/) {
			push @ret, $line;
		}
	}

	return @ret;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Test::DWG::LibreDWG::DwgRead - Base class for test-dwg-libredwg-dwgread script.

=head1 SYNOPSIS

 use App::Test::DWG::LibreDWG::DwgRead;

 my $app = App::Test::DWG::LibreDWG::DwgRead->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Test::DWG::LibreDWG::DwgRead->new;

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

 use App::Test::DWG::LibreDWG::DwgRead;
 use File::Temp qw(tempdir);
 use File::Spec::Functions qw(catfile);
 use IO::Barf qw(barf);
 use MIME::Base64;

 # Bad DWG data in base64.
 my $bad_dwg_data = <<'END';
 QUMxMDAyAAAAAAAAAAAAAAAK
 END

 # Prepare file in temp dir.
 my $temp_dir = tempdir(CLEANUP => 1);

 # Save data to file.
 my $temp_file = catfile($temp_dir, 'bad.dwg');
 barf($temp_file, decode_base64($bad_dwg_data));

 # Arguments.
 @ARGV = (
         $temp_dir,
 );

 # Run.
 exit App::Test::DWG::LibreDWG::DwgRead->new->run;

 # Output like:
 # Cannot dwgread '/tmp/__TMP_DIR__/bad.dwg'.
 #         Command 'dwgread -v1 /tmp/__TMP_DIR__/1.dwg' exit with 256.

=head1 DEPENDENCIES

L<Capture::Tiny>,
L<File::Copy>,
L<File::Find::Rule>,
L<File::Find::Rule::DWG>,
L<File::Path>,
L<File::Spec::Functions>,
L<File::Temp>,
L<Getopt::Std>,
L<IO::Barf>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Test-DWG-LibreDWG-DwgRead>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
