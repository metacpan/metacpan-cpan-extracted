package App::Wikidata::Print;

use strict;
use warnings;

use Class::Utils qw(set_params);
use English;
use Getopt::Std;
use Unicode::UTF8 qw(encode_utf8);
use Wikibase::API;
use Wikibase::Datatype::Print;

our $VERSION = 0.04;

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
		'r' => 0,
	};
	if (! getopts('hl:m:r', $self->{'_opts'}) || $self->{'_opts'}->{'h'} || @ARGV < 1) {
		print STDERR "Usage: $0 [-h] [-l lang] [-m mediawiki_site] [-r] [--version] wd_id\n";
		print STDERR "\t-h\t\t\tPrint help.\n";
		print STDERR "\t-l lang\t\t\tLanguage used (default is English = en).\n";
		print STDERR "\t-m mediawiki_site\tMediaWiki site (default is www.wikidata.org).\n";
		print STDERR "\t-r\t\t\tWith references.\n";
		print STDERR "\t--version\t\tPrint version.\n";
		print STDERR "\twd_id\t\t\tWikidata id (qid or pid or lid).\n";
		return 1;
	}
	my $wd_id = $ARGV[0];

	my $api = Wikibase::API->new(
		'mediawiki_site' => $self->{'_opts'}->{'m'},
	);

	my $obj = $api->get_item($wd_id);

	my $opts_hr = {
		'lang' => $self->{'_opts'}->{'l'},
	};
	if (! $self->{'_opts'}->{'r'}) {
		$opts_hr->{'no_print_references'} = 1;
	}

	eval {
		print encode_utf8(scalar Wikibase::Datatype::Print::print($obj, $opts_hr)), "\n";
	};
	if ($EVAL_ERROR) {
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
         '-l', 'cs',
         'P2668',
 );

 # Run.
 exit App::Wikidata::Print->new->run;

 # Output like:
 # Datový typ: wikibase-item
 # Štítek: proměnlivost hodnot (cs)
 # Popis: pravděpodobnost, že se prohlášení s touto vlastností změní (cs)
 # Výroky:
 #   P2559: use only instances of Q23611439 as values (en) (normální)
 #   P2559: nur Instanzen von Q23611439 als Werte verwenden (de) (normální)
 #   P2559: utiliser uniquement les instances de Q23611439 comme valeurs (fr) (normální)
 #   P2559: usar solo instancias del elemento Q23611439 (es) (normální)
 #   P2559: # ####### ########## ######## ###### ######### ######## Q23611439 (be-tarask) (normální)
 #   P2559: bruk kun forekomster av Q23611439 som verdier (nb) (normální)
 #   P2559: # # # # # # Q23611439( # # # # # # # # # # ) # # # # #  (zh-hans) (normální)
 #   P2559: gebruik alleen items van Q23611439 als waarden (nl) (normální)
 #   P2559: usar só instancias do elemento Q23611439 (gl) (normální)
 #   P2559: jako hodnoty používejte pouze instance Q23611439 (cs) (normální)
 #   P2559: usare solo istanze di Q23611439 come valori (it) (normální)
 #   P2559: utilitzeu només les instàncies de Q23611439 com a valors (ca) (normální)
 #   P2302: Q21503250 (normální)
 #    P2308: Q18616576
 #    P2309: Q21503252
 #    P2316: Q21502408
 #   P2302: Q21510865 (normální)
 #    P2308: Q23611439
 #    P2309: Q21503252
 #   P2302: Q52004125 (normální)
 #    P2305: Q29934218
 #   P2302: Q53869507 (normální)
 #    P5314: Q54828448
 #   P2302: Q21503247 (normální)
 #    P2306: P2302
 #   P2302: Q21510859 (normální)
 #    P2305: Q23611288
 #    P2305: Q24025284
 #    P2305: Q23611840
 #    P2305: Q23611587
 #    P2305: neznámá hodnota
 #   P2271: P569 (normální)
 #    P2668: Q23611288
 #   P2271: P1082 (normální)
 #    P2668: Q23611587
 #   P2271: P39 (normální)
 #    P2668: Q23611840
 #   P2271: P3185 (normální)
 #    P2668: Q24025284
 #   P2271: P11021 (normální)
 #    P2668: neznámá hodnota
 #   P1629: Q23611439 (normální)
 #   P3254: https://www.wikidata.org/wiki/Wikidata:Property_proposal/Archive/48#P2668 (normální)
 #   P31: Q19820110 (normální)
 #   P2668: Q24025284 (normální)

=head1 DEPENDENCIES

L<Class::Utils>,
L<English>,
L<Getopt::Std>,
L<Unicode::UTF8>,
L<Wikibase::API>,
L<Wikibase::Datatype::Print>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/App-Wikidata-Print>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2024 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
