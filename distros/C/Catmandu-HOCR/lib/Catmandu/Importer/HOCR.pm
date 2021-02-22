package Catmandu::Importer::HOCR;
use Catmandu::Sane;
use Moo;
use XML::LibXML::Reader;
use Catmandu::Error;
use namespace::clean;

with "Catmandu::Importer";

has reader => ( is => "lazy", init_arg => undef );

has current_page => (
    is => "rw",
    default => sub { undef; }
);

sub _build_reader {
    my $self = $_[0];
    binmode $self->fh;
    my $reader = XML::LibXML::Reader->new(
        IO => $self->fh,
        validation => 0,
        load_ext_dtd => 0
    ) or Catmandu::Error->throw("unable to read file");

    $reader;
}

sub _parse_ocr_attr {

    my ( $key, $value ) = @_;

    if ( $key eq "bbox" ) {

        my @coords = map { int($_) } split( " ", $value );
        return +{
            x1 => $coords[0], y1 => $coords[1],
            x2 => $coords[2], y2 => $coords[3]
        };

    }
    elsif ( $key eq "x_wconf" ) {

        return int($value);

    }

    $value;

}

sub _parse_ocr_attrs {

    my $title = $_[0];

    map {
        $_ =~ s/^\s+//o;
        $_ =~ s/\s+$//o;

        my $idx = index( $_, " " );
        my $key;
        my $val;

        if( $idx >= 0 ) {
            $key = substr( $_, 0, $idx );
            $val = substr( $_, $idx + 1 );
            $val = _parse_ocr_attr( $key, $val );
        }
        else {
            $key = $_;
            $val = undef;
        }

        $key => $val;
    } split( ";", $title );

}

sub _parse_coords {
    my $title = $_[0];
    my %attrs = _parse_ocr_attrs( $title );
    my $bbox = $attrs{bbox};
    my $x = $bbox->{x1};
    my $y = $bbox->{y1};
    my $w = $bbox->{x2} - $bbox->{x1};
    my $h = $bbox->{y2} - $bbox->{y1};

    +{
        x => $x,
        y => $y,
        w => $w,
        h => $h
    };
}

sub _read {
    my $state = $_[0]->reader->read() or return;
    $state < 0 && Catmandu::Error->throw("error occurred during parsing of file");
    $state;
}

sub _next {

    my $self = $_[0];
    state $start_element = XML_READER_TYPE_ELEMENT;
    state $end_element   = XML_READER_TYPE_END_ELEMENT;

    my $reader = $self->reader();

    my $line;

    while( $self->_read ){

        my $name = $reader->name();
        my $nodeType = $reader->nodeType();
        my $class = $reader->getAttribute("class");

        if ( $nodeType == $start_element && defined($class) && $class eq "ocr_page" ) {

            my $old_page = $self->current_page // +{ no => 0 };

            my $title = $reader->getAttribute("title");
            my $coords = _parse_coords( $title );

            $self->current_page({
                no => $old_page->{no} + 1,
                %$coords
            });

            next;

        }
        elsif ( $nodeType == $start_element && defined($class) && $class eq "ocr_line" ) {

            my $title = $reader->getAttribute("title");
            my $coords = _parse_coords( $title );

            my $current_page = $self->current_page();
            $line = +{
                page => $current_page->{no},
                page_x => $current_page->{x},
                page_y => $current_page->{y},
                page_w => $current_page->{w},
                page_h => $current_page->{h},
                %$coords,
                text => []
            };

        }
        elsif ( $nodeType == $start_element && defined($class) && ($class eq "ocr_word" || $class eq "ocrx_word") ) {

            # only include text nodes, and read until end of span
            while( $reader->read() ){

                # text may be enclosed with <strong>
                if( $reader->nodeType() == XML_READER_TYPE_TEXT ){
                    push @{$line->{text}}, $reader->value();
                }
                elsif( $reader->nodeType == $end_element && $reader->localName eq "span" ){
                    last;
                }

            }

        }
        elsif ( defined($line) && $nodeType == $end_element ) {

            if ( $line ) {

                $line->{text} = join(" ", @{ $line->{text} });

            }
            last;

        }

    }

    $line;
}

sub generator {

    my $self = $_[0];

    sub {
        $self->_next();
    };

}

1;
