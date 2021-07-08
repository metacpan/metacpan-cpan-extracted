package Book::Collate::Writer::Report;

use 5.006;
use strict;
use warnings;

=head1 NAME

Book::Collate::Writer::Report

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = 'v0.0.1';


=head1 SYNOPSIS

Given a file name, a report directory name, and a data object that includes report data,
writes the report.


=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 write_report_book

Takes a book object, iterates through the sections, and writes the reports.

=cut

sub write_report_book {
  my ($self, $book)  = @_;
  # This assumes it is given a book object, which has section objects.
  foreach my $section ( @{$book->sections()} ){
    my $report_file = $book->report_dir . "/report_" . $section->filename();
    open( my $file, '>', $report_file ) or die "Can't open $report_file: $!";
    print $file write_report_section($section);
    close($file);
  }
  return;
}

=head2 write_report_section

Takes a section object and returns the stringified report.

=cut

sub write_report_section {
  my $self    = shift;
  my $string  = "Grade Level:             " . $self->grade_level() . "\n";
  $string     .= "Average Word Length:     " . $self->avg_word_length() . "\n";
  $string     .= "Average Sentence Length  " . $self->avg_sentence_length() . "\n";
  $string     .= "Word Frequency List:\n";
  my %word_list = $self->{_report}->sorted_word_list();
  my @unsorted_keys = ( keys %word_list );
  my @sorted_keys = reverse ( sort { $a <=> $b } @unsorted_keys );
  my $max_keys = 25;
  foreach my $count ( @sorted_keys ){
    $string .= "  $count  ";
    foreach my $word ( @{$word_list{$count}} ){
      $string .= " $word";
    }
    $string .= "\n";
    $max_keys -= 1;
    last unless $max_keys;
  }
  return $string;
}

=head1 AUTHOR

Leam Hall, C<< <leamhall at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-. at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=.>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Book::Collate::Writer::Report


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=.>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/.>

=item * Search CPAN

L<https://metacpan.org/release/.>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Leam Hall.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Book::Collate::Writer::Report
