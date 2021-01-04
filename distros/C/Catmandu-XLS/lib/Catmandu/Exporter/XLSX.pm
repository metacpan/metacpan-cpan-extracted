package Catmandu::Exporter::XLSX;

our $VERSION = '0.10';

use namespace::clean;
use Catmandu::Sane;
use Excel::Writer::XLSX;
use Moo;

with 'Catmandu::TabularExporter';

has xlsx      => (is => 'ro', lazy => 1, builder => '_build_xlsx');
has worksheet => (is => 'ro', lazy => 1, builder => '_build_worksheet');
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

sub _build_xlsx {
    my $xlsx = Excel::Writer::XLSX->new($_[0]->fh);
    $xlsx;
}

sub _build_worksheet {
    $_[0]->xlsx->add_worksheet;
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
    $_[0]->xlsx->close;
}

=head1 NAME

Catmandu::Exporter::XLSX - a XLSX exporter

=head1 SYNOPSIS

    # On the command line
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLSX --file test.xlsx
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLSX --file test.xlsx --header 0
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLSX --file test.xlsx --fields a,c
    $ printf "a,b,c\n1,2,3" | catmandu convert CSV to XLSX --file test.xlsx --fields a,c --columns ALPHA,CHARLIE

    # Or in Perl
    use Catmandu::Exporter::XLSX;

    my $exporter = Catmandu::Exporter::XLSX->new(
                file => 'test.xlsx',
                fields => 'a,b,c',
                columns => 'ALPHA,BRAVO,CHARLIE',
                header => 1);

    $exporter->add({a => 1, b => 2, c => 3});
    $exporter->add_many($arrayref);

    $exporter->commit;

    printf "exported %d objects\n" , $exporter->count;

=head1 DESCRIPTION

L<Catmandu> exporter for Excel XLSX files.

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

=item collect_fields

This option will first read the complete stream to create a complete list
of fields to export. When this option is not set, only the fields of the first
record (or the ones provided in the C<fields> option will be exported).

=back

=head1 SEE ALSO

L<Catmandu::Exporter::CSV>, L<Catmandu::Exporter::XLS>.
=cut

1;
