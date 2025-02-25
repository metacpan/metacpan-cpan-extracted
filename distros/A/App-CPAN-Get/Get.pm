package App::CPAN::Get;

use strict;
use warnings;

use App::CPAN::Get::MetaCPAN;
use App::CPAN::Get::Utils qw(process_module_name_and_version);
use Class::Utils qw(set_params);
use English;
use Error::Pure qw(err);
use File::Spec::Functions qw(catfile);
use Getopt::Std;
use LWP::UserAgent;
use Scalar::Util qw(blessed);

our $VERSION = 0.14;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# LWP::User agent object.
	$self->{'lwp_user_agent'} = undef;

	# Process parameters.
	set_params($self, @params);

	if (defined $self->{'lwp_user_agent'}) {
		if (! blessed($self->{'lwp_user_agent'})
			|| ! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {

			err "Parameter 'lwp_user_agent' must be a ".
				'LWP::UserAgent instance.';
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent(__PACKAGE__.'/'.$VERSION);
	}

	$self->{'_cpan'} = App::CPAN::Get::MetaCPAN->new(
		'lwp_user_agent' => $self->{'lwp_user_agent'},
	);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'f' => 0,
		'h' => 0,
		'o' => undef,
	};
	if (! getopts('fho:', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		print STDERR "Usage: $0 [-f] [-h] [-o out_dir] [--version] module_name[module_version]\n";
		print STDERR "\t-f\t\tForce download and rewrite of existing file.\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-o out_dir\tOutput directory (default is actual).\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tmodule_name\tModule name. e.g. ".
			"App::Pod::Example\n";
		print STDERR "\tmodule_version\tModule version. e.g. \@1.23, ~1.23 etc.\n";
		return 1;
	}
	$self->{'_module_name_and_version'} = shift @ARGV;

	if (defined $self->{'_opts'}->{'o'}) {
		if (! -d $self->{'_opts'}->{'o'}) {
			print STDERR "Directory '$self->{'_opts'}->{'o'}' doesn't exist.\n";
			return 1;
		}
	}

	# Parse module name and version.
	($self->{'_module_name'}, $self->{'_module_version_range'})
		= process_module_name_and_version($self->{'_module_name_and_version'});

	# Search.
	my $search_hr = $self->{'_cpan'}->search({
		'package' => $self->{'_module_name'},
		'version_range' => $self->{'_module_version_range'},
	});

	# Save.
	my $download_url = URI->new($search_hr->{'download_url'});
	my $file_to_save = ($download_url->path_segments)[-1];
	if ($self->{'_opts'}->{'o'}) {
		$file_to_save = catfile($self->{'_opts'}->{'o'}, $file_to_save);
	}
	eval {
		$self->{'_cpan'}->save($search_hr->{'download_url'}, $file_to_save, $self->{'_opts'});
	};
	if ($EVAL_ERROR) {
		print $EVAL_ERROR;
		return 1;
	}

	print "Package on '$search_hr->{'download_url'}' was downloaded.\n";
	
	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::CPAN::Get - Base class for cpan-get script.

=head1 SYNOPSIS

 use App::CPAN::Get;

 my $app = App::CPAN::Get->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::CPAN::Get->new;

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
         Parameter 'lwp_user_agent' must be a LWP::UserAgent instance.

 run():
         From App::CPAN::Get::MetaCPAN::search():
                Bad search options.
                Cannot connect to CPAN server.
                        HTTP code: %s
                        HTTP message: %s
                Module '%s' doesn't exist.
                Package doesn't present.

=head1 EXAMPLE

=for comment filename=download_app_pod_example.pl

 use strict;
 use warnings;

 use App::CPAN::Get;

 # Arguments.
 @ARGV = (
         'App::Pod::Example',
 );

 # Run.
 exit App::CPAN::Get->new->run;

 # Output like:
 # Package on 'http://cpan.metacpan.org/authors/id/S/SK/SKIM/App-Pod-Example-0.19.tar.gz' was downloaded.

=head1 DEPENDENCIES

L<App::CPAN::Get::MetaCPAN>,
L<App::CPAN::Get::Utils>,
L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<File::Spec::Functions>,
L<Getopt::Std>,
L<LWP::UserAgent>,
L<Scalar::Util>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-CPAN-Get>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2025 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.14

=cut
