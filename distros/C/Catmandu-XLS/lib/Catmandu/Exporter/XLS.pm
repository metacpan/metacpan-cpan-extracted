package Catmandu::Exporter::XLS;

our $VERSION = '0.09';

use namespace::clean;
use Catmandu::Sane;
use Spreadsheet::WriteExcel;
use Moo;

with 'Catmandu::Exporter';

has xls       => (is => 'ro', lazy => 1, builder => '_build_xls');
has worksheet => (is => 'ro', lazy => 1, builder => '_build_worksheet');
has header => (is => 'ro', default => sub {1});
has fields => (
    is     => 'rw',
    coerce => sub {
        my $fields = $_[0];
        if (ref $fields eq 'ARRAY') {return $fields}
        return [split ',', $fields];
    },
);
has columns => (
    is     => 'rw',
    coerce => sub {
        my $columns = $_[0];
        if (ref $columns eq 'ARRAY') {return $columns}
        return [split ',', $columns];
    },
);
has _n => (is => 'rw', default => sub {0});

sub BUILD {
    my $self    = shift;
    my $columns = $self->columns;
    my $fields  = $self->fields;
    if ($fields && $columns && scalar @{$fields} != scalar @{$columns}) {
        Catmandu::Error->throw(
            "arguments 'fields' and 'columns' have different number of elements"
        );
    }
}

sub _build_xls {
    my $xls = Spreadsheet::WriteExcel->new($_[0]->fh);
    $xls->set_properties(utf8 => 1);
    $xls;
}

sub _build_worksheet {
    $_[0]->xls->add_worksheet;
}

sub encoding {':raw'}

sub add {
    my ($self, $data) = @_;
    my $fields = $self->fields || $self->fields([sort keys %$data]);

    if ($self->header && $self->_n == 0) {
        for (my $i = 0; $i < @$fields; $i++) {
            my $field = $self->columns ? $self->columns->[$i] : $fields->[$i];

            # keep for backward compatibility (header could be a hashref)
            $field = $self->header->{$field}
                if ref $self->header && defined $self->header->{$field};

            $self->worksheet->write_string($self->_n, $i, $field);
        }
        $self->{_n}++;
    }

    for (my $i = 0; $i < @$fields; $i++) {
        $self->worksheet->write_string($self->_n, $i,
            $data->{$fields->[$i]} // "");
    }
    $self->{_n}++;
}

sub commit {
    $_[0]->xls->close;
}

=head1 NAME

Catmandu::Exporter::XLS - Package that exports XLS files

=head1 SYNOPSIS

    # On the command line
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLS --file test.xls
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLS --file test.xls --header 0
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLS --file test.xls --fields a,c
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLS --file test.xls --fields a,c --columns ALPHA,CHARLIE

    # Or in Perl
    use Catmandu::Exporter::XLS;

    my $exporter = Catmandu::Exporter::XLS->new(
                file => 'test.xls',
                fields => 'a,b,c',
                columns => 'ALPHA,BRAVO,CHARLIE',
                header => 1);

    $exporter->add({a => 1, b => 2, c => 3});
    $exporter->add_many($arrayref);

    $exporter->commit;

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

L<Catmandu> exporter for Excel XLS files.

=head1 METHODS

See L<Catmandu::Exporter>, L<Catmandu::Addable>, L<Catmandu::Fixable>, 
L<Catmandu::Counter>, and L<Catmandu::Logger> for a full list of methods.

=head1 CONFIGURATION
 
In addition to the configuration provided by L<Catmandu::Exporter> (C<file>,
C<fh>, etc.) the importer can be configured with the following parameters:
 
=over
 
=item header

Include a header line with column names, if set to 1 (default). 

=item fields

List of fields to be used as columns, given as array reference or 
comma-separated string

=item columns

List of custom column names, given as array reference or comma-separated 
list. 
 
=back

=head1 SEE ALSO

L<Catmandu::Exporter::CSV>, L<Catmandu::Exporter::XLSX>.

=cut

1;
