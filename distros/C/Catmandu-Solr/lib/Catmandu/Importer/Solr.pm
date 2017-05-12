package Catmandu::Importer::Solr;

use Catmandu::Sane;
use Catmandu::Store::Solr;
use Catmandu;
use Moo;

our $VERSION = '0.0302';

with 'Catmandu::Importer';

has fq => (is => 'ro');
has query    => (is => 'ro');
has url => ( is => 'ro' );
has bag => ( is => 'ro' );
has id_field  => (is => 'ro', default => sub { '_id' });
has bag_field => (is => 'ro', default => sub { '_bag' });
has _bag  => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_bag',
);
has fl => (
    is => 'ro',
    lazy => 1,
    default => sub { "*" }
);

sub _build_bag {
    my $self = $_[0];
    Catmandu::Store::Solr->new( url => $self->url, bag_field => $self->bag_field, id_field => $self->id_field )->bag($self->bag());
}

sub generator {
	my ($self) = @_;

	return sub {
        state $start = 0;
        state $limit = 100;
        state $total = 100;
        state $hits = [];

        unless(scalar(@$hits)){

            return if $start >= $total;

            my $res = $self->_bag()->search(
                query => $self->query,
                fq => $self->fq,
                start => $start,
                limit => $limit,
                fl => $self->fl,
                facet => "false",
                spellcheck => "false",
                sort => $self->id_field()." asc"
            );
            $total = $res->total;
            $hits = $res->hits();

            $start += $limit;

        }

        shift(@$hits);

	}
}

sub count {
    my ( $self ) = @_;
    $self->_bag()->search( query => $self->query, fq => $self->fq, limit => 0, facet => "false", spellcheck => "false" )->total();
}


=head1 NAME

Catmandu::Importer::Solr - Catmandu module to import data from a Solr endpoint

=head1 SYNOPSIS

    # From the command line
    $ catmandu convert Solr --url "http://localhost:8983/solr" --query "type:book"

    # From perl
    use Catmandu;

    my %attrs = (
        url => "http://localhost:8983/solr",
        query => 'type:book',
        bag_field => '_bag',
        id_field => '_id'
    );

    my $importer = Catmandu->importer('Solr',%attrs);

    $importer->each(sub {
	    my $row_hash = shift;
	    ...
    });

=head1 AUTHOR

Nicolas Franck, C<< nicolas.franck at ugent.be >>

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer> , L<Catmandu::Store::Solr>

=cut

1;
