package App::Images::To::DjVu;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use File::Basename;
use Getopt::Std;
use Perl6::Slurp qw(slurp);

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
		'e' => 'c44',
		'h' => 0,
		'o' => 'output.djvu',
		'q' => 0,
	};
	if (! getopts('e:ho:q', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-e encoder] [-h] [-o out_file] [-q] ".
			"[--version] images_list_file\n";
		print STDERR "\t-e encoder\t\tEncoder (default value is 'c44').\n";
		print STDERR "\t-h\t\t\tHelp.\n";
		print STDERR "\t-o out_file\t\tOutput file (default value is ".
			"'output.djvu').\n";
		print STDERR "\t-q\t\t\tQuiet mode.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\timages_list_file\tText file with images list.\n";
		return 1;
	}
	my $images_list_file = $ARGV[0];

	# Get images.
	my @images = slurp($images_list_file, { 'chomp' => 1 });

	# Create djvu file for each file.
	my @djvu;
	foreach my $image (@images) {
		my ($image_base, undef, $suffix) = fileparse($image, qr{\.[^.]+$});
		$suffix =~ s/^\.//ms;
		my $djvu = $image_base.'.djvu';
		push @djvu, $djvu;
		if ($image ne $djvu && ! -r $djvu) {
			if ($self->{'_opts'}->{'e'} eq 'c44') {
				if ($suffix eq 'png') {
					system "convert $image $image_base.jpg";
					$image = "$image_base.jpg";
				}
				system "c44 $image $djvu";
				if (! $self->{'_opts'}->{'q'}) {
					print "$djvu\n";
				}
			} else {
				err "Unsupported encoder '$self->{'_opts'}->{'e'}'.";
			}
		}
	}

	# Create djvu file.
	if (! -r $self->{'_opts'}->{'o'}) {
		system "djvm -c $self->{'_opts'}->{'o'} ".(join ' ', @djvu);
		if (! $self->{'_opts'}->{'q'}) {
			print "$self->{'_opts'}->{'o'}\n";
		}
	}

	return 0;
}

1;

=pod

=encoding utf8

=head1 NAME

App::Images::To::DjVu - Base class for images2djvu script.

=head1 SYNOPSIS

 use App::Images::To::DjVu;

 my $app = App::Images::To::DjVu->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Images::To::DjVu->new;

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

 run():
         Unsupported encoder '%s'.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::Images::To::DjVu;

 # Arguments.
 @ARGV = (
         '-h',
 );

 # Run.
 exit App::Images::To::DjVu->new->run;

 # Output like:
 # Usage: ./ex1.pl [-e encoder] [-h] [-o out_file] [-q] [--version] images_list_file
 #         -e encoder              Encoder (default value is 'c44').
 #         -h                      Help.
 #         -o out_file             Output file (default value is 'output.djvu').
 #         -q                      Quiet mode.
 #         --version               Print version.
 #         images_list_file        Text file with images list.

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<File::Basename>,
L<Getopt::Std>,
L<Perl6::Slurp>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Images-To-DjVu>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
