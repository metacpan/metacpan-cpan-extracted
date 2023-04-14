package Book::Collate::Writer::Report;

use 5.006;
use strict;
use warnings;

use Book::Collate;

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

=head2 _generate_fry_stats

Gives a percentage of Fry list words used against the total unique words used.

=cut

sub _generate_fry_stats {
  my ( $word_list, $custom_word_list ) = @_;
  my %word_list = %{$word_list};
  my %custom_word_list = %{$custom_word_list};
  my %fry_words = %Book::Collate::Words::fry;
  my %used_words;
  my %missed;
  my %fry_used = (
    fry     => 0,
    custom  => 0,
    miss    => 0,
  );
  foreach my $word ( keys %word_list ){
    $word = Book::Collate::Utils::scrub_word($word);
    $used_words{$word} = 1;
  }

  foreach my $word ( keys %used_words ){
    if ( defined($fry_words{$word}) ){
      $fry_used{fry}++;
    } elsif ( defined($custom_word_list{$word}) ){
      $fry_used{custom}++;
    } else {
      $fry_used{miss}++;
      $missed{$word} = 1;
    }
  }
  return %fry_used;
}


=head2 write_fry_stats

Produces a string based on Fry word usage.

=cut

sub write_fry_stats {
  my ( $word_list, $custom_word_list ) = @_;
  my %fry_used  = _generate_fry_stats( $word_list, $custom_word_list );
  my $string    = "Fry Stats:\n";
  $string       .= "  Used   " . $fry_used{fry}     . "\n";
  $string       .= "  Custom " . $fry_used{custom}  . "\n";
  $string       .= "  Miss   " . $fry_used{miss}    . "\n";
  return $string;
}

=head2 write_weak_word_count

Produces a string of weak word usage.

=cut

sub write_weak_word_count {
  my ( $weak_word_used_ref ) = @_;
  my %weak_used = %{$weak_word_used_ref};
  my $string = "Weak Words:\n";
  
  foreach my $word ( sort( keys(%weak_used) ) ){
    #$string .= "\t$word   $weak_used{$word}\n";
    $string .= sprintf("%3d   %s\n", $weak_used{$word}, $word); 
  } 
  return $string;
}

=head2 accumulate_weak_used

Returns a ref to a hash of cumulative weak words used.

=cut

sub accumulate_weak_used {
  my ($book_weak_used, $section_weak_used) = @_;
  my %book_weak_used      = %{$book_weak_used};
  my %section_weak_used   = %{$section_weak_used};

  foreach my $key ( keys( %section_weak_used ) ){
    $book_weak_used{$key} += $section_weak_used{$key};
  }
  
  return \%book_weak_used;
}


=head2 write_report_book

Takes a book object, iterates through the sections, and writes the reports.

=cut

sub write_report_book {
  # Test if given a book object.
  my ($self, $book)  = @_;
  my %word_list;
  my %custom_word_list = ();
  if ( defined($book->custom_word_file() ) ){
    %custom_word_list = Book::Collate::Utils::build_hash_from_file($book->custom_word_file());
  }
  my %weak_word_list = ();
  if ( defined($book->weak_word_file() ) ){
    %weak_word_list = Book::Collate::Utils::build_hash_from_file($book->weak_word_file());
  }
  my %book_weak_used;

  my %section_data_strings;
  # This assumes it is given a book object, which has section objects.
  foreach my $section ( @{$book->sections()} ){
    %word_list = ( %word_list, $section->word_list() );
    my ($section_string, $section_weak_word_used) = write_report_section(
      $section->headless_data(), 
      \%custom_word_list,
      \%weak_word_list,
    );
    $section_data_strings{$section->filename()} = $section_string ; 

    %book_weak_used = %{accumulate_weak_used(\%book_weak_used, $section_weak_word_used)};

    ### Keep this idea if we write individual section reports.
    #my $section_report_file = $book->report_dir . "/report_" . $section->filename();
    #open( my $section_file, '>', $section_report_file ) 
      #or die "Can't open $section_report_file: $!";
    #print $section_file write_report_section($section->headless_data(), \%custom_word_list);
    #close($section_file);
    ###

  }
  my $book_report_filename = $book->title_as_filename . "_report.txt";
  my $book_report_file = $book->report_dir . "/" . $book_report_filename;
  open( my $book_file, '>', $book_report_file ) or die "Can't open $book_report_file: $!";
  print $book_file "Report for:   " . $book->title . "\n\n";
  print $book_file  write_fry_stats(\%word_list, \%custom_word_list);
  print $book_file "\n";
  print $book_file write_weak_word_count(\%book_weak_used);
  print $book_file "\n";

  foreach my $title ( sort( keys(%section_data_strings) ) ){
    print $book_file "\n\n #### \n\n$title \n\n$section_data_strings{$title}";
  }
  close $book_file;
  return;
}

=head2 write_report_section

Takes a section object and returns the stringified report.

=cut

sub write_report_section {
  my ( $data, $custom_word_list, $weak_word_list ) = @_;
  my %custom_word_list    = %$custom_word_list;
  my %weak_words          = %$weak_word_list;
  my $report              = Book::Collate::Report->new( 
    string                => $data, 
    custom_word_file      => 'data/custom_words.txt',
    weak_words            => \%weak_words,
    );
  my $weak_word_used_ref  = $report->weak_used();

  my $grade_level         = sprintf("%.2f", $report->grade_level());  
  my $avg_word_length     = sprintf("%.2f", $report->avg_word_length());
  my $avg_sentence_length = sprintf("%.2f", $report->avg_sentence_length());

  my $string;
  $string     .= "Grade Level:             $grade_level \n";
  $string     .= "Average Word Length:     $avg_word_length \n";
  $string     .= "Average Sentence Length  $avg_sentence_length \n";

  my %word_list = $report->word_list();
  $string     .= write_fry_stats(\%word_list, \%custom_word_list);

  my @words     = $report->words();
  $string       .= write_weak_word_count($weak_word_used_ref);
  
  $string       .= "Word Frequency List:\n";
  my %sorted_word_list = $report->sorted_word_list();
  my @unsorted_keys = ( keys %sorted_word_list );
  my @sorted_keys = reverse ( sort { $a <=> $b } @unsorted_keys );
  my $max_keys = 25;
  foreach my $count ( @sorted_keys ){
    $string .= "  $count  ";
    foreach my $word ( @{$sorted_word_list{$count}} ){
      $string .= " $word";
    }
    $string .= "\n";
    $max_keys -= 1;
    last unless $max_keys;
  }
  return ($string, $weak_word_used_ref);
}



=head1 AUTHOR

Leam Hall, C<< <leamhall at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/LeamHall/book_collate/issues>.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Book::Collate::Writer::Report


You can also look for information at:

=over 4

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
