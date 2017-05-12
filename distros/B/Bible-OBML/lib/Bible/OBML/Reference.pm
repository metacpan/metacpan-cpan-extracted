package Bible::OBML::Reference;
# ABSTRACT: Simple Bible reference parser

use strict;
use warnings;

use Moose;
use List::MoreUtils 'firstidx';

our $VERSION = '1.07'; # VERSION

with 'Throwable';

has bible => ( is => 'ro', isa => 'ArrayRef[ArrayRef[Str]]', default => sub { [
    [ 'Genesis', 'Ge', 'Gen' ],
    [ 'Exodus', 'Ex', 'Exo' ],
    [ 'Leviticus', 'Le', 'Lev' ],
    [ 'Numbers', 'Nu', 'Num' ],
    [ 'Deuteronomy', 'De', 'Deut' ],
    [ 'Joshua', 'Jsh', 'Josh' ],
    [ 'Judges', 'Jdg', 'Judg' ],
    [ 'Ruth', 'Ru', 'Ruth' ],
    [ '1 Samuel', '1Sa', '1 Sam' ],
    [ '2 Samuel', '2Sa', '2 Sam' ],
    [ '1 Kings', '1Ki' ],
    [ '2 Kings', '2Ki' ],
    [ '1 Chronicles', '1Ch', '1 Chr' ],
    [ '2 Chronicles', '2Ch', '2 Chr' ],
    [ 'Ezra', 'Er', 'Ezra' ],
    [ 'Nehemiah', 'Ne', 'Neh' ],
    [ 'Esther', 'Es', 'Esth' ],
    [ 'Job', 'Jb', 'Job' ],
    [ 'Psalms', 'Ps' ],
    [ 'Proverbs', 'Prv', 'Prov' ],
    [ 'Ecclesiastes', 'Ec', 'Eccl' ],
    [ 'Song of Solomon', 'Sng', 'Song' ],
    [ 'Isaiah', 'Is', 'Isa' ],
    [ 'Jeremiah', 'Je', 'Jer' ],
    [ 'Lamentations', 'Lm', 'Lam' ],
    [ 'Ezekiel', 'Ek', 'Ezek' ],
    [ 'Daniel', 'Da', 'Dan' ],
    [ 'Hosea', 'Ho', 'Hos' ],
    [ 'Joel', 'Jl', 'Joel' ],
    [ 'Amos', 'Am', 'Amos' ],
    [ 'Obadiah', 'Ob', 'Oba' ],
    [ 'Jonah', 'Jnh', 'Jonah' ],
    [ 'Micah', 'Mi', 'Mic' ],
    [ 'Nahum', 'Na', 'Nah' ],
    [ 'Habakkuk', 'Hb', 'Hab' ],
    [ 'Zephaniah', 'Zph', 'Zeph' ],
    [ 'Haggai', 'Hg', 'Hag' ],
    [ 'Zechariah', 'Zch', 'Zech' ],
    [ 'Malachi', 'Ml', 'Mal' ],
    [ 'Matthew', 'Mt', 'Matt' ],
    [ 'Mark', 'Mk', 'Mark' ],
    [ 'Luke', 'Lk', 'Luke' ],
    [ 'John', 'Jhn', 'John' ],
    [ 'Acts', 'Ac', 'Acts' ],
    [ 'Romans', 'Ro', 'Rom' ],
    [ '1 Corinthians', '1Co', '1 Cor' ],
    [ '2 Corinthians', '2Co', '2 Cor' ],
    [ 'Galatians', 'Ga', 'Gal' ],
    [ 'Ephesians', 'Eph' ],
    [ 'Philippians', 'Php', 'Philip' ],
    [ 'Colossians', 'Co', 'Col' ],
    [ '1 Thessalonians', '1Th' ],
    [ '2 Thessalonians', '2Th' ],
    [ '1 Timothy', '1Tm', '1 Tim' ],
    [ '2 Timothy', '2Tm', '2 Tim' ],
    [ 'Titus', 'Ti', 'Titus' ],
    [ 'Philemon', 'Phm', 'Phile' ],
    [ 'Hebrews', 'He', 'Heb' ],
    [ 'James', 'Ja', 'Jam' ],
    [ '1 Peter', '1Pt', '1 Pet' ],
    [ '2 Peter', '2Pt', '2 Pet' ],
    [ '1 John', '1Jn' ],
    [ '2 John', '2Jn' ],
    [ '3 John', '3Jn' ],
    [ 'Jude', 'Jud', 'Jude' ],
    [ 'Revelation', 'Rv', 'Rev' ],
] } );

