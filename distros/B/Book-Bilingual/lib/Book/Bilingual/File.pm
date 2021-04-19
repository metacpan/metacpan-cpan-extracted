package Book::Bilingual::File;
# ABSTRACT: Construct a Bilingual book from file
use Mojo::Base -base;
use Book::Bilingual;
use Book::Bilingual::Dline;
use Book::Bilingual::Dlineset;
use Book::Bilingual::Chapter;
use Path::Tiny qw/path/;
use Carp;

has 'book'     => sub { Book::Bilingual->new};  # Book::Bilingual
has 'file';                                     # Path to file
has 'chapters';                                 # Arrayref of chapter text

sub new { ## ($path :Path)
    croak 'Need args ($path)' unless @_ > 1;
    my $self = $_[0]->SUPER::new({ file => path($_[1]) });
    $self->_init();
}

sub _init {
    my ($self) = @_;
    #say ref $self->book;

    my $text = $self->file->slurp_utf8;
    $self->chapters( _extract_chapters($text));

    foreach my $chapter (@{$self->chapters}) {

        # Generate Dlinesets from extracted chapter text
        my @Dsets = map {
            Book::Bilingual::Dlineset->new->set(_extract_dlines($_));
        } @{_extract_dlineset($chapter)};

        my $book_chapter = Book::Bilingual::Chapter->new;
        $book_chapter->number(shift @Dsets);
        $book_chapter->title(shift @Dsets);
        $book_chapter->body([@Dsets]);
        $self->book->push($book_chapter);
    };

    return $self;
}
sub _extract_chapters { ## ($file_text) :> [$chapter_text]
    my ($text) = @_;

    my @chapters = split /^----$/m, $text;
    shift @chapters if scalar @chapters;    # Ignore TOC and other front matter

    return [@chapters];
}
=head2 _extract_dlineset

Returns arrayref of DSET_TEXT.

Sample of DSET_TEXT:

    Chapter One
        #chapter-number         <-- class definition

        บทที่หนึ่ง /
        บทที่ /One
         /Chapter One
    ..                          <-- last line


=cut
sub _extract_dlineset { ## ($chapter_text) :> [DSET_TEXT]
    my ($chapter) = @_;

    my @dsets = grep {
        $_ !~ /^#/                      # Ignore comments
        } split /^__ /m, $chapter;

    shift @dsets if scalar @dsets;      # Ignore chapter front matter

    return [@dsets];
}
=head2 _extract_dlines

A set with class definition

    Chapter One
        #chapter-number         <-- class definition

        บทที่หนึ่ง /
        บทที่ /One
         /Chapter One
    ..                          <-- last line

A set without the class definition

    "Can we go to Polseath as usual?"

        "เราไปชายหาดตามปกติได้ไหม" /
         /"Can /เราไปชายหาดตามปกติ?"
         /"Can /เราไป /beach as usual?"
         /"Can /เรา /go to the beach as usual?"
         /"Can we go to the beach as usual?"
    ..                          <-- last line

=cut
sub _extract_dlines {   ## ($dset_text) :> [Dline]
    my ($dset) = @_;
    my @lines = split "\n", $dset;

    shift @lines;                               # Ignore first line
    my $class = _extract_class(shift @lines);   # Extract dline class
    pop @lines;                                 # Ignore last line

    @lines = grep {
        $_ !~ /^\s*$/;                          # Ignore empty lines
    } @lines;

    @lines = map {
        $_ =~ s/^    //;                        # Trim prefix
        Book::Bilingual::Dline->new({ class=>$class, str=>$_ });
    } @lines;

    return [@lines];
}
sub _extract_class {
    my ($line) = @_;

    $line =~ s/^\s+|\s+$//g;                # Trim front and back
    return '' unless $line;

    $line =~ s/#//g;                        # Remove # markers
    return join ' ',(split /\s+/, $line);   # Split and recombine words
}

1;
