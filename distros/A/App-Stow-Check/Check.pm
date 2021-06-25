package App::Stow::Check;

use strict;
use warnings;

use Cwd qw(realpath);
use File::Spec::Functions qw(abs2rel splitdir);
use File::Which qw(which);
use Getopt::Std;
use Readonly;

Readonly::Scalar our $DEFAULT_STOW_DIR => '/usr/local/stow';

our $VERSION = 0.02;

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
		'd' => $DEFAULT_STOW_DIR,
		'h' => 0,
	};
	if (! getopts('d:h', $self->{'_opts'}) || $self->{'_opts'}->{'h'} || @ARGV < 1) {
		print STDERR "Usage: $0 [-d stow_dir] [-h] [--version] command\n";
		print STDERR "\t-d stow_dir\tStow directory (default value is '$DEFAULT_STOW_DIR').\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tcommand\t\tCommand for which is stow dist looking.\n";
		return 1;
	}
	$self->{'_command'} = $ARGV[0];

	my ($exit_code, $message) = $self->_check;
	if ($exit_code == 0) {
		print $message."\n";
	} else {
		print STDERR $message."\n";
	}

	return $exit_code;
}

sub _check {
	my $self = shift;

	my $command = $self->{'_command'};

	my $command_path = which($command);
	if (! defined $command_path) {
		return (1, "Command '$command' not found.");
	}

	my $stow_dir = $self->{'_opts'}->{'d'};
	if (! -d $stow_dir) {
		return (1, "Stow directory '$stow_dir' doesn't exist.");
	}
	my $rel_path = abs2rel(realpath($command_path), $stow_dir);
	my @rel_path = splitdir($rel_path);
	if ($rel_path[0] eq '..') {
		return (1, "Command '$command' doesn't use stow.");
	}
	if ($rel_path[1] ne 'bin' && $rel_path[1] ne 'sbin') {
		return (1, "Command '$command' don't use 'bin/sbin' path.");
	}

	return (0, $rel_path[0]);
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Stow::Check - Base class for stow-check script.

=head1 SYNOPSIS

 use App::Stow::Check;

 my $app = App::Stow::Check->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Stow::Check->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run method. Check if command is in stow directory and print error message
(STDERR, exit code 1) or dist name (STDOUT, exit code 0).

Returns exit code.

=head1 ERRORS

 run():
         Command '%s' doesn't use stow.
         Command '%s' don't use 'bin/sbin' path.
         Command '%s' not found.
         Stow directory '%s' doesn't exist.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Stow::Check;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Stow::Check->new->run;

 # Output:
 # Usage: ./ex1.pl [-d stow_dir] [-h] [--version] command
 #         -d stow_dir     Stow directory (default value is '/usr/local/stow').
 #         -h              Help.
 #         --version       Print version.
 #         command         Command for which is stow dist looking.

=head1 DEPENDENCIES

L<Cwd>,
L<File::Spec::Functions>,
L<File::Which>,
L<Getopt::Std>,
L<Readonly>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Stow-Check>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
