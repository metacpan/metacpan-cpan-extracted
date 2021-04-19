package Book::Bilingual::Reader;
# ABSTRACT: A book reader class
use Mojo::Base -base;
use Mojo::JSON qw(decode_json encode_json);
use Book::Bilingual;
use Book::Bilingual::File;
use Path::Tiny qw/path/;
use Carp;

has 'book' => sub { Book::Bilingual->new};  # Book::Bilingual
has 'file';                                 # Book File
has '_ptr';                                 # Current pointer
has '_chapter_dlines';                      # Href { loc => Dline } in chapter
has '_curr_dlineset';                       # Href { loc => Dline } of current dlineset

sub new { ## ($path :Path)
    croak 'Need args ($path)' unless @_ > 1;
    my $self = $_[0]->SUPER::new({ file => path($_[1]) });

    # Initialize pointer
    $self->_ptr([0,0,0]);

    # Setup book
    $self->book(Book::Bilingual::File->new($_[1])->book);

    # Load current chapter
    $self->_load_chapter();

    # Load current Dlineset
    $self->_load_dlineset();

    return $self;
}
sub _load_chapter { ## () :> Self
    my ($self) = @_;

    # Fetch chapter being pointed to
    my $ch_idx = $self->_ptr->[0];
    my $chapter = $self->book->chapters->[$ch_idx];

    # Empty the target hashref
    $self->{_chapter_dlines} = {};

    # Iterate over all Dlinesets in chapter
    my $dset_idx = 0;
    foreach my $dset ($chapter->number, $chapter->title, @{$chapter->body}) {
        # Store the default/target dline into _chapter_dlines
        my $dline_idx = $dset->dline_count - 1;
        # say "$ch_idx.$dset_idx.$dline_idx: ". $dset->target->str;
        $self->{_chapter_dlines}{"$ch_idx.$dset_idx.$dline_idx"} = $dset->target;

        $dset_idx++;
    }

    return $self;
}
sub _load_dlineset { ## () :> Self
    my ($self) = @_;

    # Fetch dlineset being pointed to
    my $ch_idx = $self->_ptr->[0];
    my $chapter = $self->book->chapters->[$ch_idx];

    # Empty the target hashref
    $self->{_curr_dlineset} = {};

    # Iterate over all Dlinesets in chapter
    my $dset_idx = $self->_ptr->[1];
    my $dset;
    $dset = $chapter->number if $dset_idx eq 0;
    $dset = $chapter->title if $dset_idx eq 1;
    $dset = $chapter->body->[$dset_idx-2] if $dset_idx > 1;

    my $dline_idx = 0;
    foreach my $dline (@{$dset->set}) {
        # say "$ch_idx.$dset_idx.$dline_idx: ". $dline->str;
        $self->{_curr_dlineset}{"$ch_idx.$dset_idx.$dline_idx"} = $dline;
        $dline_idx++;
    }

    return $self;
}

sub html { ## () :> HTML
    my ($self) = @_;

    my $ch_idx = $self->_ptr->[0];
    my $dset_idx = $self->_ptr->[1];

    # Regex that matches other locations in the same dlineset
    #   e.g. '0.1.2' will match qr/^0\.1\.\d+$/
    my $curr_dlineset_re = qr/^$ch_idx\.$dset_idx\.\d+$/; 

    # Use the chapter Dline, except if the Dline is in the same Dlineset
    # as the pointer, use the pointed to Dline
    my @html = map {
        my $loc = $_;
        my $pointed = $loc =~ $curr_dlineset_re ? 1 : 0;
        my $dline = $pointed
                  ? $self->_curr_dlineset->{join('.',@{$self->_ptr})}
                  : $self->_chapter_dlines->{$loc};

        my $ptr = $loc;
        $ptr =~ s/\.(\d+)$/\.0/;

        # Render Dline depending on whether it is pointed to
        $pointed ? _render_pointed($dline->class, $dline->str, $ptr)
                 : _render_normal($dline->class, $dline->str, $ptr);
    } sort keys %{$self->_chapter_dlines};

    # Render to HTML
    my $html = join '', @html;

    # say "\n$html\n";
    return $html;
}
sub _render {
    my ($dline) = @_;

    my $seg_idx = 0;
    my @spans = map {
        my $class = $seg_idx++ % 2 ? 'tgt-lang' : 'src-lang';
        "<span class=\"$class\"> $_</span>";
    } split(' /', $dline->str);

    return '  <div class="'.$dline->class.'">'.join('',@spans).'</div>';
}
sub _render_normal { ## ($class,$str,$ptr)
    my ($class,$str,$ptr) = @_;

    $str =~ s/^ \///;   # Remove language mark
    $str .= ' ';        # Add a space at the end of the line

    return "\n  <h1 data-ptr=\"$ptr\" class=\"".$class.'">'.$str."</h1>\n"
        if $class eq 'chapter-number';

    return "\n  <h2 data-ptr=\"$ptr\" class=\"".$class.'">'.$str."</h2>"
        if $class eq 'chapter-title';

    return "\n\n  <br/><span data-ptr=\"$ptr\" class=\"".$class.'">'.$str.'</span>'
        if $class eq 'paragraph-start';

    return "<span data-ptr=\"$ptr\">$str</span>";
}
sub _render_pointed { ## ($class,$str)
    my ($class,$str,$ptr) = @_;

    my $seg_class = '';
    my @spans = map {
        # Toggles segment class.
        # One of: 'src-lang'|''. Always start as 'src-lang'.
        $seg_class = $seg_class eq '' ? 'src-lang' : '';

        # If segment class is src-lang, return a span else as is
        my $span = $seg_class ? "<span class=\"$seg_class\">$_ </span>" : $_;

        # Return span only if segment is non-empty, else empty string
        $_ ? $span : '';
    } split(' /', $str);

    my $wrapped = "<span id=\"Ptr\" class=\"pointed\">".join('',@spans)."</span>";

    return _render_normal($class,$wrapped,$ptr);
}

