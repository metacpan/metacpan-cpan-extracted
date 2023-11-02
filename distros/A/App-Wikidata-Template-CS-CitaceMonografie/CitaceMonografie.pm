package App::Wikidata::Template::CS::CitaceMonografie;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Error::Pure qw(err);
use Getopt::Std;
use Readonly;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);
use Wikibase::API;
use Wikibase::Datatype::Query;

our $VERSION = 0.01;

Readonly::Scalar our $LANGUAGE => 'cs';

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	$self->{'_q'} = Wikibase::Datatype::Query->new;

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'l' => 'en',
		'm' => 'www.wikidata.org',
		'p' => 0,
	};
	if (! getopts('hl:m:p', $self->{'_opts'}) || $self->{'_opts'}->{'h'}) {
		print STDERR "Usage: $0 [-h] [-l lang] [-m mediawiki_site] [-p] [--version] wd_id\n";
		print STDERR "\t-h\t\t\tHelp.\n";
		print STDERR "\t-l lang\t\t\tLanguage used (default is English = en)\n";
		print STDERR "\t-m mediawiki_site\tMediaWiki site (default is www.wikidata.org).\n";
		print STDERR "\t-m\t\t\tPretty print.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\twd_id\t\t\tWikidata id (qid or pid or lid).\n";
		return 1;
	}
	my $wd_id = $ARGV[0];

	# API object.
	$self->{'_api'} = Wikibase::API->new(
		'mediawiki_site' => $self->{'_opts'}->{'m'},
	);

	# Get item.
	my $item = $self->{'_api'}->get_item($wd_id);

	# Check for edition.
	if ($self->{'_q'}->query($item, 'P31') ne 'Q3331189') {
		err "This item isn't book edition.";
	}

	# Citation parameters.
	# XXX Rewrite to data object.
	my $citace_params_hr = $self->_get_citace_params($item);

	# Print to putput.
	print encode_utf8($self->_citace_monografie($citace_params_hr,
		$self->{'_opts'}->{'p'})), "\n";

	return 0;
}

sub _citace_monografie {
	my ($self, $params_hr, $pretty_print) = @_;

	$pretty_print //= 0;
	my $ret = '{{citace monografie';
	foreach my $param (sort keys %{$params_hr}) {
		if ($pretty_print) {
			$ret .= "\n";
		}
		$ret .= ' | '.$param.' = '.$params_hr->{$param};
	}
	if ($pretty_print) {
		$ret .= "\n}}";
	} else {
		$ret .= ' }}';
	}

	return $ret;
}

