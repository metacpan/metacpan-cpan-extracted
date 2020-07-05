package App::CSV2Chart::API::ToXLSX;
$App::CSV2Chart::API::ToXLSX::VERSION = '0.12.0';
use strict;
use warnings;
use 5.014;

use Excel::Writer::XLSX ();
use Text::CSV           ();

sub _to_xlsx_common_opt_spec
{
    return [
        [ "chart-type=s", "Chart Type" ],
        [ "height=i",     "Chart Height" ],
        [ "output|o=s",   "Output path" ],
        [ "title=s",      "Chart Title" ],
        [ "width=i",      "Chart Width" ],
        [ 'exec|e=s@',    "Execute command on the output" ]
    ];

}

# Based on https://metacpan.org/source/JMCNAMARA/Excel-Writer-XLSX-0.99/examples/chart_scatter.pl by John McNamara - thanks!
#
# Modified by Shlomi Fish ( https://www.shlomifish.org/ ) while putting the
# changes under https://creativecommons.org/choose/zero/ .

#######################################################################
#
# A demo of a Scatter chart in Excel::Writer::XLSX. Other subtypes are
# also supported such as markers_only (the default), straight_with_markers,
# straight, smooth_with_markers and smooth. See the main documentation for
# more details.
#
# reverse ('(c)'), March 2011, John McNamara, jmcnamara@cpan.org
#
sub csv_to_xlsx
{
    my $args       = shift;
    my $fh         = $args->{input_fh};
    my $fn         = $args->{output_fn};
    my $title      = $args->{title};
    my $height     = $args->{height};
    my $width      = $args->{width};
    my $chart_type = ( $args->{chart_type} // 'scatter' );

    my $csv       = Text::CSV->new;
    my $workbook  = Excel::Writer::XLSX->new($fn);
    my $headings  = $csv->getline($fh);
    my $worksheet = $workbook->add_worksheet();
    my $bold      = $workbook->add_format( bold => 1 );

    # Add the worksheet data that the charts will refer to.
    my $data = [ map { [] } @$headings ];
    while ( my $row = $csv->getline($fh) )
    {
        while ( my ( $i, $v ) = each @$row )
        {
            push @{ $data->[$i] }, $v;
        }
    }

    $worksheet->write( 'A1', $headings, $bold );
    $worksheet->write( 'A2', $data );

    my $w = @$headings;
    my $h = @{ $data->[0] };

    # Create a new chart object. In this case an embedded chart.
    my $chart1 = $workbook->add_chart( type => $chart_type, embedded => 1 );

    my @size = (
        ( defined($height) ? ( height => $height ) : () ),
        ( defined($width)  ? ( width  => $width )  : () ),
    );

    foreach my $series_idx ( 0 .. $#$data - 1 )
    {
        # Configure second series. Note alternative use of array ref to define
        # ranges: [ $sheetname, $row_start, $row_end, $col_start, $col_end ].
        $chart1->add_series(
            name       => '=Sheet1!$' . chr( ord('B') + $series_idx ) . '$1',
            categories => [ 'Sheet1', 1, 1 + $h, 0, 0 ],
            values => [ 'Sheet1', 1, 1 + $h, 1 + $series_idx, 1 + $series_idx ],
        );
    }

    # Add a chart title and some axis labels.
    $chart1->set_title( name => ( $title // 'Results of sample analysis' ) );
    $chart1->set_x_axis( name => $headings->[0] );
    $chart1->set_y_axis( name => $headings->[1] );

    # Set an Excel chart style. Blue colors with white outline and shadow.
    $chart1->set_style(11);

    if (@size)
    {
        $chart1->set_size(@size);
    }

    # Insert the chart into the worksheet (with an offset).
    $worksheet->insert_chart( 'D2', $chart1, 25, 10 );

    if (0)
    {
        #
        # Create a scatter chart sub-type with straight lines and markers.
        #
        my $chart2 = $workbook->add_chart(
            type     => 'scatter',
            embedded => 1,
            subtype  => 'straight_with_markers'
        );

        # Configure the first series.
        $chart2->add_series(
            name       => '=Sheet1!$B$1',
            categories => '=Sheet1!$A$2:$A$7',
            values     => '=Sheet1!$B$2:$B$7',
        );

        # Configure second series.
        $chart2->add_series(
            name       => '=Sheet1!$C$1',
            categories => [ 'Sheet1', 1, 6, 0, 0 ],
            values     => [ 'Sheet1', 1, 6, 2, 2 ],
        );

        # Add a chart title and some axis labels.
        $chart2->set_title( name => 'Straight line with markers' );
        $chart2->set_x_axis( name => 'Test number' );
        $chart2->set_y_axis( name => 'Sample length (mm)' );

        # Set an Excel chart style. Blue colors with white outline and shadow.
        $chart2->set_style(12);

        # Insert the chart into the worksheet (with an offset).
        $worksheet->insert_chart( 'D18', $chart2, 25, 11 );

        #
        # Create a scatter chart sub-type with straight lines and no markers.
        #
        my $chart3 = $workbook->add_chart(
            type     => 'scatter',
            embedded => 1,
            subtype  => 'straight'
        );

        # Configure the first series.
        $chart3->add_series(
            name       => '=Sheet1!$B$1',
            categories => '=Sheet1!$A$2:$A$7',
            values     => '=Sheet1!$B$2:$B$7',
        );

        # Configure second series.
        $chart3->add_series(
            name       => '=Sheet1!$C$1',
            categories => [ 'Sheet1', 1, 6, 0, 0 ],
            values     => [ 'Sheet1', 1, 6, 2, 2 ],
        );

        # Add a chart title and some axis labels.
        $chart3->set_title( name => 'Straight line' );
        $chart3->set_x_axis( name => 'Test number' );
        $chart3->set_y_axis( name => 'Sample length (mm)' );

        # Set an Excel chart style. Blue colors with white outline and shadow.
        $chart3->set_style(13);

        # Insert the chart into the worksheet (with an offset).
        $worksheet->insert_chart( 'D34', $chart3, 25, 11 );

        #
        # Create a scatter chart sub-type with smooth lines and markers.
        #
        my $chart4 = $workbook->add_chart(
            type     => 'scatter',
            embedded => 1,
            subtype  => 'smooth_with_markers'
        );

        # Configure the first series.
        $chart4->add_series(
            name       => '=Sheet1!$B$1',
            categories => '=Sheet1!$A$2:$A$7',
            values     => '=Sheet1!$B$2:$B$7',
        );

        # Configure second series.
        $chart4->add_series(
            name       => '=Sheet1!$C$1',
            categories => [ 'Sheet1', 1, 6, 0, 0 ],
            values     => [ 'Sheet1', 1, 6, 2, 2 ],
        );

        # Add a chart title and some axis labels.
        $chart4->set_title( name => 'Smooth line with markers' );
        $chart4->set_x_axis( name => 'Test number' );
        $chart4->set_y_axis( name => 'Sample length (mm)' );

        # Set an Excel chart style. Blue colors with white outline and shadow.
        $chart4->set_style(14);

        # Insert the chart into the worksheet (with an offset).
        $worksheet->insert_chart( 'D51', $chart4, 25, 11 );

        #
        # Create a scatter chart sub-type with smooth lines and no markers.
        #
        my $chart5 = $workbook->add_chart(
            type     => 'scatter',
            embedded => 1,
            subtype  => 'smooth'
        );

        # Configure the first series.
        $chart5->add_series(
            name       => '=Sheet1!$B$1',
            categories => '=Sheet1!$A$2:$A$7',
            values     => '=Sheet1!$B$2:$B$7',
        );

        # Configure second series.
        $chart5->add_series(
            name       => '=Sheet1!$C$1',
            categories => [ 'Sheet1', 1, 6, 0, 0 ],
            values     => [ 'Sheet1', 1, 6, 2, 2 ],
        );

        # Add a chart title and some axis labels.
        $chart5->set_title( name => 'Smooth line' );
        $chart5->set_x_axis( name => 'Test number' );
        $chart5->set_y_axis( name => 'Sample length (mm)' );

        # Set an Excel chart style. Blue colors with white outline and shadow.
        $chart5->set_style(15);

        # Insert the chart into the worksheet (with an offset).
        $worksheet->insert_chart( 'D66', $chart5, 25, 11 );

    }

    $workbook->close();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CSV2Chart::API::ToXLSX - convert CSV to xlsx internal API

=head1 VERSION

version 0.12.0

=head1 FUNCTIONS

=head2 csv_to_xlsx({input_fh => $fh, output_fn => "/path/to/out.xlsx", title => "My results",});

Concert CSV data to an .xlsx file with the data and an embedded chart.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/App-CSV2Chart>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-CSV2Chart>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/App-CSV2Chart>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/A/App-CSV2Chart>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=App-CSV2Chart>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=App::CSV2Chart>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-app-csv2chart at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=App-CSV2Chart>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/CSV2Chart>

  git clone https://github.com/shlomif/CSV2Chart.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/app-csv2chart/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