sub _next_ptr { ## () :> undef | [Ptr,diff_chapter,diff_dlineset,diff_dline]
    my ($self) = @_;

    my $ptr_0 = $self->_ptr->[0];
    my $ptr_1 = $self->_ptr->[1];
    my $ptr_2 = $self->_ptr->[2];

    my $max_chapter_idx
        = $self->book->chapter_count - 1;
    my $max_chapter_dlineset_idx
        = $self->book->chapter_dlineset_count($ptr_0) - 1;
    my $max_chapter_dlineset_dline_idx
        = $self->book->chapter_dlineset_dline_len($ptr_0, $ptr_1) - 1;

    # Case 1: NOT end of current dlineset
    #   Return pointer to next dline in dlineset
    return [join('.', $ptr_0, $ptr_1, $ptr_2+1), 0, 0, 1]
        if $ptr_2 < $max_chapter_dlineset_dline_idx;

    # Case 2: End of current dlineset, NOT end of dlinesets in chapter
    #   Return pointer to first dline in next dlineset
    return [join('.', $ptr_0, $ptr_1+1, 0), 0, 1, 1]
        if $ptr_1 < $max_chapter_dlineset_idx;

    # Case 3: End of chapter dlineset, NOT end of chapters in book
    #   Return pointer to first dline in next chapter
    return [join('.', $ptr_0+1, 0, 0), 0, 1, 1]
        if $ptr_0 < $max_chapter_idx;

    # Case 4: End of book chapters
    #   Return undef
    return undef;
}
sub _prev_ptr { ## () :> undef | [PtrStr,diff_chapter,diff_dlineset,diff_dline]
    my ($self) = @_;

    my $ptr_0 = $self->_ptr->[0];       # Chapter_idx
    my $ptr_1 = $self->_ptr->[1];       # Dlineset_idx
    my $ptr_2 = $self->_ptr->[2];       # Dline_idx

    my $max_chapter_idx
        = $self->book->chapter_count - 1;

    # Case 1: NOT at first Dline in current Dlineset
    #   Return pointer to prev dline in Dlineset
    return [join('.', $ptr_0, $ptr_1, $ptr_2-1), 0, 0, 1]
        if $ptr_2 > 0;

    # Case 2: At first Dline in current Dlineset, NOT at first Dlineset in Chapter
    #   Return pointer to prev Dlineset in Chapter
    if ($ptr_1 > 0) {
        my $Curr_chapter_Prev_dlineset_Max_dline_idx
            = $self->book->chapter_dlineset_dline_len($ptr_0, $ptr_1-1) - 1;
        return [join('.', $ptr_0,
                          $ptr_1-1,
                          $Curr_chapter_Prev_dlineset_Max_dline_idx), 0, 0, 1]
    }

    # Case 3: At first Dlineset in chapter, NOT at first Chapter
    #   Return pointer to last Dline in last Dlineset in prev Chapter
    if ($ptr_0 > 0) {
        my $Prev_chapter_Max_dlineset_idx
            = $self->book->chapter_dlineset_count($ptr_0-1) - 1;
        my $Prev_chapter_Max_dlineset_Max_dline_idx
            = $self->book->chapter_dlineset_dline_len(
                $ptr_0-1, $Prev_chapter_Max_dlineset_idx) - 1;
        return [join('.', $ptr_0-1,
                          $Prev_chapter_Max_dlineset_idx,
                          $Prev_chapter_Max_dlineset_Max_dline_idx), 0, 0, 1]
    }

    # Case 4: At start of book
    return undef
}
sub _max_loc {
    (sort _cmp_loc (keys %{$_[0]}))[-1]
}
sub _cmp_loc ($$) {
    my ($a,$b) = @_;

    # Convert each element to a zero-prefixed 5 digit string
    my $A = sprintf("%05d%05d%05d",split('\.',$a));
    my $B = sprintf("%05d%05d%05d",split('\.',$b));

    return $A cmp $B;
}

