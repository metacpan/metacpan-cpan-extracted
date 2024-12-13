package Catmandu::Importer::XLS;

our $VERSION = '0.11';

use namespace::clean;
use Catmandu::Sane;
use Types::Standard qw(Enum);
use Spreadsheet::ParseExcel;
use Spreadsheet::ParseExcel::Utility qw(int2col);
use Moo;

with 'Catmandu::Importer';

has xls     => (is => 'ro', builder => '_build_xls');
has header  => (is => 'ro', default => sub {1});
has columns => (is => 'ro', default => sub {0});
has fields  => (
    is     => 'rw',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') {return $fields}
        if (ref $fields eq 'HASH')  {return [sort keys %$fields]}
        return [split ',', $fields];
    },
);
has empty => (
    is      => 'ro',
    isa     => Enum [qw(ignore string nil)],
    default => sub {'string'}
);
has worksheet => (is => 'ro', default => sub {0});
has _n        => (is => 'rw', default => sub {0});
has _row_min  => (is => 'rw');
has _row_max  => (is => 'rw');
has _col_min  => (is => 'rw');
has _col_max  => (is => 'rw');

sub BUILD {
    my $self = shift;

    if ($self->header) {
        if ($self->fields) {
            $self->{_n}++;
        }
        elsif ($self->columns) {
            $self->fields([$self->_get_cols]);
            $self->{_n}++;
        }
        else {
            $self->fields([$self->_get_row]);
            $self->{_n}++;
        }
    }
    else {
        if (!$self->fields || $self->columns) {
            $self->fields([$self->_get_cols]);
        }
    }
}

sub _build_xls {
    my ($self) = @_;
    my $parser = Spreadsheet::ParseExcel->new();
    my $xls    = $parser->parse($self->file)
        or Catmandu::Error->throw(
        "could not parse file \"$self->{file}\": " . $parser->error());

    $xls = $xls->worksheet($self->worksheet)
        or Catmandu::Error->throw(
        "worksheet $self->{worksheet} does not exist.");
    ($self->{_row_min}, $self->{_row_max}) = $xls->row_range();
    ($self->{_col_min}, $self->{_col_max}) = $xls->col_range();
    return $xls;
}

sub generator {
    my ($self) = @_;
    sub {
        while ($self->_n <= $self->_row_max) {
            my @data = $self->_get_row();
            $self->{_n}++;
            my @fields = @{$self->fields()};
            my %hash   = map {
                my $key = shift @fields;

                if (defined $_) {
                    ($key => $_);
                }
                elsif ($self->empty eq 'ignore') {
                    ();
                }
                elsif ($self->empty eq 'string') {
                    ($key => '');
                }
                elsif ($self->empty eq 'nil') {
                    ($key => undef);
                }
            } @data;
            return \%hash;
        }
        return;
    }
}

sub _get_row {
    my ($self) = @_;
    my @row;
    for my $col ($self->_col_min .. $self->_col_max) {
        my $cell = $self->xls->get_cell($self->_n, $col);
        if ($cell) {
            push(@row, $cell->value());
        }
        else {
            push(@row, undef);
        }
    }
    return @row;
}

sub _get_cols {
    my ($self) = @_;

    my @row;
    for my $col ($self->_col_min .. $self->_col_max) {

        if (!$self->header || $self->columns) {
            push(@row, int2col($col));
        }
        else {
            my $cell = $self->xls->get_cell($self->_n, $col);
            if ($cell) {
                push(@row, $cell->value());
            }
            else {
                push(@row, undef);
            }
        }
    }
    return @row;
}

=head1 NAME

Catmandu::Importer::XLS - Package that imports XLS files

=head1 SYNOPSIS

    # On the command line
    $ catmandu convert XLS < ./t/test.xls
    $ catmandu convert XLS --header 0 < ./t/test.xls
    $ catmandu convert XLS --fields 1,2,3 < ./t/test.xls
    $ catmandu convert XLS --columns 1 < ./t/test.xls
    $ catmandu convert XLS --worksheet 1 < ./t/test.xls

    # Or in Perl
    use Catmandu::Importer::XLS;

    my $importer = Catmandu::Importer::XLS->new(file => "./t/test.xls");

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 DESCRIPTION

L<Catmandu> importer for XLS files.

=head1 METHODS

This module inherits all methods of L<Catmandu::Importer> and by this
L<Catmandu::Iterable>.

=head1 CONFIGURATION

In addition to the configuration provided by L<Catmandu::Importer> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:

=over

=item header

By default object fields are read from the XLS header line. If no header
line is avaiable object fields are named as column coordinates (A,B,C,...). Default: 1.

=item fields

Provide custom object field names as array, hash reference or comma-
separated list.

=item columns

When the 'columns' option is provided, then the object fields are named as
column coordinates (A,B,C,...). Default: 0.

=item empty

How to treat empty fields in the data. When the option value is 'string', the
empty values will be empty strings. When the option value is 'nil', the empty
values will get turned into undefined fields. When the option is 'ignore', the
empty values are ignored.  Default is 'string'.

=item worksheet

If the Excel workbook contains more than one worksheet, you can select a specific worksheet by its index number (0,1,2,...). Default: 0.

=back

=head1 SEE ALSO

L<Catmandu::Importer>, L<Catmandu::Iterable>, L<Catmandu::Importer::CSV>, L<Catmandu::Importer::XLSX>.

=cut

1;
