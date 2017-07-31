package Catmandu::Importer::PDF;

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

    my $num_pages = $pdf->get_n_pages();

    my $record = {
        document => {
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
        },
        pages => []
    };

    for(my $i = 0;$i < $num_pages;$i++){
        my $page = $pdf->get_page($i);
        my $text = $page->get_text();
        my($w,$h) = $page->get_size;
        my $label = $page->get_label();

        my $p = {
            width => $w,
            height => $h,
            label => $label,
            text => $text
        };

        push @{ $record->{pages} },$p;
    }

    if( $self->has_date_bug() ) {

        if( is_natural( $record->{document}->{creation_date} ) ){
            $record->{document}->{creation_date} += $self->date_offset();
        }
        if( is_natural( $record->{document}->{modification_date} ) ){
            $record->{document}->{modification_date} += $self->date_offset();
        }

    }

    $record;
}

sub generator {
    my ($self) = @_;

    return sub {
        state $doc = undef;

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

Catmandu::Importer::PDF - Catmandu importer to extract data from one pdf

=begin markdown

# STATUS

[![Build Status](https://travis-ci.org/LibreCat/Catmandu-Importer-PDF.svg?branch=master)](https://travis-ci.org/LibreCat/Catmandu-Importer-PDF)
[![Coverage](https://coveralls.io/repos/LibreCat/Catmandu-Importer-PDF/badge.png?branch=master)](https://coveralls.io/r/LibreCat/Catmandu-Importer-PDF)
[![CPANTS kwalitee](http://cpants.cpanauthors.org/dist/Catmandu-Importer-PDF.png)](http://cpants.cpanauthors.org/dist/Catmandu-Importer-PDF)

=end markdown

=head1 SYNOPSIS

    #From the command line

    #Export pdf information, and text

    $ catmandu convert PDF --file input.pdf to YAML

    #In a script

    use Catmandu::Sane;

    use Catmandu::Importer::PDF;

    my $importer = Catmandu::Importer::PDF->new( file => "/tmp/input.pdf" );

    $importer->each(sub{

        my $pdf = $_[0];
        #..

    });

=head1 EXAMPLE OUTPUT IN YAML

    document:
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
    pages:
    - label: Cover Page
      height: 878
      width: 595
      text: "Hello world"

=head1 INSTALLATION

In order to install this package you need the following system packages installed

=over

=item Centos

Requires Centos 7 at minimum. Centos 6 only has poppler-glib 0.12.

* perl-devel

* make

* gcc

* gcc-c++

* libyaml-devel

* libyaml

* poppler-glib ( >= 0.16 )

* poppler-glib-devel ( >= 0.16 )

* gobject-introspection-devel

=item Ubuntu

Requires Ubuntu 14 at minimum.

* libpoppler-glib8

* libpoppler-glib-dev

* gobject-introspection

* libgirepository1.0-dev

=back

=head1 NOTES

* L<Catmandu::Importer::PDF> returns one record, containing both document information, and page text

* L<Catmandu::Importer::PDFPages> returns multiple records, each for each page

* L<Catmandu::Importer::PDFInfo> returns one record, containing document information

=head1 KNOWN ISSUES

* Due to a bug in older versions of poppler-glib (bug #94173), the creation_date and modification_date can be returned in local time, instead of utc. This module tries to fix that.

* Some versions of Poppler add form feeds and newlines to a text line, while others don't.

=head1 AUTHORS

Nicolas Franck C<< <nicolas.franck at ugent.be> >>

=head1 SEE ALSO

L<Catmandu::Importer::PDFInfo>, L<Catmandu::Importer::PDFPages>, L<Catmandu>, L<Catmandu::Importer> , L<Poppler>

=cut

1;