sub _get_citace_params {
	my ($self, $item) = @_;

	my $ret_hr = {};

	# Title.
	$ret_hr->{'titul'} = $self->{'_q'}->query($item, 'P1476');

	# Subtitle.
	my $subtitle = $self->{'_q'}->query($item, 'P1680');
	if ($subtitle) {
		$ret_hr->{'titul'} .= ': '.$subtitle;
	}

	# Authors.
	my $author_count = 1;
	# TODO Not deprecated family name (Q11870379).
	foreach my $author_page_id ($self->{'_q'}->query($item, 'P50')) {
		my $given_name = decode_utf8('jméno');
		my $family_name = decode_utf8('příjmení');
		my $author = 'autor';
		if ($author_count > 1) {
			$given_name .= $author_count;
			$family_name .= $author_count;
			$author .= $author_count;
		}
		my $author_item = $self->{'_api'}->get_item($author_page_id);
		my $family_name_id = $self->{'_q'}->query($author_item, 'P734');
		my @given_name_ids = $self->{'_q'}->query($author_item, 'P735');
		if (@given_name_ids && $family_name_id) {
			$ret_hr->{$given_name} = join ' ', map { $self->_get_page_label($_) }
				@given_name_ids;
			$ret_hr->{$family_name} = $self->_get_page_label($family_name_id);
		} else {
			$ret_hr->{$author} = $self->_get_page_label($author_page_id);
		}

		# Link to author.
		# TODO

		$author_count++;
	}
	foreach my $author_string ($self->{'_q'}->query($item, 'P2093')) {
		my $given_name = decode_utf8('jméno');
		my $family_name = decode_utf8('příjmení');
		my $author = 'autor';
		if ($author_count > 1) {
			$given_name .= $author_count;
			$family_name .= $author_count;
			$author .= $author_count;
		}
		$ret_hr->{$author} = $author_string;
		$author_count++;
	}

	# Year.
	my $year = $self->{'_q'}->query($item, 'P577');
	$year =~ s/^\+(\d+).*$/$1/ms;
	$ret_hr->{'rok'} = $year;

	# Publisher.
	# TODO Add link.
	my $publisher = '';
	foreach my $publisher_page_id ($self->{'_q'}->query($item, 'P123')) {
		if ($publisher) {
			$publisher .= ', ';
		}
		$publisher .= $self->_get_page_label($publisher_page_id);
	}
	if ($publisher) {
		($ret_hr->{'vydavatel'}) = $publisher;
	}

	# Book series.
	# XXX Only one.
	my $series_page_id = $self->{'_q'}->query($item, 'P179');
	if ($series_page_id) {
		$ret_hr->{'edice'} = $self->_get_page_label($series_page_id);
	}
	# TODO Number in series
	# TODO Subseries (Q109810503)

	# Publication place.
	my $place_page_id = $self->{'_q'}->query($item, 'P291');
	if ($place_page_id) {
		$ret_hr->{decode_utf8('místo')} = $self->_get_page_label($place_page_id);
	}

	# Translator.
	# TODO Link to translator
	my $translator_count = 1;
	foreach my $translator_page_id ($self->{'_q'}->query($item, 'P655')) {
		my $translator_item = $self->{'_api'}->get_item($translator_page_id);
		my $family_name_id = $self->{'_q'}->query($translator_item, 'P734');
		my @given_name_ids = $self->{'_q'}->query($translator_item, 'P735');
		my $translator_name;
		if (@given_name_ids && $family_name_id) {
			$translator_name = join ' ', map { $self->_get_page_label($_) }
                                @given_name_ids;
			$translator_name .= ' '.$self->_get_page_label($family_name_id);
		} else {
			$translator_name = $self->_get_page_label($translator_page_id);
		}
		if ($ret_hr->{decode_utf8('překladatelé')}) {
			$ret_hr->{decode_utf8('překladatelé')} .= ', ';
		}
		$ret_hr->{decode_utf8('překladatelé')} .= $translator_name;
		$translator_count++;
		last if $translator_count > 3;
	}

	# Illustrators.
	my $illustrator_count = 1;
	foreach my $illustrator_page_id ($self->{'_q'}->query($item, 'P110')) {
		my $illustrator_item = $self->{'_api'}->get_item($illustrator_page_id);
		my $family_name_id = $self->{'_q'}->query($illustrator_item, 'P734');
		my @given_name_ids = $self->{'_q'}->query($illustrator_item, 'P735');
		my $illustrator_name;
		if (@given_name_ids && $family_name_id) {
			$illustrator_name = join ' ', map { $self->_get_page_label($_) }
                                @given_name_ids;
			$illustrator_name .= ' '.$self->_get_page_label($family_name_id);
		} else {
			$illustrator_name = $self->_get_page_label($illustrator_page_id);
		}
		if ($ret_hr->{decode_utf8('ilustrátoři')}) {
			$ret_hr->{decode_utf8('ilustrátoři')} .= ', ';
		}
		$ret_hr->{decode_utf8('ilustrátoři')} = $illustrator_name;
		$illustrator_count++;
		last if $illustrator_count > 3;
	}

	# ISBN.
	my $isbn_count = 1;
	foreach my $isbn ($self->{'_q'}->query($item, 'P957'),
		$self->{'_q'}->query($item, 'P212')) {

		my $isbn_key = decode_utf8('isbn');
		if ($isbn_count > 1) {
			$isbn_key .= $isbn_count;
		}
		$ret_hr->{$isbn_key} = $isbn;
		$isbn_count++;
		last if $isbn_count > 2;
	}

	# Number of pages.
	$ret_hr->{decode_utf8('počet stran')} = $self->{'_q'}->query($item, 'P1104');

	# Edition number.
	my $edition_number = $self->{'_q'}->query($item, 'P393');
	if (defined $edition_number) {
		$ret_hr->{decode_utf8('vydání')} = $edition_number;
	}

	# Online version.
	my $online_url = $self->{'_q'}->query($item, 'P953');
	if (defined $online_url) {
		$ret_hr->{'url'} = $online_url;
	}

	return $ret_hr;
}

sub _get_page_label {
	my ($self, $page_id, $lang) = @_;

	$lang //= $LANGUAGE;
	my $item = $self->{'_api'}->get_item($page_id);
	my $label = $self->{'_q'}->query($item, 'label:'.$lang);
	if (defined $label) {
		return $label;
	}
	err "No '$lang' description for '$page_id'.";
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Wikidata::Template::CS::CitaceMonografie - Base class for Wikidata command line tool wd-citace-monografie.

=head1 SYNOPSIS

 use App::Wikidata::Template::CS::CitaceMonografie;

 my $app = App::Wikidata::Template::CS::CitaceMonografie->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Wikidata::Template::CS::CitaceMonografie->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

=for comment filename=print_q79324593_in_czech.pl

 use strict;
 use warnings;

 use App::Wikidata::Template::CS::CitaceMonografie;

 # Arguments.
 @ARGV = (
         '-l cs',
         '-p',
         'Q79324593',
 );

 # Run.
 exit App::Wikidata::Template::CS::CitaceMonografie->new->run;

 # Output like:
 # {{citace monografie
 #  | autor = Mistr Eckhart
 #  | isbn = 978-80-901884-8-8
 #  | místo = Brno
 #  | počet stran = 333
 #  | překladatelé = Martin Mrskoš, Petr Snášil, Vilém Konečný
 #  | rok = 2019
 #  | titul = Kázání
 #  | vydavatel = Horus
 # }}

=head1 DEPENDENCIES

L<Class::Utils>,
L<Error::Pure>,
L<Getopt::Std>,
L<Readonly>,
L<Unicode::UTF8>,
L<Wikibase::API>,
L<Wikibase::Datatype::Query>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Wikidata-Template-CS-CitaceMonografie>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2018-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.01

=cut
