package App::Angle2Zodiac;

use strict;
use warnings;

use Getopt::Std;
use Unicode::UTF8 qw(encode_utf8);
use Zodiac::Angle;

our $VERSION = 0.01;

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
		'a' => 0,
		'h' => 0,
	};
	if (! getopts('ah', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-a] [-h] [--version] angle\n";
		print STDERR "\t-a\tOutput will be in ascii form ".
			"(e.g. 2 sc 31'28.9560'').\n";
		print STDERR "\t-h\t\tHelp.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tangle\tAngle in numeric (e.g. 212.5247100).\n";
		return 1;
	}
	$self->{'_angle'} = shift @ARGV;

	print encode_utf8(Zodiac::Angle->new->angle2zodiac($self->{'_angle'}, {
		'second' => 1,
		$self->{'_opts'}->{'a'} ? (
			'sign_type' => 'ascii',
		) : (),
	}))."\n";

	return 0;
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::Angle2Zodiac - Base class for angle2zodiac script.

=head1 SYNOPSIS

 use App::Angle2Zodiac;

 my $app = App::Angle2Zodiac->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Angle2Zodiac->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE1

=for comment filename=example_convert.pl

 use strict;
 use warnings;

 use App::Angle2Zodiac;

 # Arguments.
 @ARGV = (
         212.5247100,
 );

 # Run.
 exit App::Angle2Zodiac->new->run;

 # Output:
 # 2°♏31′28.9560′′

=head1 EXAMPLE2

=for comment filename=example_convert_ascii.pl

 use strict;
 use warnings;

 use App::Angle2Zodiac;

 # Arguments.
 @ARGV = (
         '-a',
         212.5247100,
 );

 # Run.
 exit App::Angle2Zodiac->new->run;

 # Output:
 # 2 sc 31′28.9560′′

=head1 DEPENDENCIES

L<Getopt::Std>,
L<Zodiac::Angle>,
L<Unicode::UTF8>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Angle2Zodiac>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2020-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
