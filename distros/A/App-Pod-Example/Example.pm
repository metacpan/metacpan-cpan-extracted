package App::Pod::Example;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English qw(-no_match_vars);
use Error::Pure qw(err);
use File::Temp qw(tempfile);
use Getopt::Std;
use IO::Barf qw(barf);
use Pod::Example qw(get);
use Readonly;

# Constants.
Readonly::Scalar my $DASH => q{-};
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $HASH => q{#};
Readonly::Scalar my $SPACE => q{ };

our $VERSION = 0.17;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process params.
	set_params($self, @params);

	# Process arguments.
	$self->{'_opts'} = {
		'd' => 0,
		'h' => 0,
		'e' => 0,
		'n' => undef,
		'p' => 0,
		'r' => 0,
		's' => 'EXAMPLE',
	};
	if (! getopts('d:ehn:prs:', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d flag] [-e] [-h] [-n number] ".
			"[-p] [-r]\n\t[-s section] [--version] ".
			"pod_file_or_module [argument ..]\n\n";
		print STDERR "\t-d flag\t\tTurn debug (0/1) (default is 1).\n";
		print STDERR "\t-e\t\tEnumerate lines. Only for print mode.\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t-n number\tNumber of example (default is ".
			"nothing).\n";
		print STDERR "\t-p\t\tPrint example.\n";
		print STDERR "\t-r\t\tRun example.\n";
		print STDERR "\t-s section\tUse section (default EXAMPLE).\n";
		print STDERR "\t--version\tPrint version.\n";
		exit 1;
	}
	$self->{'_pod_file'} = shift @ARGV;
	$self->{'_args'} = \@ARGV;
	$self->{'_debug'} = $self->{'_opts'}->{'d'};
	$self->{'_enumerate'} = $self->{'_opts'}->{'e'};
	$self->{'_number'} = $self->{'_opts'}->{'n'};
	$self->{'_print'} = $self->{'_opts'}->{'p'};
	$self->{'_run'} = $self->{'_opts'}->{'r'};
	$self->{'_section'} = $self->{'_opts'}->{'s'};

	# No action.
	if (! $self->{'_print'} && ! $self->{'_run'}) {
		err 'Cannot process any action (-p or -r options).';
	}

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Get example code.
	my $code = get($self->{'_pod_file'}, $self->{'_section'}, $self->{'_number'});

	# No code.
	if (! defined $code) {
		print "No code.\n";
		return;
	}

	# Print.
	if ($self->{'_print'}) {
		if ($self->{'_debug'}) {
			_debug('Example source');
		}
		if ($self->{'_enumerate'}) {
			my @lines = split "\n", $code;
			my $count = 1;
			foreach my $line (@lines) {
				print $count.': '.$line."\n";
				$count++;
			}
		} else {
			print $code."\n";
		}
	}

	# Run.
	if ($self->{'_run'}) {
		if ($self->{'_debug'}) {
			_debug('Example output');
		}
		my (undef, $tempfile) = tempfile();
		barf($tempfile, $code);
		my $args = $EMPTY_STR;
		if (@{$self->{'_args'}}) {
			$args = '"'.(join '" "', @{$self->{'_args'}}).'"';
		}
		system "$EXECUTABLE_NAME $tempfile $args";
		unlink $tempfile;
	}

	return;
}

sub _debug {
	my $text = shift;
	print $HASH, $DASH x 79, "\n";
	print $HASH, $SPACE, $text."\n";
	print $HASH, $DASH x 79, "\n";
	return;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Pod::Example - Base class for pod-example script.

=head1 SYNOPSIS

 use App::Pod::Example;

 my $app = App::Pod::Example->new;
 $app->run;

=head1 METHODS

=over 8

=item C<new()>

 Constructor.

=item C<run()>

 Run method.
 Returns undef.

=back

=head1 ERRORS

 new():
         Cannot process any action.
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Pod::Example;

 # Arguments.
 @ARGV = (
         '-e',
         '-p',
         'App::Pod::Example',
 );

 # Run.
 App::Pod::Example->new->run;

 # Output:
 # -- this code with enumerated lines --

=head1 CAVEATS

Examples with die() cannot process, because returns bad results.

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Error::Pure>,
L<File::Temp>,
L<Getopt::Std>,
L<IO::Barf>,
L<Pod::Example>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Pod-Example>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2011-2020 Michal Josef Špaček
 BSD 2-Clause License

=head1 VERSION

0.17

=cut
