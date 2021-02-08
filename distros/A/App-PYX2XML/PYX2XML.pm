package App::PYX2XML;

use strict;
use warnings;

use Getopt::Std;
use PYX::SGML::Tags;
use Tags::Output::Indent;
use Tags::Output::Raw;

our $VERSION = 0.06;

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
		'e' => 'utf-8',
		'h' => 0,
		'i' => 0,
		's' => '',
	};
	if (! getopts('e:his:', $self->{'_opts'}) || $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		print STDERR "Usage: $0 [-e in_enc] [-h] [-i] [-s no_simple] [--version] ".
			"[filename] [-]\n";
		print STDERR "\t-e in_enc\tInput encoding (default value ".
			"is utf-8)\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-i\t\tIndent output.\n";
		print STDERR "\t-s no_simple\tList of element, which cannot be a simple".
			" like <element/>. Separator is comma.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\t[filename]\tProcess on filename\n";
		print STDERR "\t[-]\t\tProcess on stdin\n";
		return 1;
	}
	$self->{'_filename_or_stdin'} = $ARGV[0];

	# No simple elements.
	my @no_simple = split m/,/ms, $self->{'_opts'}->{'s'};

	# Tags object.
	my $tags;
	my %params = (
		'no_simple' => \@no_simple,
		'output_handler' => \*STDOUT,
		'xml' => 1,
	);
	if ($self->{'_opts'}->{'i'}) {
		$tags = Tags::Output::Indent->new(%params);
	} else {
		$tags = Tags::Output::Raw->new(%params);
	}

	# PYX::SGML::Tags object.
	my $writer = PYX::SGML::Tags->new(
		'input_encoding' => $self->{'_opts'}->{'e'},
		'tags' => $tags,
	);

	# Parse from stdin.
	if ($self->{'_filename_or_stdin'} eq '-') {
		$writer->parse_handler(\*STDIN);

	# Parse file.
	} else {
		$writer->parse_file($self->{'_filename_or_stdin'});
	}
	print "\n";

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::PYX2XML - Perl class for pyx2xml application.

=head1 SYNOPSIS

 use App::PYX2XML;

 my $obj = App::PYX2XML->new;
 $obj->run;

=head1 METHODS

=head2 C<new>

 my $obj = App::PYX2XML->new;

Constructor.

Returns instance of object.

=head2 C<run>

 $obj->run;

Run.

Returns undef.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::PYX2XML;

 # Run.
 exit App::PYX2XML->new->run;

 # Output:
 # Usage: ./examples/ex1.pl [-e in_enc] [-h] [-i] [-s no_simple] [--version] [filename] [-]
 #         -e in_enc       Input encoding (default value is utf-8).
 #         -h              Print help.
 #         -i              Indent output.
 #         -s no_simple    List of element, which cannot be a simple like <element/>. Separator is comma.
 #         --version       Print version.
 #         [filename]      Process on filename
 #         [-]             Process on stdin

=head1 DEPENDENCIES

L<Getopt::Std>,
L<PYX::SGML::Tags>,
L<Tags::Output::Indent>,
L<Tags::Output::Raw>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-PYX2XML>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.06

=cut
