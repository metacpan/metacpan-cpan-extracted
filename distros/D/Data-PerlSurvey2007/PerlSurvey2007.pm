package Data::PerlSurvey2007;

use warnings;
use strict;

=head1 NAME

Data::PerlSurvey2007 - Data results and simple code for the results of Perl Survey 2007

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

our @columns;

=head1 SYNOPSIS

Now you can do your own analyses of the data from Perl Survey 2007.

    use Data::PerlSurvey2007;

    my @responses = Data::PerlSurvey2007::read_responses( 'results.csv' );

Each element of the responses coming back is a hashref that looks like this

    {
      'Attended Perl Mongers' => '1',
      'Attended Perl Mongers (non-local)' => '0',
      'Attended conference' => '1',
      'Attended conference (non-local)' => '0',
      'CPAN modules maintained' => '12',
      'Contributed to CPAN' => '1',
      'Contributed to Perl 5' => '0',
      'Contributed to Perl 6' => '0',
      'Contributed to other projects' => '1',
      'Contributed to websites' => '1',
      'Country of birth' => 'au',
      'Country of residence' => 'au',
      'Date survey completed' => '2007-07-26 12:49:37',
      'ID' => '25',
      'Income' => '80000-89999',
      'Industry/ies' => [
                          'Internet',
                          'Real Estate'
                        ],
      'Led other projects' => '1',
      'Other programming languages known' => [],
      'Perl versions' => [
                           '5.005',
                           '5.6.1',
                           '5.8.4',
                           '5.8.5',
                           '5.8.8'
                         ],
      'Perlmonks' => '0',
      'Platforms' => [
                       'BSD - FreeBSD',
                       'Linux - Debian',
                       'Linux - Ubuntu',
                       'Mac OS/X',
                       'Windows XP'
                     ],
      'Posted to Perl Mongers list' => '1',
      'Posted to other list' => '1',
      'Presented at conference' => '1',
      'Primary language spoken' => 'English',
      'Programming languages known' => [
                                         'JavaScript',
                                         'MOO',
                                         'PHP',
                                         'Ruby'
                                       ],
      'Proportion of Perl' => '90',
      'Provided feedback' => '1',
      'Sex' => 'female',
      'Subscribed to Perl Mongers list' => '1',
      'Subscribed to other list' => '1',
      'Year of birth' => '1975',
      'Years programming (total)' => '22',
      'Years programming Perl' => '11'
    },

=head1 FUNCTIONS

=head2 read_responses( $filename )

Reads in the responses from F<$filename> and returns an array of them.

=cut

sub read_responses {
    my $filename = shift;

    my @responses = ();

    open( my $fh, '<', $filename ) or die "Unable to read $filename: $!\n";
    while ( <$fh> ) {
        chomp;
        next if /^#/ || !/./;

        my @fields = split_csv( $_ );
        my $nfields = @fields;
        $nfields == 34 or die "I need 34 fields, but line $. has $nfields";
        if ( @columns ) {
            my %response;

            # Turn the multi-value responses into arrayrefs
            for my $col ( 7, 10, 11, 13, 14 ) {
                $fields[$col] = [ split( /\s*;\s*/, $fields[$col] ) ];
            }
            @response{ @columns } = @fields;
            push( @responses, \%response );
        }
        else {
            @columns = @fields;
        }
    }
    return @responses;
}


=head2 split_csv( $str )

Split the CSV fields into individual columns, and get rid of the quotes.

=cut

sub split_csv {
    my $str = shift;

    my @cols = ( $str =~ /(?:^|,)("(?:[^"]+|"")*"|[^,]*)/g );

    s/^"(.*)"$/$1/ for @cols;

    return @cols;
}

=head1 AUTHOR

Andy Lester, C<< <andy at petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-perlsurvey2007 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-PerlSurvey2007>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::PerlSurvey2007

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-PerlSurvey2007>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-PerlSurvey2007>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-PerlSurvey2007>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-PerlSurvey2007>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Andy Lester, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::PerlSurvey2007
