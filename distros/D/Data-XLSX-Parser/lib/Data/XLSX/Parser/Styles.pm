package Data::XLSX::Parser::Styles;
use strict;
use warnings;

use XML::Parser::Expat;
use Archive::Zip ();
use File::Temp;

use constant BUILTIN_FMT  => 0;
use constant BUILTIN_TYPE => 1;

use constant BUILTIN_NUM_FMTS => [
    ['@', 'unicode'],           # 0x00
    ['0', 'int'],               # 0x01
    ['0.00', 'float'],          # 0x02
    ['#,##0', 'float'],         # 0x03
    ['#,##0.00', 'float'],      # 0x04
    ['($#,##0_);($#,##0)', 'float'], # 0x05
    ['($#,##0_);[RED]($#,##0)', 'float'], # 0x06
    ['($#,##0.00_);($#,##0.00_)', 'float'], # 0x07
    ['($#,##0.00_);[RED]($#,##0.00_)', 'float'], # 0x08
    ['0%', 'int'],                               # 0x09
    ['0.00%', 'float'],                          # 0x0a
    ['0.00E+00', 'float'],                       # 0x0b
    ['# ?/?', 'float'],                          # 0x0c
    ['# ??/??', 'float'],                        # 0x0d
    ['m-d-yy', 'datetime.date'],                 # 0x0e
    ['d-mmm-yy', 'datetime.date'],               # 0x0f
    ['d-mmm', 'datetime.date'],                  # 0x10
    ['mmm-yy', 'datetime.date'],                 # 0x11
    ['h:mm AM/PM', 'datetime.time'],             # 0x12
    ['h:mm:ss AM/PM', 'datetime.time'],          # 0x13
    ['h:mm', 'datetime.time'],                   # 0x14
    ['h:mm:ss', 'datetime.time'],                # 0x15
    ['m-d-yy h:mm', 'datetime.datetime'],        # 0x16
    #0x17-0x24 -- Differs in Natinal
    undef,                      # 0x17
    undef,                      # 0x18
    undef,                      # 0x19
    undef,                      # 0x1a
    undef,                      # 0x1b
    undef,                      # 0x1c
    undef,                      # 0x1d
    undef,                      # 0x1e
    undef,                      # 0x1f
    undef,                      # 0x20
    undef,                      # 0x21
    undef,                      # 0x22
    undef,                      # 0x23
    undef,                      # 0x24
    ['(#,##0_);(#,##0)', 'int'], # 0x25
    ['(#,##0_);[RED](#,##0)', 'int'], # 0x26
    ['(#,##0.00);(#,##0.00)', 'float'], # 0x27
    ['(#,##0.00);[RED](#,##0.00)', 'float'], # 0x28
    ['_(*#,##0_);_(*(#,##0);_(*"-"_);_(@_)', 'float'], # 0x29
    ['_($*#,##0_);_($*(#,##0);_(*"-"_);_(@_)', 'float'], # 0x2a
    ['_(*#,##0.00_);_(*(#,##0.00);_(*"-"??_);_(@_)', 'float'], # 0x2b
    ['_($*#,##0.00_);_($*(#,##0.00);_(*"-"??_);_(@_)', 'float'], # 0x2c
    ['mm:ss', 'datetime.timedelta'],                             # 0x2d
    ['[h]:mm:ss', 'datetime.timedelta'],                         # 0x2e
    ['mm:ss.0', 'datetime.timedelta'],                           # 0x2f
    ['##0.0E+0', 'float'],                                       # 0x30
    ['@', 'unicode'],                                            # 0x31
];

