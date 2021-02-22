package Data::XLSX::Parser::Sheet;
use strict;
use warnings;

use File::Temp;
use XML::Parser::Expat;
use Archive::Zip ();
use Time::Piece ();
use Scalar::Util ();
use Carp;

use constant {
    STYLE_IDX          => 'i',
    STYLE              => 's',
    FMT                => 'f',
    REF                => 'r',
    COLUMN             => 'c',
    VALUE              => 'v',
    TYPE               => 't',
    TYPE_SHARED_STRING => 's',
    GENERATED_CELL     => 'g',
};

sub new {
    my ($class, $doc, $archive, $sheet_id_or_filepath) = @_;

    my $filepath = $sheet_id_or_filepath;
    if (Scalar::Util::looks_like_number($sheet_id_or_filepath)) {
        $filepath = sprintf 'worksheets/sheet%d.xml', $sheet_id_or_filepath;
    }

    my $self = bless {
        _document => $doc,

        _data => '',
        _is_sheetdata => 0,
        _row_count => 0,
        _current_row => [],
        _cell => undef,
        _is_value => 0,

        _shared_strings => $doc->shared_strings,
        _styles         => $doc->styles,

    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' ) or confess "couldn't create tempfile: $!";

    my $handle = $archive->sheet($filepath) or confess "couldn't get handle to sheet archive $filepath: $!";
    confess 'Failed to write temporary file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new(Namespaces=>1);
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub { $self->_char(@_) },
    );
    $parser->parse($fh);

    $self;
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;

    if ($name eq 'sheetData') {
        $self->{_is_sheetdata} = 1;
    } elsif ($self->{_is_sheetdata} and $name eq 'row') {
        $self->{_current_row} = [];
    } elsif ($name eq 'c') {
        $self->{_cell} = {
            STYLE_IDX() => $attrs{ STYLE() },
            TYPE()      => $attrs{ TYPE() },
            REF()       => $attrs{ REF() },
            COLUMN()    => scalar(@{ $self->{_current_row} }) + 1,
        };
    } elsif ($name eq 'v') {
        $self->{_is_value} = 1;
    }
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'sheetData') {
        $self->{_is_sheetdata} = 0;
    } elsif ($self->{_is_sheetdata} and $name eq 'row') {
        $self->{_row_count}++;
        $self->{_document}->_row_event( delete $self->{_current_row} );
    } elsif ($name eq 'c') {
        my $c = $self->{_cell};
        $self->_parse_rel($c);

        if (($c->{ TYPE() } || '') eq TYPE_SHARED_STRING()) {
            my $idx = int($self->{_data});
            $c->{ VALUE() } = $self->{_shared_strings}->get($idx);
        } else {
            $c->{ VALUE() } = $self->{_data};
        }

        $c->{ STYLE() } = $self->{_styles}->cell_style( $c->{ STYLE_IDX() } );
        $c->{ FMT() }   = my $cell_type = $self->{_styles}->cell_type_from_style($c->{ STYLE() });

        my $v = $c->{ VALUE() };

        if (!defined $c->{ TYPE() }) {
            # actual value (number or date)
            if ($v && defined $c->{ FMT() } &&
                    $c->{ FMT() } =~ /^datetime\.(date)?(time)?$/) {
                if (Scalar::Util::looks_like_number($v)) {
                    $c->{ VALUE() } = $self->_convert_serial_time($v);
                }
            } elsif (Scalar::Util::looks_like_number($v)) {
                $c->{ VALUE() } = $v + 0;
            }
        } else {
            if (!defined $v) {
                $c->{ VALUE() } = '';
            } elsif ($cell_type ne 'unicode') {
                # warn 'not unicode: ' . $cell_type;
                $c->{ VALUE() } = $v;
            }
        }

        push @{ $self->{_current_row} }, $c;

        $self->{_data} = '';
        $self->{_cell} = undef;
    } elsif ($name eq 'v') {
        $self->{_is_value} = 0;
    }
}

sub _convert_serial_time {
    my ($self, $serial_time) = @_;

    # UNIX Epoch(1970/1/1 00:00:00) is 25569.0
    my $epoch = ($serial_time - 25569) * 24 * 60 * 60;
    # round to nearest second to compensate for floating point errors
    $epoch = $epoch > 0 ? int( $epoch + 0.5) : int( $epoch - 0.5);
    return Time::Piece::gmtime($epoch);
}

sub _char {
    my ($self, $parser, $data) = @_;

    if ($self->{_is_value}) {
        $self->{_data} .= $data;
    }
}

sub _parse_rel {
    my ($self, $cell) = @_;

    my ($column, $row);
    my $v;
    if ($cell->{ REF() }) {
        ($column, $row) = $cell->{ REF() } =~ /([A-Z]+)(\d+)/;
        $v = 0;
        my $i = 0;
        for my $ch (split '', $column) {
            my $s = length($column) - $i++ - 1;
            $v += (ord($ch) - ord('A') + 1) * (26**$s);
        }
        $cell->{ row } = $row + 0;
        if ($cell->{ COLUMN() } > $v) {
            carp sprintf 'Detected smaller index than current cell, something is wrong! (row %s): %s <> %s', $row, $v, $cell->{ COLUMN() };
        }
    } else {
        # fallback if REF() not defined
        $v = $cell->{ COLUMN() };
        $row = $self->{_row_count}+1;
        $cell->{ row } = $row;
    }

    # add omitted cells as empty...
    for ($cell->{ COLUMN() } .. $v-1) {
        push @{ $self->{_current_row} }, {
            GENERATED_CELL() => 1,
            STYLE_IDX()      => undef,
            TYPE()           => undef,
            REF()            => [ $_, $row ],
            COLUMN()         => $_,
            VALUE()          => '',
            FMT()            => 'unicode',
        };
    }
}

1;
__END__

=head1 NAME

Data::XLSX::Parser::Sheet - Sheet class of Data::XLSX::Parser

=head1 DESCRIPTION

Data::XLSX::Parser::Sheet parses the cells in a sheet and invokes the _row_event method from the main parser object to return the processed row.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=cut