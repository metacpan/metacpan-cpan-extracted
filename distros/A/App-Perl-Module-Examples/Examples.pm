package App::Perl::Module::Examples;

use strict;
use warnings;

use Class::Utils qw(set_params);
use File::Find::Rule;
use File::Spec::Functions qw(catfile);
use Getopt::Std;
use IO::Barf qw(barf);
use Pod::Example qw(get sections);

our $VERSION = 0.03;

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
		'd' => 0,
		'h' => 0,
	};
	if (! getopts('dh', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-d] [-h] [--version]\n";
		print STDERR "\t-d\t\tDebug mode.\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}

	# Find all perl module files in actual directory.
	my $rule = File::Find::Rule->new;
	my @pm = $rule->or(
		$rule->new->directory->name('t')->prune->discard,
		$rule->new->directory->name('inc')->prune->discard,
		$rule->new->directory->name('blib')->prune->discard,
		$rule->new,
	)->name('*.pm')->in('.');

	# Dump perl modules in debug mode.
	if ($self->{'_opts'}->{'d'}) {
		require Dumpvalue;
		my $dump = Dumpvalue->new;
		$dump->dumpValues(\@pm);
	}

	# For each example save example.
	my $num = 1;
	foreach my $perl_module_file (@pm) {

		# Get all example sections.
		my @examples = sections($perl_module_file);

		# For each section.
		foreach my $example_sec (@examples) {

			# Create example content.
			my ($example_data, $example_file) = get($perl_module_file, $example_sec);
			if (! defined $example_file) {
				$example_file = sprintf 'ex%d.pl', $num;
			}
			$example_data = "#!/usr/bin/env perl\n\n".
				$example_data;
			my $example_path = catfile('examples', $example_file);

			# Examples directory.
			if (! -r 'examples') {
				mkdir 'examples';
			}

			# Save example.
			barf($example_path, $example_data);
			chmod 0755, $example_path; 

			$num++;
		}
	}
	
	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Perl::Module::Examples - Base class for perl-module-examples script.

=head1 SYNOPSIS

 use App::Perl::Module::Examples;

 my $app = App::Perl::Module::Examples->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Perl::Module::Examples->new;

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

=head1 EXAMPLE

=for comment filename=print_help.pl

 use strict;
 use warnings;

 use App::Perl::Module::Examples;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Perl::Module::Examples->new->run;

 # Output like:
 # Usage: ./print_help.pl [-d] [-h] [--version]
 #         -d              Debug mode.
 #         -h              Print help.
 #         --version       Print version.

=head1 DEPENDENCIES

L<Class::Utils>,
L<File::Find::Rule>,
L<File::Spec::Functions>,
L<Getopt::Std>,
L<IO::Barf>,
L<Pod::Example>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Perl-Module-Examples>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2012-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
