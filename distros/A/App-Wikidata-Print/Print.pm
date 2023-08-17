package App::Wikidata::Print;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Getopt::Std;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::API;
use Wikibase::Datatype::Print::Item;
use Wikibase::Datatype::Print::Lexeme;
use Wikibase::Datatype::Print::Property;

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
		'l' => 'en',
		'm' => 'www.wikidata.org',
	};
	if (! getopts('hl:m:', $self->{'_opts'}) || $self->{'_opts'}->{'h'}) {
		print STDERR "Usage: $0 [-h] [-l lang] [-m mediawiki_site] [--version] wd_id\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-l lang\t\t\tLanguage used (default is English = en).\n";
		print STDERR "\t-m mediawiki_site\tMediaWiki site (default is www.wikidata.org).\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\twd_id\t\t\tWikidata id (qid or pid or lid).\n";
		return 1;
	}
	my $wd_id = $ARGV[0];

	my $api = Wikibase::API->new(
		'mediawiki_site' => $self->{'_opts'}->{'m'},
	);

	my $obj = $api->get_item($wd_id);

	if (ref $obj eq 'Wikibase::Datatype::Item') {
		print encode_utf8(scalar Wikibase::Datatype::Print::Item::print($obj, {
			'lang' => $self->{'_opts'}->{'l'},
		})), "\n";
	} elsif (ref $obj eq 'Wikibase::Datatype::Lexeme') {
		print encode_utf8(scalar Wikibase::Datatype::Print::Lexeme::print($obj, {
			'lang' => $self->{'_opts'}->{'l'},
		})), "\n";
	} elsif (ref $obj eq 'Wikibase::Datatype::Property') {
		print encode_utf8(scalar Wikibase::Datatype::Print::Property::print($obj, {
			'lang' => $self->{'_opts'}->{'l'},
		})), "\n";
	} else {
		print STDERR "Unsupported Wikibase::Datatype object.";
		return 1;
	}

	return 0;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

App::Wikidata::Print - Base class for Wikidata command line tool wd-print.

=head1 SYNOPSIS

 use App::Wikidata::Print;

 my $app = App::Wikidata::Print->new;
 my $exit_code = $app->run;

=head1 METHODS

=head2 C<new>

 my $app = App::Wikidata::Print->new;

Constructor.

Returns instance of object.

=head2 C<run>

 my $exit_code = $app->run;

Run.

Returns 1 for error, 0 for success.

=head1 EXAMPLE

=for comment filename=print_p2668_in_czech.pl

 use strict;
 use warnings;

 use App::Wikidata::Print;

 # Arguments.
 @ARGV = (
         '-l cs',
         'P2668',
 );

 # Run.
 exit App::Wikidata::Print->new->run;

 # Output like:
 # Data type: wikibase-item
 # Label: proměnlivost hodnot (cs)
 # Description: pravděpodobnost, že se prohlášení s touto vlastností změní (cs)
 # Statements:
 #   P2302: Q21503250 (normal)
 #    P2308: Q18616576
 #    P2309: Q21503252
 #    P2316: Q21502408
 #   P2302: Q21510865 (normal)
 #    P2308: Q23611439
 #    P2309: Q21503252
 #   P2302: Q52004125 (normal)
 #    P2305: Q29934218
 #   P2302: Q53869507 (normal)
 #    P5314: Q54828448
 #   P2302: Q21503247 (normal)
 #    P2306: P2302
 #   P2302: Q21510859 (normal)
 #    P2305: Q23611288
 #    P2305: Q24025284
 #    P2305: Q23611840
 #    P2305: Q23611587
 #    P2305: unknown value
 #   P2668: Q24025284 (normal)
 #   P3254: https://www.wikidata.org/wiki/Wikidata:Property_proposal/Archive/48#P2668 (normal)
 #   P31: Q19820110 (normal)
 #   P2271: P569 (normal)
 #    P2668: Q23611288
 #   P2271: P1082 (normal)
 #    P2668: Q23611587
 #   P2271: P39 (normal)
 #    P2668: Q23611840
 #   P2271: P3185 (normal)
 #    P2668: Q24025284
 #   P2271: P11021 (normal)
 #    P2668: unknown value
 #   P1629: Q23611439 (normal)
 #   P2559: use only instances of Q23611439 as values (en) (normal)
 #   P2559: nur Instanzen von Q23611439 als Werte verwenden (de) (normal)
 #   P2559: utiliser uniquement les instances de Q23611439 comme valeurs (fr) (normal)
 #   P2559: usar solo instancias del elemento Q23611439 (es) (normal)
 #   P2559: у якасьці значэньняў ужывайце толькі сутнасьці элемэнту Q23611439 (be-tarask) (normal)
 #   P2559: bruk kun forekomster av Q23611439 som verdier (nb) (normal)
 #   P2559: 请只将性质为Q23611439（维基数据属性更改频率）的项作为值 (zh-hans) (normal)
 #   P2559: gebruik alleen items van Q23611439 als waarden (nl) (normal)
 #   P2559: usar só instancias do elemento Q23611439 (gl) (normal)
 #   P2559: jako hodnoty používejte pouze instance Q23611439 (cs) (normal)
 #   P2559: usare solo istanze di Q23611439 come valori (it) (normal)
 #   P2559: utilitzeu només les instàncies de Q23611439 com a valors (ca) (normal)

=head1 DEPENDENCIES

L<Class::Utils>,
L<Getopt::Std>,
L<Unicode::UTF8>,
L<Wikibase::API>,
L<Wikibase::Datatype::Print::Item>,
L<Wikibase::Datatype::Print::Lexeme>,
L<Wikibase::Datatype::Print::Property>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Wikidata-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2023 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.02

=cut
