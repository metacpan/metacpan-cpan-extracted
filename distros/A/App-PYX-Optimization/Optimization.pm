package App::PYX::Optimization;

use strict;
use warnings;

use Getopt::Std;
use PYX::Optimization

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

# Run script.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'}) || $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		print STDERR "Usage: $0 [-h] [--version] [filename] [-]\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tfilename\tProcess on filename\n";
		print STDERR "\t-\t\tProcess on stdin\n";
		return 1;
	}
	$self->{'_filename_or_stdin'} = $ARGV[0];

	# PYX::Optimization object.
	my $optimizer = PYX::Optimization->new;

	# Parse from stdin.
	if ($self->{'_filename_or_stdin'} eq '-') {
		$optimizer->parse_handler(\*STDIN);

	# Parse file.
	} else {
		$optimizer->parse_file($self->{'_filename_or_stdin'});
	}

	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::PYX::Optimization - Perl class for pyx-optimization application.

=head1 SYNOPSIS

 use App::PYX::Optimization;

 my $obj = App::PYX::Optimization->new;
 $obj->run;

=head1 METHODS

=head2 C<new>

Constructor.

=head2 C<run>

Run.

=head1 ERRORS

 new():
         From Class::Utils:
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::PYX::Optimization;

 # Run.
 exit App::PYX::Optimization->new->run;

 # Output:
 # Usage: __SCRIPT_NAME__ [-h] [--version] [filename] [-]
 #         -h              Print help.
 #         --version       Print version.
 #         [filename]      Process on filename
 #         -               Process on stdin

=head1 DEPENDENCIES

L<Getopt::Std>,
L<PYX::Optimization>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-PYX-Optimization>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2020 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
