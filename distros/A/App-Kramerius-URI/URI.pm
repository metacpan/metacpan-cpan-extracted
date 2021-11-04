package App::Kramerius::URI;

use strict;
use warnings;

use Data::Kramerius;
use Getopt::Std;

our $VERSION = 0.03;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Load data.
	$self->{'kramerius'} = Data::Kramerius->new;

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

		print STDERR "Usage: $0 [-h] [--version] kramerius_id\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tkramerius_id\tKramerius system id. e.g. ".
			"mzk\n";
		return 1;
	}
	my $kramerius_id = shift @ARGV;

	my $kramerius_obj = $self->{'kramerius'}->get($kramerius_id);

	# Print URL.
	if (defined $kramerius_obj) {
		print $kramerius_obj->url.' '.$kramerius_obj->version."\n";
	}

	return 0;
}

1;

=pod

=encoding utf8

=head1 NAME

App::Kramerius::URI - Base class for kramerius-uri script.

=head1 SYNOPSIS

 use App::Kramerius::URI;

 my $app = App::Kramerius::URI->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Kramerius::URI->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Kramerius::URI;

 # Arguments.
 @ARGV = (
         'mzk',
 );

 # Run.
 exit App::Kramerius::URI->new->run;

 # Output like:
 # http://kramerius.mzk.cz/ 4

=head1 DEPENDENCIES

L<Data::Kramerius>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Kramerius-URI>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.03

=cut
