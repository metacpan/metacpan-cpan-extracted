package Catmandu::Stat;

=head1 NAME

Catmandu::Stat - Catmandu modules for working with statistical data

=cut

our $VERSION = '0.13';

=head1 SYNOPSIS

    # Calculate statistics on the availabity of the ISBN fields in the dataset
    cat data.json | catmandu convert JSON to Stat --fields isbn

    # Preprocess data and calculate statistics
    catmandu convert MARC to Stat --fix 'marc_map(020a,isbn)' --fields isbn < data.mrc

    # Or in fix files

    # Calculate the mean of foo. E.g. foo => [1,2,3,4]
    stat_mean(foo)  # foo => '2.5'

    # Calculate the median of foo. E.g. foo => [1,2,3,4]
    stat_median(foo)  # foo => '2.5'

    # Calculate the standard deviation of foo. E.g. foo => [1,2,3,4]
    stat_stddev(foo)  # foo => '1.12'

    # Calculate the variance of foo. E.g. foo => [1,2,3,4]
    stat_variance(foo)  # foo => '1.25'

=head1 MODULES

=over

=item * L<Catmandu::Exporter::Stat>

=item * L<Catmandu::Fix::stat_mean>

=item * L<Catmandu::Fix::stat_median>

=item * L<Catmandu::Fix::stat_stddev>

=item * L<Catmandu::Fix::stat_variance>

=back

=head1 EXAMPLES

The Catmandu::Stat distribution includes a CSV file on the Sacramento crime rate in January 2006,
"t/SacramentocrimeJanuary2006.csv" also available at
http://samplecsvs.s3.amazonaws.com/SacramentocrimeJanuary2006.csv

To view statistics on the fields available in this file type:

    $ catmandu convert CSV to Stat < t/SacramentocrimeJanuary2006.csv

    | name          | count | zeros | zeros% | min | max | mean | variance | stdev | uniq~ | uniq% | entropy   |
    |---------------|-------|-------|--------|-----|-----|------|----------|-------|-------|-------|-----------|
    | #             | 7584  |       |        |     |     |      |          |       |       |       |           |
    | address       | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 5425  | 71.5  | 12.4/12.4 |
    | beat          | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 20    | 0.3   | 4.3/12.9  |
    | cdatetime     | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 5071  | 66.9  | 12.3/12.3 |
    | crimedescr    | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 305   | 4.0   | 5.6/12.6  |
    | district      | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 6     | 0.1   | 2.6/12.9  |
    | grid          | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 537   | 7.1   | 7.8/9.9   |
    | latitude      | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 5288  | 69.7  | 12.4/12.4 |
    | longitude     | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 5295  | 69.8  | 12.4/12.4 |
    | ucr_ncic_code | 7584  | 0     | 0.0    | 1   | 1   | 1    | 0.0      | 0.0   | 88    | 1.2   | 4.1/12.9  |

The file has 7584 rows where and all the fields C<address> to C<ucr_ncic_code> contain values.
Each field has only one value (no arrays available in the CSV file). The are 5492 unique
addresses in the CSV file. The C<district> field has the lowest entropy, most of its values are
shared among many rows.


=head1 SEE ALSO

L<Catmandu>,
L<Catmandu::Breaker>,

=head1 AUTHOR

Patrick Hochstenbach, C<< <patrick.hochstenbach at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
