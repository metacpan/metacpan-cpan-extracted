package App::NKC2ISBD;

use strict;
use warnings;

use Encode qw(encode_utf8);
use English;
use Error::Pure qw(err);
use File::Temp qw(tempfile);
use Getopt::Std;
use IO::Barf qw(barf);
use MARC;
use MARC::Record;
use ZOOM;

our $VERSION = 0.01;

$| = 1;

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
		'h' => 0,
	};
	if (! getopts('h', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		print STDERR "Usage: $0 [-h] [--version] id_of_book ..\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tid_of_book ..\t\tIdentifier of book e.g. Czech ".
			"national bibliography id or ISBN\n";
		return 1;
	}
	my @book_ids = @ARGV;

	# Configuration of National library of the Czech Republic service.
	my $c = {
		host => 'aleph.nkp.cz',
		port => '9991',
		database => 'NKC01',
		record => 'usmarc'
	};

	# ZOOM object.
	my $conn = eval {
		ZOOM::Connection->new(
			$c->{'host'}, $c->{'port'},
			'databaseName' => $c->{'database'},
		);
	};
	if ($EVAL_ERROR) {
		err "Cannot connect to '".$c->{'host'}."'.",
			'Code', $EVAL_ERROR->code,
			'Message', $EVAL_ERROR->message,
		;
	}
	$conn->option(preferredRecordSyntax => $c->{'record'});

	foreach my $book_id (@book_ids) {
		# Get MARC record from library.
		my ($rs, $ccnb);
		## CCNB
		if ($book_id =~ m/^cnb\d+$/ms) {
			$rs = $conn->search_pqf('@attr 1=48 '.$book_id);
			if (! defined $rs || ! $rs->size) {
				print STDERR encode_utf8("Edition with ČČNB '$book_id' doesn't exist.\n");
				return 1;
			}
			$ccnb = $book_id;
		## ISBN
		} else {
			$rs = $conn->search_pqf('@attr 1=7 '.$book_id);
			if (! defined $rs || ! $rs->size) {
				print STDERR "Edition with ISBN '$book_id' doesn't exist.\n";
				return 1;
			}
		}
		my $raw_record = $rs->record(0)->raw;

		if (! defined $ccnb) {
			my $usmarc = MARC::Record->new_from_usmarc($raw_record);
			$ccnb = $self->_subfield($usmarc, '015', 'a');
		}
		my $output_file = $ccnb.'.txt';

		my (undef, $tempfile) = tempfile();
		barf($tempfile, $raw_record);
		my $marc = MARC->new($tempfile);
		my $isbd = $marc->output({'format' => 'isbd'});
		barf($output_file, $isbd);
		unlink $tempfile;

		print "Record for '".$book_id."' was saved to '$output_file'.\n";
	}

	return 0;
}

sub _subfield {
	my ($self, $obj, $field, $subfield) = @_;

	my $field_value = $obj->field($field);
	if (! defined $field_value) {
		return;
	}

	return $field_value->subfield($subfield);
}

1;


__END__

=pod

=encoding utf8

=head1 NAME

App::NKC2ISBD - Base class for nkc-to-marc script.

=head1 SYNOPSIS

 use App::NKC2ISBD;

 my $app = App::NKC2ISBD->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::NKC2ISBD->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

=for comment filename=fetch_marc_record_via_isbn.pl

 use strict;
 use warnings;

 use App::NKC2ISBD;

 # Arguments.
 @ARGV = (
         '978-80-7370-353-0',
 );

 # Run.
 exit App::NKC2ISBD->new->run;

 # Output:
 # Record for '978-80-7370-353-0' was saved to 'cnb002751696.txt'.

 # `cat cnb002751696.txt`
 # Vědomá prostitutka : tipy a triky profesionálky / Veronica Monet ; z anglického originálu Sex secrets of escort přeložila Hana Vysloužilová  -- Vydání první  -- 256 stran ; 21 cm

=head1 DEPENDENCIES

L<Encode>,
L<English>,
L<Error::Pure>,
L<File::Temp>,
L<Getopt::Std>,
L<IO::Barf>,
L<MARC>,
L<MARC::Record>,
L<ZOOM>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-NKC2ISBD>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2026 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