sub new {
    my ($class, $archive) = @_;

    my $self = bless {
        _number_formats => [],

        _is_cell_xfs   => 0,
        _current_style => undef,
    }, $class;

    my $fh = File::Temp->new( SUFFIX => '.xml' );

    my $handle = $archive->styles;
    die 'Failed to write temporally file: ', $fh->filename
        unless $handle->extractToFileNamed($fh->filename) == Archive::Zip::AZ_OK;

    my $parser = XML::Parser::Expat->new;
    $parser->setHandlers(
        Start => sub { $self->_start(@_) },
        End   => sub { $self->_end(@_) },
        Char  => sub {  },
    );
    $parser->parse($fh);

    $self;
}

sub cell_style {
    my ($self, $style_id) = @_;
    $style_id ||= 0;
    $self->{_number_formats}[int $style_id];
}

sub cell_type_from_style {
    my ($self, $style) = @_;

    if ($style->{numFmt} > scalar @{ BUILTIN_NUM_FMTS() }) {
        return $self->{_num_fmt}{ $style->{numFmt} }{_type} // undef;
    }

    BUILTIN_NUM_FMTS->[ $style->{numFmt} ][BUILTIN_TYPE];
}

sub cell_format_from_style {
    my ($self, $style) = @_;

    if ($style->{numFmt} > scalar @{ BUILTIN_NUM_FMTS() }) {
        return $self->{_num_fmt}{ $style->{numFmt} }{formatCode} // undef;
    }

    BUILTIN_NUM_FMTS->[ $style->{numFmt} ][BUILTIN_FMT];
}

sub _start {
    my ($self, $parser, $name, %attrs) = @_;

    if ($name eq 'cellXfs') {
        $self->{_is_cell_xfs} = 1;
    }
    elsif ($self->{_is_cell_xfs} and $name eq 'xf') {
        $self->{_current_style} = {
            numFmt => int($attrs{numFmtId}) || 0,
            exists $attrs{fontId}   ? ( font   => $attrs{fontId} )   : (),
            exists $attrs{fillId}   ? ( fill   => $attrs{fillId} )   : (),
            exists $attrs{borderId} ? ( border => $attrs{borderId} ) : (),
            exists $attrs{xfId}     ? ( xf     => $attrs{xfId} )     : (),
            exists $attrs{applyFont} ? ( applyFont => $attrs{applyFont} ) : (),
            exists $attrs{applyNumberFormat} ? ( applyNumFmt => $attrs{applyNumberFormat} ) : (),
        };
    }
    elsif ($name eq 'numFmts') {
        $self->{_is_num_fmts} = 1;
    }
    elsif ($self->{_is_num_fmts} and $name eq 'numFmt'){
        $self->{_current_numfmt} = {
            numFmtId   => $attrs{numFmtId},
            exists $attrs{formatCode} ? (
                formatCode => $attrs{formatCode},
                _type      => $self->_parse_format_code_type($attrs{formatCode}),
            ) : (),
        };
    }
}

sub _end {
    my ($self, $parser, $name) = @_;

    if ($name eq 'cellXfs') {
        $self->{_is_cell_xfs} = 0;
    }
    elsif ($self->{_current_style} and $name eq 'xf') {
        push @{ $self->{_number_formats } }, delete $self->{_current_style};
    }
    elsif ($name eq 'numFmts') {
        $self->{_is_num_fmts} = 0;
    }
    elsif ($self->{_current_numfmt} and $name eq 'numFmt') {
        my $id = $self->{_current_numfmt}{numFmtId};
        $self->{_num_fmt}{ $id } = delete $self->{_current_numfmt};
    }
}

sub _parse_format_code_type {
    my ($self, $format_code) = @_;

    my $type;
    if ($format_code =~ /;/) {
        $type = 'unicode';
    } elsif ($format_code =~ /(y|m|d|h|s)/) {
        $type = 'datetime.';

        $type .= 'date' if $format_code =~ /(y|d)/;
        $type .= 'time' if $format_code =~ /(h|s)/;

        $type .= 'date' if $type eq 'datetime.'; # assume as date only specified 'm'
    } else {
        $type = 'unicode';
    }

    return $type;
}

1;