{
    my %book_lookup;
    my %acronym_lookup;
    my @books;
    my @acronyms;

    sub BUILD {
        my ($self) = @_;

        for my $book ( @{ $self->bible } ) {
            $book_lookup{$_} = $book->[0] for (@$book);
            push( @books, $book->[0] );

            $acronym_lookup{ $book->[0] } = $book->[1];
            push( @acronyms, $book->[1] );
        }

        return;
    }

    sub books {
        my ( $self, $book ) = @_;
        return @books unless ($book);
        return ( $book_lookup{$book} or $self->throw( qq{Failed to find "$book" during book lookup} ) );
    }

    sub acronyms {
        my ( $self, $acronym ) = @_;
        return @acronyms unless ($acronym);
        return (
            $acronym_lookup{$acronym}
            or $self->throw( qq{Failed to find "$acronym" during acronym lookup} )
        );
    }
}

sub parse {
    my ( $self, $text, $return_acronyms ) = @_;
    my @references;

    # fix-up "1Cor 3:15-1Cor 3:20" into "1Cor 3:15-3:20"
    $text =~ s/\-\s*((?:[123]|[Ii]{1,3})?\s*[A-z]+)\s/\-/g;

    # loop through each part of $text that looks like it might be a reference
    while (
        $text =~ s/
            \b((?:[123]|[Ii]{1,3})\s*
            [A-z]+)\.{0,1}\s+
            (?:ch\.{0,1}\s){0,1}
            (\d+(?:[\d:\-,;\s]+\d+){0,1})
            [;,\s]*$
        //x
        or
        $text =~ s/
            ([A-z]+)\.{0,1}\s+
            (?:ch\.{0,1}\s){0,1}
            (\d+(?:[\d:\-,;\s]+\d+){0,1})
            [;,\s]*$
        //x
    ) {
        my ( $book, $numbers ) = ( $1, $2 );

        # skip some obviously non-reference strings
        unless ( $numbers !~ /[:-]/ and length($numbers) > 3 ) {
            $book =~ s/^(\d)(\S)/$1 $2/;

            # convert "II Corinthians" to "2 Corinthians" (and similar)
            $book =~ s/^([iI]{1,3})\s/ length($1) . ' ' /e;

            my $new_book = ( grep { /^$book/i } $self->books )[0] || undef;
            unless ($new_book) {
                my $pattern = join( '.*', split( '', $book ) );
                $new_book = ( grep { /^$pattern/i } $self->books )[0] || undef;
            }

            if ($new_book) {
                $new_book = $self->books($new_book);

                # do some cleanup of the chapter/verse numbers
                $numbers =~ s/\s{2,}/ /g;
                $numbers =~ s/([;,])\s{2,}/$1 /g;
                $numbers =~ s/\s*[\-]+\s*/-/g;

                # "2:20-2:30" becomes "2:20-30"
                $numbers =~ s/
                    (\d+)\s*:\s*(\d+)\s*
                    \-
                    \s*(\d+)\s*:\s*(\d+)
                /
                    ( $1 and $3 and $1 == $3 ) ? "$1:$2-$4" : "$1:$2-$3:$4"
                /gex;

                push( @references, $new_book . ' ' . $_ ) foreach (
                    map {
                        split( /[;]\s*(?=\d)/ )
                    } split( /[;,]\s*(?=\d+:)/, $numbers )
                );
            }
        }
    }

    # unique the references
    my %references = map { $_ => 1 } @references;
    @references = keys %references;

    # sort the references by biblical location
    @references = sort {
        $a =~ /^((?:\d\s)?\D+)\s+(\d+)\D*(\d*)/;
        my ( $a_book, $a_chapter, $a_verse ) = ( $1, $2, $3 );

        $b =~ /^((?:\d\s)?\D+)\s+(\d+)\D*(\d*)/;
        my ( $b_book, $b_chapter, $b_verse ) = ( $1, $2, $3 );

        if ( $a_book ne $b_book ) {
            my $a_book_index = firstidx { $_ eq $a_book } $self->books;
            my $b_book_index = firstidx { $_ eq $b_book } $self->books;
            $a_book_index <=> $b_book_index;
        }
        else {
            $a_chapter <=> $b_chapter or do {
                my $a_bit = ( $a_verse =~ /(\d+)/ ) ? $1 : 0;
                my $b_bit = ( $b_verse =~ /(\d+)/ ) ? $1 : 0;
                $a_bit <=> $b_bit;
            };
        }
    }
    @references;

    # set references to acronyms if that was requested
    @references = map {
        /^((?:\d\s)?\D+)\s+(\d+)\D*(.*+)/;
        my ( $book, $chapter, $verse ) = ( $1, $2, $3 );
        join( '', $self->acronyms($book), ' ', $chapter, ':', $verse );
    } @references if ($return_acronyms);

    return ( wantarray() ) ? @references : \@references;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bible::OBML::Reference - Simple Bible reference parser

=head1 VERSION

version 1.07

=head1 SYNOPSIS

    use Bible::OBML::Reference;
    my $self = Bible::OBML::Reference->new;

    my $ref = $self->parse('Text that includes Romans 2:2-14 and other words');

    my @books    = $self->books;
    my @acronyms = $self->acronyms;

=head1 DESCRIPTION

This module primarily provides a method to parse text to pull out canonical
Bible references. These are "address references" only, such as "James 1:5".
There are supporting methods that may also be useful such as returning a list
of books and acronyms.

=head1 METHODS

=head2 parse

This method expects to receive a text string and will return a list of canonical
Bible references that it was able to derive from the string. The method will
parse the string looking for what appear to be references. If any are found,
they are canonicalized and returned.

    my @ref = $self->parse('Text that includes Romans 2:2-14 and other words');
    # $ref[0] now contains "Romans 2:2-14"

You can also provide an optional second parameter, and if it is positive, the
method will return acronyms instead of full book names. Also note that the
method will return an arrayref insteaf an array if in scalar context.

    my $ref = $self->parse('Text that includes Romans 2:2-14 and other words');
    # $ref->[0] now contains "Ro 2:2-14"

=head2 books

    my @books = $self->books;
    my $book  = $self->books('Genesis');

Returns either a list of all books of the Bible or a single book title that
matches the acronym provided.

=head2 acronyms

    my @acronyms = $self->acronyms;
    my $acronym  = $self->acronyms('Genesis');

Returns either a list of all short acronyms or a single short acronym that
matches the book full title provided.

=head1 ATTRIBUTES

=head2 bible

This is a read-only attribute that contains an arrayref of arrayrefs, each
containing 3 text strings. The first string is the full name of a book of the
Bible, followed by a very short acronym, followed by a more common and slightly
longer acronym. The books (as arrayrefs) are listed in Bible order. For example:

    [ 'Genesis', 'Ge', 'Gen' ],
    [ 'Exodus', 'Ex', 'Exo' ],
    [ 'Leviticus', 'Le', 'Lev' ],

=head1 SEE ALSO

L<Bible::OBML>.

You can also look for additional information at:

=over 4

=item *

L<GitHub|https://github.com/gryphonshafer/Bible-OBML>

=item *

L<CPAN|http://search.cpan.org/dist/Bible-OBML>

=item *

L<MetaCPAN|https://metacpan.org/pod/Bible::OBML>

=item *

L<AnnoCPAN|http://annocpan.org/dist/Bible-OBML>

=item *

L<Travis CI|https://travis-ci.org/gryphonshafer/Bible-OBML>

=item *

L<Coveralls|https://coveralls.io/r/gryphonshafer/Bible-OBML>

=item *

L<CPANTS|http://cpants.cpanauthors.org/dist/Bible-OBML>

=item *

L<CPAN Testers|http://www.cpantesters.org/distro/B/Bible-OBML.html>

=back

=for Pod::Coverage BUILD

=head1 AUTHOR

Gryphon Shafer <gryphon@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gryphon Shafer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
