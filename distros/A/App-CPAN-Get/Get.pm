package App::CPAN::Get;

use strict;
use warnings;

use App::CPAN::Get::Utils qw(process_module_name_and_version);
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;
use IO::Barf qw(barf);
use LWP::UserAgent;
use Menlo::Index::MetaCPAN;
use URI::cpan;

our $VERSION = 0.07;

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
		if (! $self->{'lwp_user_agent'}->isa('LWP::UserAgent')) {
			err "Parameter 'lwp_user_agent' must be a ".
				'LWP::UserAgent instance.';
		}
	} else {
		$self->{'lwp_user_agent'} = LWP::UserAgent->new;
		$self->{'lwp_user_agent'}->agent(__PACKAGE__.'/'.$VERSION);
	}

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] module_name[module_version]\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tmodule_name\tModule name. e.g. ".
			"App::Pod::Example\n";
		print STDERR "\tmodule_version\tModule version. e.g. \@1.23, ~1.23 etc.\n";
		return 1;
	}
	$self->{'_module_name_and_version'} = shift @ARGV;

	# Parse module name and version.
	($self->{'_module_name'}, $self->{'_module_version_range'})
		= process_module_name_and_version($self->{'_module_name_and_version'});

	# Get meta information for module name.
	# XXX Why not small dist?.
	my $res = Menlo::Index::MetaCPAN->new->search_packages({
		'package' => $self->{'_module_name'},
		exists $self->{'_module_version_range'}
			? ('version_range' => $self->{'_module_version_range'})
			: (),
	});
	if (! defined $res) {
		err "Module '".$self->{'_module_name'}."' doesn't exist.";
	}

	# Download dist.
	if (! $res->{'download_uri'}) {
		err "Value 'download_uri' doesn't exist.";
	}
	my $dist_res = $self->{'lwp_user_agent'}->get($res->{'download_uri'});
	if (! $dist_res->is_success) {
		err "Cannot download '$res->{'download_uri'}'.";
	}

	# Save to file.
	if (! $res->{'uri'}) {
		err "Value 'uri' doesn't exist.";
	}
	my $u = URI->new($res->{'uri'});
	my $dist_file = ($u->path_segments)[-1];
	barf($dist_file, $dist_res->decoded_content);

	print "Package on '$res->{'download_uri'}' was downloaded.\n";
	
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
         Cannot download '%s'.
         Module '%s' doesn't exist.
         Value 'download_uri' doesn't exist.
         Value 'uri' doesn't exist.

=head1 EXAMPLE

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

L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>,
L<IO::Barf>,
L<LWP::UserAgent>
L<Menlo::Index::MetaCPAN>
L<URI::cpan>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-CPAN-Get>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.07

=cut
