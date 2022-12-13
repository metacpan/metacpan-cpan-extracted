package App::CSV2LaTeXTable;

# ABSTRACT: Generate LaTeX table from CSV file

use v5.24;

use Carp;
use File::Basename;
use LaTeX::Table;
use Moo;
use Text::CSV_XS;

our $VERSION = '1.0.0'; # VERSION

use experimental 'signatures';

has csv         => ( is => 'ro', required => 1 );
has csv_param   => ( is => 'ro', default => sub { [] } );
has latex       => ( is => 'ro', required => 1 );
has latex_param => ( is => 'ro', default => sub { [] } );

sub run ($self) {
    my %csv_params = map { split /=/, $_, 2 } $self->csv_param->@*;
    $csv_params{binary} = 1;

    my $csv = Text::CSV_XS->new(\%csv_params);

    if ( !-f $self->csv ) {
        croak sprintf "File %s does not exist", $self->csv;
    }

    my ($header, $data);

    open my $fh, '<:encoding(utf-8)', $self->csv or croak $!;
    while ( my $row = $csv->getline( $fh ) ) {
        if ( $. == 1 ) {
            push $header->@*, $row;
            next;
        }

        push $data->@*, $row;
    }
    close $fh or croak $!;

    my %latex_params = map { split /=/, $_, 2 } $self->latex_param->@*;

    if ( !defined $latex_params{label} ) {
        my $basename = basename $self->csv, '.csv';
        $latex_params{label} = 'table:' . $basename;
    }

    my $table = LaTeX::Table->new({
        %latex_params,
        filename => $self->latex,
        header   => $header,
        data     => $data,
    });

    $table->generate;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSV2LaTeXTable - Generate LaTeX table from CSV file

=head1 VERSION

version 1.0.0

=head1 SYNOPSIS

    use App::CSV2LaTeXTable;

    my $csv   = '/path/to/a_csv_file.csv';
    my $latex = '/path/to/resulting_latex_file.tex';

    my $obj = App::CSV2LaTeXTable->new(
        csv   => $csv,
        latex => $latex,
    );

    $obj->run;

Using this CSV file:

    Name,Age,City
    Mr X,34,London
    Q,43,London
    M,55,London

This module generates this:

    \begin{table}
    \centering
    \begin{tabular}{lrl}
    \toprule
    Name & Age & City \\
    \midrule
    Mr X & 34 & London \\
    Q    & 43 & London \\
    M    & 55 & London \\
    \bottomrule
    \end{tabular}
    \label{table:a_csv_file}
    \end{table}

=head1 DESCRIPTION

This is the module behind L<csv2latextable>.

=head1 ATTRIBUTES

=over 4

=item * csv

=item * csv_param

=item * latex

=item * latex_param

=back

=head1 METHODS

=head2 run

    my $obj = App::CSV2LaTeXTable->new(
        csv   => 'A-csv-file.csv',
        latex => 'Target_file.tex',
    );

    $obj->run;

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
