package Catmandu::Importer::PDFInfo;

use Catmandu::Sane;
use Catmandu::Util qw(:is);
use Poppler;
use Moo;

our $VERSION = '0.012';

with 'Catmandu::Importer';

has poppler_glib_version => (
    is => "ro",
    init_arg => undef,
    lazy => 1,
    builder => "_build_poppler_glib_version"
);
has has_date_bug => (
    is => "ro",
    init_arg => undef,
    lazy => 1,
    builder => "_build_has_date_bug"
);
has date_offset => (
    is => "ro",
    init_arg => undef,
    lazy => 1,
    default => sub {
        require DateTime;
        DateTime->now( time_zone => "local" )->offset();
    }
);
sub _build_poppler_glib_version {
    require ExtUtils::PkgConfig;
    ExtUtils::PkgConfig->modversion('poppler-glib');
}
sub _build_has_date_bug {
    require version;
    version->parse( $_[0]->poppler_glib_version() ) < version->parse("0.45.0") ? 1 : 0;
}

sub _createDoc {
    my $self = $_[0];

    my $pdf = Poppler::Document->new_from_file( $self->file );

    my $record = +{
        version => $pdf->get_pdf_version_string(),
        title => $pdf->get_title(),
        author => $pdf->get_author(),
        subject => $pdf->get_subject(),
        keywords => $pdf->get_keywords(),
        creator => $pdf->get_creator(),
        producer => $pdf->get_producer(),
        creation_date => $pdf->get_creation_date(),
        modification_date => $pdf->get_modification_date(),
        metadata => $pdf->get_metadata()
    };

    if( $self->has_date_bug() ) {

        if( is_natural( $record->{creation_date} ) ){
            $record->{creation_date} += $self->date_offset();
        }
        if( is_natural( $record->{modification_date} ) ){
            $record->{modification_date} += $self->date_offset();
        }

    }

    $record;
}

sub generator {
    my ($self) = @_;

    return sub {
        state $doc;

        unless($doc){
            $doc = $self->_createDoc();
            return $doc;
        }
        return;

    }
}
sub DESTROY {
    my ($self) = @_;
    close($self->fh);
}

=encoding utf8

=head1 NAME

Catmandu::Importer::PDFInfo - Catmandu importer to extract metadata from one pdf

=head1 SYNOPSIS

    # From the command line

    # Export pdf information

    $ catmandu convert PDFInfo --file input.pdf to YAML

    #In a script

    use Catmandu::Sane;

    use Catmandu::Importer::PDFInfo;

    my $importer = Catmandu::Importer::PDFInfo->new( file => "/tmp/input.pdf" );

    $importer->each(sub{

        my $pdf = $_[0];
        #..

    });

=head1 EXAMPLE OUTPUT IN YAML

    author: ~
    creation_date: 1207274644
    creator: PDFplus
    keywords: ~
    metadata: ~
    modification_date: 1421574847
    producer: "Nobody at all"
    subject: ~
    title: "Hello there"
    version: PDF-1.6

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu>, L<Catmandu::Importer> , L<Poppler>

=cut

1;
