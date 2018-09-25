package Catmandu::Importer::ALTOXML;
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

has current_block => (
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

sub _get_coords {
    my $reader = $_[0];

    my $coords = +{
        x => $reader->getAttribute("HPOS"),
        y => $reader->getAttribute("VPOS"),
        w => $reader->getAttribute("WIDTH"),
        h => $reader->getAttribute("HEIGHT")
    };

    for(keys %$coords){
        $coords->{$_} += 0 if defined($coords->{$_});
    }

    $coords;
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

        if ( $nodeType == $start_element && $name eq "Page" ) {

            my $old_page = $self->current_page // +{ no => 0 };
            my $coords = _get_coords( $reader );

            $self->current_page({
                no => $old_page->{no} + 1,
                %$coords
            });

            next;

        }
        elsif ( $nodeType == $start_element && $name eq "TextBlock" ) {

            my $old_block = $self->current_block() // +{ no => 0 };
            $self->current_block({
                %{ _get_coords( $reader ) },
                no => $old_block->{no} + 1,
                no_lines => 0
            });

        }
        elsif ( $nodeType == $start_element && $name eq "TextLine" ) {

            my $current_block = $self->current_block();

            if ( $current_block ) {

                $current_block->{no_lines}++;

            }

            my $coords = _get_coords( $reader );

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

            if ( $current_block ) {

                $line->{block} = $current_block->{no};
                $line->{"block_$_"} = $current_block->{$_} for qw(x y w h);

            }

        }
        elsif ( $nodeType == $end_element && $name eq "TextBlock" ) {

            my $current_block = $self->current_block();

            #something wrong with text_line dimensions. Use all text_block coordinates if only one text_line
            if ( defined( $line ) && ($line->{w} == 0 || $line->{h} == 0 ) &&  $current_block->{no_lines} == 1 ) {

                $line->{$_} = $current_block->{$_} for qw(x y w h);

            }

        }
        elsif ( $nodeType == $start_element && $name eq "String" ) {

            if( $line ) {

                push @{$line->{text}}, $reader->getAttribute("CONTENT");

            }

        }
        elsif ( $nodeType == $end_element && $name eq "TextLine" ) {

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
