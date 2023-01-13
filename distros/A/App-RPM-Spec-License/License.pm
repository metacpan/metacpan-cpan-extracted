package App::RPM::Spec::License;

use strict;
use warnings;

use English;
use Error::Pure qw(err);
use File::Find::Rule;
use Getopt::Std;
use List::Util qw(none);
use Parse::RPM::Spec;

our $VERSION = 0.02;

$| = 1;

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
		'f' => 0,
		'g' => '*',
		'h' => 0,
		's' => 0,
		'u' => 0,
	};
	if (! getopts('fg:hsu', $self->{'_opts'}) || $self->{'_opts'}->{'h'}) {
		print STDERR "Usage: $0 [-f] [-g file_glog] [-h] [-s] [-u] [--version] [file_or_dir]\n";
		print STDERR "\t-f\t\tPrint spec file name.\n";
		print STDERR "\t-g file_glob\tFile glob (default is * = *.spec).\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-s\t\tSkip errors.\n";
		print STDERR "\t-u\t\tPrint unique only.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tfile_or_dir\tFile or directory to check license in spec ".
			"files (default is actual directory)\n";
		return 1;
	}
	$self->{'_file_or_dir'} = shift @ARGV || '.';

	$self->{'_license_printed'} = [];

	if (-f $self->{'_file_or_dir'}) {
		$self->_process_spec_file($self->{'_file_or_dir'});
	} elsif (-d $self->{'_file_or_dir'}) {
		foreach my $spec_file (File::Find::Rule->file
			->name($self->{'_opts'}->{'g'}.'.spec')->in($self->{'_file_or_dir'})) {

			$self->_process_spec_file($spec_file);
		}
	} else {
		err 'Cannot process file or dir.',
			'Input', $self->{'_file_or_dir'},
		;
	}

	return 0;
}

sub _process_spec_file {
	my ($self, $spec_file) = @_;

	my $rpm_spec = eval {
		Parse::RPM::Spec->new({'file' => $spec_file});
	};
	if ($EVAL_ERROR) {
		if (! $self->{'_opts'}->{'s'}) {
			err "Failing of '$spec_file'.",
				'Error', $EVAL_ERROR,
			;
		} else {
			print STDERR "Skip spec file '$spec_file' (error).\n";
			return;
		}
	}
	if (defined $rpm_spec->license) {
		if (! $self->{'_opts'}->{'u'}
			|| ($self->{'_opts'}->{'u'}
			&& (none { $rpm_spec->license eq $_ } @{$self->{'_license_printed'}}))) {

			if ($self->{'_opts'}->{'f'}) {
				print $spec_file.': ';
			}
			print $rpm_spec->license."\n";
			if ($self->{'_opts'}->{'u'}) {
				push @{$self->{'_license_printed'}}, $rpm_spec->license;
			}
		}
	} else {
		print STDERR "Skip spec file '$spec_file' (no license).\n";
		return;
	}

	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::RPM::Spec::License - Base class for rpm-spec-license tool.

=head1 SYNOPSIS

 use App::RPM::Spec::License;

 my $app = App::RPM::Spec::License->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::RPM::Spec::License->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE1

=for comment filename=print_licenses.pl

 use strict;
 use warnings;

 use App::RPM::Spec::License;
 use File::Temp;
 use File::Spec::Functions qw(catfile);
 use IO::Barf qw(barf);

 # Temp dir.
 my $temp_dir = File::Temp->newdir;

 barf(catfile($temp_dir, 'ex1.spec'), <<'END');
 License: BSD
 END
 barf(catfile($temp_dir, 'ex2.spec'), <<'END');
 License: MIT
 END
 barf(catfile($temp_dir, 'ex3.spec'), <<'END');
 License: MIT
 END

 # Arguments.
 @ARGV = (
         $temp_dir,
 );

 # Run.
 exit App::RPM::Spec::License->new->run;

 # Output:
 # BSD
 # MIT
 # MIT

=head1 EXAMPLE2

=for comment filename=print_unique_licenses.pl

 use strict;
 use warnings;

 use App::RPM::Spec::License;
 use File::Temp;
 use File::Spec::Functions qw(catfile);
 use IO::Barf qw(barf);

 # Temp dir.
 my $temp_dir = File::Temp->newdir;

 barf(catfile($temp_dir, 'ex1.spec'), <<'END');
 License: BSD
 END
 barf(catfile($temp_dir, 'ex2.spec'), <<'END');
 License: MIT
 END
 barf(catfile($temp_dir, 'ex3.spec'), <<'END');
 License: MIT
 END

 # Arguments.
 @ARGV = (
         '-u',
         $temp_dir,
 );

 # Run.
 exit App::RPM::Spec::License->new->run;

 # Output:
 # BSD
 # MIT

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<File::Find::Rule>,
L<Getopt::Std>.
L<List::Util>,
L<Parse::RPM::Spec>,

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-RPM-Spec-License>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
