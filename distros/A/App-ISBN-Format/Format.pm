package App::ISBN::Format;

use strict;
use warnings;

use Business::ISBN;
use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;

our $VERSION = 0.02;

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

		print STDERR "Usage: $0 [-h] [--version] isbn_string\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t--version\tPrint version.\n";
		print STDERR "\tisbn_string\tISBN string.\n";
		return 1;
	}
	$self->{'_isbn_string'} = shift @ARGV;

	my $isbn_obj = Business::ISBN->new($self->{'_isbn_string'});
	if (! $isbn_obj) {
		err "ISBN '$self->{'_isbn_string'}' is bad.";
		return 1;
	}

	# Validation.
	if (! $isbn_obj->is_valid) {
		$isbn_obj->fix_checksum;

		# Check again.
		if (! $isbn_obj->is_valid) {
			err "ISBN '$self->{'_isbn_string'}' is not valid.";
			return 1;
		}
	}

	# Construct output.
	my $isbn_concrete;
	my $isbn_without_dash = $self->{'_isbn_string'};
	$isbn_without_dash =~ s/-//msg;
	if (length $isbn_without_dash > 10) {
		$isbn_concrete = $isbn_obj->as_isbn13;
	} else {
		$isbn_concrete = $isbn_obj->as_isbn10;
	}

	print $self->{'_isbn_string'}.' -> '.$isbn_concrete->as_string, "\n";
	
	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::ISBN::Format - Base class for cpan-get script.

=head1 SYNOPSIS

 use App::ISBN::Format;

 my $app = App::ISBN::Format->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::ISBN::Format->new;

Constructor.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 new():
         From Class::Utils::set_params():
                 Unknown parameter '%s'.

 run():
         ISBN '%s' is bad.
         ISBN '%s' is not valid.

=head1 EXAMPLE

 use strict;
 use warnings;

 use App::ISBN::Format;

 # Arguments.
 @ARGV = (
         '9788025343364',
 );

 # Run.
 exit App::ISBN::Format->new->run;

 # Output:
 # 9788025343364 -> 978-80-253-4336-4

=head1 DEPENDENCIES

L<Business::ISBN>,
L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-ISBN-Format>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
