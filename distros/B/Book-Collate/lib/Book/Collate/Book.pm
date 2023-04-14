package Book::Collate::Book;

use 5.006;
use strict;
use warnings;

=head1 NAME

Book

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = 'v0.0.2';


=head1 SYNOPSIS

Book object


    use Book;

    my $book    = Book->new(
      title     => 'Al rescues the universe again',
      author    => 'Leam Hall',
    );


=head1 SUBROUTINES/METHODS

=head2 new

Initializes with a data hash consisiting of title and author.
  
=cut

sub new {
  my ( $class, %data ) = @_;
  bless {
    _author           => $data{author},
    _blurb_file       => $data{blurb_file},
    _book_dir         => $data{book_dir},
    _file_name        => $data{file_name},
    _image            => $data{image},
    _output_dir       => $data{output_dir},
    _report_dir       => $data{report_dir},
    _sections         => [],  
    _title            => $data{title},
    _url              => $data{url},
    _words            => {},
    _custom_word_file => $data{custom_word_file},
    _weak_word_file   => $data{weak_word_file},
  }, $class;
}

=head2 add_words

Adds words from each section to the $self->_words hash.

=cut

sub add_words {
  my ( $self, $word_list ) = @_;
  my @word_list = @$word_list;
  foreach my $word ( @word_list ) {
    $self->{_words}{$word} = 1;
  } 
  return;
}

=head2 add_section

Appends a section object to the internal list of sections.

=cut

sub add_section {
  my ($self, $section) = @_;
  push(@{$self->sections}, $section);
};


=head2 author

Returns the author.

=cut

sub author    { $_[0]->{_author}    };

=head2 blurb

Returns the blurb.

=cut

sub blurb {
  my $self = shift;
  my $file;
  {
    local $/;
    open my $fh, '<', $self->{_blurb_file} or die "Can't open blurb file: $!";
    $file = <$fh>;
    chomp($file);
  }
  return $file;
}

=head2 book_dir

Returns the directory for the book project.

=cut

sub book_dir { $_[0]->{_book_dir} };


=head2 custom_word_file

Returns the file with custom words.

=cut

sub custom_word_file { $_[0]->{_custom_word_file} };


=head2 weak_word_file 

Returns the file of weak words.

=cut

sub weak_word_file { $_[0]->{_weak_word_file} };

=head2 file_name

Returns the file portion of the file_name.

=cut

sub file_name { $_[0]->{_file_name} };

=head2 image

Returns the localized path to the image.

=cut

sub image { $_[0]->{_image} };


=head2 output_dir

Returns the directory where the files are written.

=cut

sub output_dir { $_[0]->{_output_dir} };

=head2 report_dir

Returns the directory where reports are written.

=cut

sub report_dir { $_[0]->{_report_dir} };

=head2 sections

Returns the array of section objects.

=cut

sub sections  { $_[0]->{_sections}  };

=head2 title

Returns the title.

=cut

sub title     { $_[0]->{_title}     };

=head2 title_as_filename

Returns the book title as a lowercase string, with underscores replacing spaces and punctuation.

=cut

sub title_as_filename {
  my $self = shift;
  my $title_string;
  my $title_orig = $self->title;
  my $last_char = '_';
  foreach my $char ( split( //, $title_orig ) ){
    if ( $char =~ m/[A-Za-z]/ ){
      $last_char = lc($char);
      $title_string .= $last_char;
    } elsif ( $last_char eq '_' ){
      next;
    } else {
      $last_char = '_';
      $title_string .= $last_char;
    }
  }
  return $title_string;
};

=head2 url

Return the URL of the book.

=cut

sub url       { $_[0]->{_url}       };


=head2 write_report

Writes the report files.

=cut

sub write_report {
  my $self  = shift;
  my $num   = 1; 
  foreach my $section ( @{$self->sections} ){
    my $report_file = $self->report_dir . "/report_${num}.txt";
    open( my $file, '>', $report_file ) or die "Can't open $report_file: $!";
    print $file $section->write_report;
    close($file);
    $num += 1;
  }

}

=head2 write_text

Writes the text version of the file.

=cut

sub write_text {
  my ($self)      = @_; 
  my $title = $self->title;
  my $text_file   = $self->output_dir . '/' . $self->file_name . '.txt';
  my $section_break   = "\n__section_break__\n";

  open( my $file, '>', $text_file) or die "Can't open $text_file: $!";
  select $file;
 
  foreach my $section ( @{$self->sections} ) { 
    print $section_break;
    printf "Chapter %03d", $section->number();
    print "\n\n";
    print $section->header(), "\n\n";
    print $section->headless_data(), "\n\n";
  }
  close($file);
}

=head1 AUTHOR

Leam Hall, C<< <leamhall at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/LeamHall/book_collate/issues>.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc lib/Book/Collate/Book.pm


You can also look for information at:

=over 4

=item * GitHub Project Page

L<https://github.com/LeamHall/book_collate>

=back


=head1 ACKNOWLEDGEMENTS

Besides Larry Wall, you can blame the folks on IRC Libera#perl for this stuff existing.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2321 by Leam Hall.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Book
