package App::CSV2LaTeXTable;

# ABSTRACT: Generate LaTeX table from CSV file

use v5.24;

use Carp;
use File::Basename;
use LaTeX::Table;
use Moo;
use Text::CSV_XS;

our $VERSION = '1.1.0'; # VERSION

use experimental 'signatures';

has csv         => ( is => 'ro', required => 1 );
has csv_param   => ( is => 'ro', default => sub { [] } );
has latex       => ( is => 'ro', required => 1 );
has latex_param => ( is => 'ro', default => sub { [] } );
has rotate      => ( is => 'ro', default => sub { 0 } );
has split       => ( is => 'ro', default => sub { 0 } );

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

    my $table_sets = $data;

    if ( $self->split ) {
        $table_sets = [];

        my $per_set  = $self->split;
        my $index    = 0;
        my @all_data = $data->@*;

        my $counter = 1;
        while ( my $row = shift @all_data ) {
            push $table_sets->[$index]->@*, $row;

            if ( $counter++ == $per_set ) {
                $index++;
                $counter = 1;
            }
        }
    }

    my $counter;
    while ( my $table_set = shift $table_sets->@* ) {
        my %latex_params = map { split /=/, $_, 2 } $self->latex_param->@*;

        my $suffix = '';
        if ( $self->split ) {
            $suffix = sprintf "-%s", ++$counter;
        }

        if ( $table_sets->@* ) {
            delete $latex_params{caption};
        }

        if ( !defined $latex_params{label} ) {
            my $basename = basename $self->csv, '.csv';
            $latex_params{label} = 'table:' . $basename . $suffix;
        }

        my $table = LaTeX::Table->new({
            %latex_params,
            header   => $header,
            data     => $data,
        });

        my $latex_string = $table->generate_string;

        if ( $self->rotate ) {
            my $rotatebox = sprintf 'rotatebox{%s}{', $self->rotate;
            $latex_string =~ s{begin\{table\}}{$rotatebox};
            $latex_string =~ s{\\end\{table\}$}{\}};
        }

        my $latex_file = $self->latex =~ s{(\.[^\.]+)}{$suffix$1}r;

        open my $tex_fh, '>', $latex_file or croak $!;
        print $tex_fh $latex_string;
        close $tex_fh or croak $!;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSV2LaTeXTable - Generate LaTeX table from CSV file

=head1 VERSION

version 1.1.0

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

=item * rotate

=item * split

=back

=head1 METHODS

=head2 run

    my $obj = App::CSV2LaTeXTable->new(
        csv   => 'A-csv-file.csv',
        latex => 'Target_file.tex',
    );

    $obj->run;

=head1 SEE ALSO

=over 4

=item * L<LaTeX::Table>

Used to generate the LaTeX code.

=item * L<Text::CSV_XS>

Used to parse the CSV file

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
