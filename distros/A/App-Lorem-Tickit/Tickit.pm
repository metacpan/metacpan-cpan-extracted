package App::Lorem::Tickit;

use strict;
use warnings;

use App::Lorem::Tickit::Widget;
use Getopt::Std;
use Tickit;

our $VERSION = 0.01;

sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Object.
	return $self;
}

sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [--version]\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}

	my $widget = App::Lorem::Tickit::Widget->new(
		'version' => $VERSION,
	);

	Tickit->new('root' => $widget)->run;

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Lorem::Tickit - Base class for lorem-tickit script.

=head1 SYNOPSIS

 use App::Lorem::Tickit;

 my $app = App::Lorem::Tickit->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Lorem::Tickit->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run Tickit lorem generator.

=head1 DEPENDENCIES

L<App::Lorem::Tickit::Widget>,
L<Getopt::Std>,
L<Tickit>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Lorem-Tickit>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
