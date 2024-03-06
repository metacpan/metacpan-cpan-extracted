package App::DWG::Sort;

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Copy qw(move);
use File::Find::Rule;
use File::Find::Rule::DWG;
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile);
use Getopt::Std;

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
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version] directory\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tdirectory\tDirectory with DWG files.\n";
		return 1;
	}
	$self->{'_dir'} = shift @ARGV;

	foreach my $file (File::Find::Rule->dwg->in($self->{'_dir'})) {
		my $magic = detect_dwg_file($file);
		my $magic_dir = catfile($self->{'_dir'}, $magic);
		if (! -r $magic_dir) {
			make_path($magic_dir);
		}
		move($file, $magic_dir);
	}

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::DWG::Sort - Base class for dwg-sort script.

=head1 SYNOPSIS

 use App::DWG::Sort;

 my $app = App::DWG::Sort->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::DWG::Sort->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

=for comment filename=sort_help.pl

 use strict;
 use warnings;

 use App::DWG::Sort;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::DWG::Sort->new->run;

 # Output like:
 # Usage: ./sort_help.pl [-h] [--version] directory
 #         -h              Print help.
 #         --version       Print version.
 #         directory       Directory with DWG files.

=head1 DEPENDENCIES

L<CAD::AutoCAD::Detect>,
L<Class::Utils>,
L<Error::Pure>,
L<File::Copy>,
L<File::Find::Rule>,
L<File::Find::Rule::DWG>,
L<File::Path>,
L<File::Spec::Functions>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-DWG-Sort>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