sub book_json {
    my ($self) = @_;

    my $Book_json = [];
    foreach my $ch_idx (0..$self->book->chapter_count-1) {
        my $chapter = $self->book->chapter_at($ch_idx);

        my $Chapter_json = [];
        foreach my $dset_idx (0..$chapter->dlineset_count -1) {
            my $dlineset = $chapter->dlineset_at($dset_idx);

            my $Dset_json = [];
            foreach my $dline_idx (0..$dlineset->dline_count-1) {
                my $dline = $dlineset->dline_at($dline_idx);

                my $Dline_json = {  # Create Dline JSON object
                    ptr   => "$ch_idx.$dset_idx.$dline_idx",
                    class => $dline->class,
                    str   => $dline->str
                };

                push @$Dset_json, $Dline_json;
            }

            push @$Chapter_json, $Dset_json;
        }

        push @$Book_json, $Chapter_json;
    }

    return encode_json $Book_json;
}

sub ptr { join '.', @{shift->_ptr} }

=encoding utf8
=cut
=head1 ATTRIBUTES
=cut
=head2   _chapter_dlines

The _chapter_dlines attribute stores the default Dline for each Dlineset
that makes up the chapter. In other words it has the Dline that should
be visible. It is a Hashref of a location to Dline. Example:

    _chapter_dlines = {
        '0.0.2'  => Dline({ class => 'chapter-number', str => ' /Chapter One' });
        '0.1.2'  => Dline({ class => 'chapter-title',  str => ' /A Great Surprise' });
        '0.2.13' => Dline({ class => 'paragraph-start',str => ' /"Mother, have ...' });
        ...
    }
=cut
=head2   _curr_dlineset

The _curr_dlineset attribute stores the Dlineset that is currently being
pointed to. In other words, it is the sentence that is currently being
read and being transformed from the native language to the target
language. Example:

    _curr_dlineset = {
        '0.1.0' => Dline({ class => 'chapter-title', str => 'ความประหลาดใจที่ยอดเยี่ยม /' });
        '0.1.1' => Dline({ class => 'chapter-title', str => 'ความประหลาดใจที่ /Great' });
        '0.1.2' => Dline({ class => 'chapter-title', str => ' /A Great Surprise' });
    }
=cut
=head1 METHODS
=cut
=head2   _load_chapter() :> Self

The _load_chapter() private method loads the chapter's default/targer
Dlines into the _chapter_dlines attribute. It loads the chapter
currently pointed to by the objects '_ptr' attribute.

=cut
=head2   html() :> HTML

The html() public method renders the current chapter into HTML.

=cut
=head2   _render(Dline) :> HTML

The _render(Dline) private function renders the given Dline into a
suitable HTML string.

=cut
=head2   _render_normal(Dline) :> HTML

The _render_normal(Dline) private method renders the given Dline into
the normal HTML output.

This method reads the class of the given Dline and renders the
associated element. The Dline class is responsible for font-size and
white-space associated with the line but not colors.

=cut
=head2   _render_pointed(Dline) :> HTML

The _render_pointed(Dline) private method renders the pointed-to line.
The pointed-to line entire broken line is displayed with a background.
The source language has one set of font-color and background-color while
the target language has another set of font-color and background-color.

We implement this by first wrapping the entire line in a span with class
"current-line". Then each segment is wrapped in a span as well. Segments
in the source language is has a class of src-lang. Segments in the
target language are unlabeled.

Then create a new Dline with the same class as the input, but with the
generated HTML as the str. Then call _render_normal on this new Dline to
generate the final HTML.

=cut
=head2   book_json() :> JSON

The book_json() public method converts the book into a JSON string. The
method iterates over all Chapters and all Dlinesets in each chapter and
all Dlines in all Dlinesets.

Note that the returned JSON string is already utf8 encoded so when
writing the string to a file, use the form without utf8 encoding e.g.
use L<Path::Tiny>'s spew() instead spew_utf8().

=cut

=head2   _next_ptr() :> undef | [Ptr,diff_chapter,diff_dlineset,diff_dline]

The _next_ptr() private method returns undef if no next pointer is
available. Otherwise, it returns the next pointer (Ptr), several boolean
flags indicating whether the next pointer points to a location in a
different chapter, a different dlineset or a different dline.

=cut
=head2   _prev_ptr() :> undef | [PtrStr,diff_chapter,diff_dlineset,diff_dline]

The _prev_ptr() private method returns undef if no previous pointer is
available. Otherwise, it returns the previous pointer (Ptr), several boolean
flags indicating whether the previous pointer points to a location in a
different chapter, a different dlineset or a different dline.

=cut
=head2   _max_loc($href)

Returns the max location of a href that has locations as key.

=cut
=head2   _cmp_loc($a,$b)

Returns -1, 0 or 1 depending on whether the left argument is stringwise
less than, equal to or greater than the right argument.

    $a < $b : -1
    $a = $b :  0
    $a > $b :  1

=cut

1;
