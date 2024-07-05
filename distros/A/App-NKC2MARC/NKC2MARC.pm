package App::NKC2MARC;

use strict;
use warnings;

use Encode qw(encode_utf8);
use English;
use Error::Pure qw(err);
use Getopt::Std;
use IO::Barf qw(barf);
use List::Util 1.33 qw(none);
use MARC::File::XML;
use MARC::Record;
use Readonly;
use ZOOM;

Readonly::Array our @OUTPUT_FORMATS => qw(usmarc xml);

our $VERSION = 0.02;

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
		'o' => 'xml',
	};
	if (! getopts('ho:', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		print STDERR "Usage: $0 [-h] [-o output_format] [--version] id_of_book\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-o output_format\tOutput format (usmarc, xml - default).\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\tid_of_book\t\tIdentifier of book e.g. Czech ".
			"national bibliography id or ISBN\n";
		return 1;
	}
	$self->{'_id_of_book'} = shift @ARGV;

	if (none { $self->{'_opts'}->{'o'} eq $_ } @OUTPUT_FORMATS) {
		err 'Bad output format.',
			'Output format', $self->{'_opts'}->{'o'},
		;
	}

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

	# Get MARC record from library.
	my ($rs, $ccnb);
	## CCNB
	if ($self->{'_id_of_book'} =~ m/^cnb\d+$/ms) {
		$rs = $conn->search_pqf('@attr 1=48 '.$self->{'_id_of_book'});
		if (! defined $rs || ! $rs->size) {
			print STDERR encode_utf8("Edition with ČČNB '$self->{'_id_of_book'}' doesn't exist.\n");
			return 1;
		}
		$ccnb = $self->{'_id_of_book'};
	## ISBN
	} else {
		$rs = $conn->search_pqf('@attr 1=7 '.$self->{'_id_of_book'});
		if (! defined $rs || ! $rs->size) {
			print STDERR "Edition with ISBN '$self->{'_id_of_book'}' doesn't exist.\n";
			return 1;
		}
	}
	my $raw_record = $rs->record(0)->raw;
	my $usmarc = MARC::Record->new_from_usmarc($raw_record);
	if (! defined $ccnb) {
		$ccnb = $self->_subfield($usmarc, '015', 'a');
	}
	my $output_file;
	if ($self->{'_opts'}->{'o'} eq 'xml') {
		$output_file = $ccnb.'.xml';
		my $marc_xml = encode_utf8($usmarc->as_xml);
		barf($output_file, $marc_xml);
	} else {
		$output_file = $ccnb.'.mrc';
		barf($output_file, $raw_record);
	}

	print "MARC record for '".$self->{'_id_of_book'}."' was saved to '$output_file'.\n";

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

App::NKC2MARC - Base class for nkc-to-marc script.

=head1 SYNOPSIS

 use App::NKC2MARC;

 my $app = App::NKC2MARC->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::NKC2MARC->new;

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

 use App::NKC2MARC;

 # Arguments.
 @ARGV = (
         '978-80-7370-353-0',
 );

 # Run.
 exit App::NKC2MARC->new->run;

 # Output:
 # MARC record for '978-80-7370-353-0' was saved to 'cnb002751696.mrc'.

=head1 DEPENDENCIES

L<Encode>,
L<English>,
L<Error::Pure>,
L<Getopt::Std>,
L<IO::Barf>,
L<List::Util>,
L<MARC::File::XML>,
L<MARC::Record>,
L<Readonly>,
L<ZOOM>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-NKC2MARC>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
