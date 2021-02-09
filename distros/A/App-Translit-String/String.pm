package App::Translit::String;

use strict;
use warnings;

use English;
use Error::Pure qw(err);
use Getopt::Std;
use Lingua::Translit;

our $VERSION = 0.08;

# Constructor.
sub new {
	my $class = shift;

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
		'r' => 0,
		't' => 'ISO 9',
	};
	if (! getopts('hrt:', $self->{'_opts'}) || @ARGV < 1
		|| $self->{'_opts'}->{'h'}) {

		print STDERR "Usage: $0 [-h] [-r] [-t table] [--version]\n\t".
			"string\n\n";
		print STDERR "\t-h\t\tPrint help.\n";
		print STDERR "\t-r\t\tReverse transliteration.\n";
		print STDERR "\t-t table\tTransliteration table (default ".
			"value is 'ISO 9').\n";
		print STDERR "\t--version\tPrint version.\n";
		return 1;
	}
	$self->{'_string'} = $ARGV[0];

	# Run.
	my $ret;
	eval {
		my $tr = Lingua::Translit->new($self->{'_opts'}->{'t'});
		if ($self->{'_opts'}->{'r'}) {
			if ($tr->can_reverse) {
				$ret = $tr->translit_reverse(
					$self->{'_string'});
			} else {
				err 'No reverse transliteration.';
			}
		} else {
			$ret = $tr->translit($self->{'_string'});
		}
	};
	if ($EVAL_ERROR) {
		err 'Cannot transliterate string.',
			'Error', $EVAL_ERROR;
	}
	print "$ret\n";

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Translit::String - Perl class for translit-string application.

=head1 SYNOPSIS

 use App::Translit::String;

 my $obj = App::Translit::String->new;
 my $exit_code = $obj->run;

=head1 METHODS

=head2 C<new>

 my $obj = App::Translit::String->new;

Constructor.

=head2 C<run>

 my $exit_code = $obj->run;

Run.

Returns 1 for error, 0 for success.

=head1 ERRORS

 run():
         Cannot transliterate string.
                 Error: %s
         No reverse transliteration.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use App::Translit::String;

 # Run.
 exit App::Translit::String->new->run;

 # Print version.
 sub VERSION_MESSAGE {
        print "9.99\n";
        exit 0;
 }

 # Output:
 # Usage: /tmp/vm3pgIQWej [-h] [-r] [-t table] [--version]
 #         string
 # 
 #         -h              Print help.
 #         -r              Reverse transliteration.
 #         -t table        Transliteration table (default value is 'ISO 9').
 #         --version       Print version.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use App::Translit::String;

 # Run.
 @ARGV = ('Российская Федерация');
 exit App::Translit::String->new->run;

 # Output:
 # Rossijskaâ Federaciâ

=head1 EXAMPLE3

 use strict;
 use warnings;

 use App::Translit::String;

 # Run.
 @ARGV = ('-r', 'Rossijskaâ Federaciâ');
 exit App::Translit::String->new->run;

 # Output:
 # Российская Федерация

=head1 DEPENDENCIES

L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<Lingua::Translit>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Translit-String>.

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2015-2021 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.08

=cut
