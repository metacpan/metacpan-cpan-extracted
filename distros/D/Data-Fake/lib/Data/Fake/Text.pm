use 5.008001;
use strict;
use warnings;

package Data::Fake::Text;
# ABSTRACT: Fake text data generators

our $VERSION = '0.003';

use Exporter 5.57 qw/import/;

our @EXPORT = qw(
  fake_words
  fake_sentences
  fake_paragraphs
);

use Data::Fake::Core qw/_transform/;

my $LOREM;

#pod =func fake_words
#pod
#pod     $generator = fake_words();    # single "lorem" word
#pod     $generator = fake_words($n);  # N "lorem" words, space separated
#pod     $generator = fake_words( fake_int(1, 3) ); # random number of them
#pod
#pod Returns a generator that provides space-separated L<Text::Lorem> words.
#pod The argument is the number of words to return (or a code reference to
#pod provide the number of words); the default is one.
#pod
#pod =cut

sub fake_words {
    my ($count) = @_;
    require Text::Lorem;
    $LOREM ||= Text::Lorem->new;
    return sub { $LOREM->words( _transform($count) ) };
}

#pod =func fake_sentences
#pod
#pod     $generator = fake_sentences();    # single fake sentence
#pod     $generator = fake_sentences($n);  # N sentences
#pod     $generator = fake_sentences( fake_int(1, 3) ); # random number of them
#pod
#pod Returns a generator that provides L<Text::Lorem> sentences.  The argument
#pod is the number of sentences to return (or a code reference to provide the
#pod number of sentences); the default is one.
#pod
#pod =cut

sub fake_sentences {
    my ($count) = @_;
    return sub { "" }
      if $count == 0;
    require Text::Lorem;
    $LOREM ||= Text::Lorem->new;
    return sub { $LOREM->sentences( _transform($count) ) };
}

#pod =func fake_paragraphs
#pod
#pod     $generator = fake_paragraphs();    # single fake paragraph
#pod     $generator = fake_paragraphs($n);  # N paragraph
#pod     $generator = fake_paragraphs( fake_int(1, 3) ); # random number of them
#pod
#pod Returns a generator that provides L<Text::Lorem> paragraphs.  The argument
#pod is the number of paragraphs to return (or a code reference to provide the
#pod number of paragraphs); the default is one.
#pod
#pod =cut

sub fake_paragraphs {
    my ($count) = @_;
    require Text::Lorem;
    $LOREM ||= Text::Lorem->new;
    return sub { $LOREM->paragraphs( _transform($count) ) };
}

1;


# vim: ts=4 sts=4 sw=4 et tw=75:

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Fake::Text - Fake text data generators

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use Data::Fake::Text;

    fake_words(2)->();
    fake_sentences(3)->();
    fake_paragraphs(1)->();

=head1 DESCRIPTION

This module provides fake data generators for random words and other
textual data.

All functions are exported by default.

=head1 FUNCTIONS

=head2 fake_words

    $generator = fake_words();    # single "lorem" word
    $generator = fake_words($n);  # N "lorem" words, space separated
    $generator = fake_words( fake_int(1, 3) ); # random number of them

Returns a generator that provides space-separated L<Text::Lorem> words.
The argument is the number of words to return (or a code reference to
provide the number of words); the default is one.

=head2 fake_sentences

    $generator = fake_sentences();    # single fake sentence
    $generator = fake_sentences($n);  # N sentences
    $generator = fake_sentences( fake_int(1, 3) ); # random number of them

Returns a generator that provides L<Text::Lorem> sentences.  The argument
is the number of sentences to return (or a code reference to provide the
number of sentences); the default is one.

=head2 fake_paragraphs

    $generator = fake_paragraphs();    # single fake paragraph
    $generator = fake_paragraphs($n);  # N paragraph
    $generator = fake_paragraphs( fake_int(1, 3) ); # random number of them

Returns a generator that provides L<Text::Lorem> paragraphs.  The argument
is the number of paragraphs to return (or a code reference to provide the
number of paragraphs); the default is one.

=for Pod::Coverage BUILD

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
