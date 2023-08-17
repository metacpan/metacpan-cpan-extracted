package Chicken::Ipsum;
use strict;
use warnings;

our $VERSION = '0.03';

=head1 NAME

Chicken::Ipsum - Generate random chicken noises

=head1 SYNOPSIS

    require Chicken::Ipsum;

    my $ci = Chicken::Ipsum->new();

    # Generate a string of text with 5 words
    $words = $ci->words(5);

    # Generate a list of 5 words
    @words = $ci->words(5);

    # Generate a string of text with 2 sentences
    $sentences = $ci->sentences(2);

    # Generate a list of 2 sentences
    @sentences = $ci->sentences(2);

    # Generate a string of text with 3 paragraphs
    $paragraphs = $ci->paragraphs(3);

    # Generate a list of 3 paragraphs
    @paragraphs = $ci->paragraphs(3);

=head1 DESCRIPTION

Often when developing a website or other application, it's important to have
placeholders for content. This module generates prescribed amounts of clucking,
cawing and other chicken-y noises.

=cut

use List::Util qw/ sample /;

use constant WORDS => [qw/
	puk
	pukaaak
	cluck
	cluck-cluck-cluck
	cluckity
	bwak
	waaak
	bok
	bwok
	cluck-a-buh-gawk
	cock-a-doodle-doo
	bwwwaaaaaaaaaak
	gobble-gobble
	honk
/];
use constant PUNCTUATIONS => [qw/
    .
    ...
    !
    ?
/];
use constant MIN_SENTENCE_WORDS => 4;
use constant MAX_SENTENCE_WORDS => 10;
use constant MIN_PARAGRAPH_SENTENCES => 3;
use constant MAX_PARAGRAPH_SENTENCES => 7;

=head1 CONSTRUCTOR

=head2 C<new()>

The default constructor, C<new()> takes no arguments and returns a
Chicken::Ipsum object.

=cut

sub new {
    my ($class) = @_;
    return bless {
    }, $class;
}

=head1 METHODS

All methods below will return a string in scalar context or list in list context.

=head2 C<words( INTEGER )>

Returns INTEGER Chicken words.

=cut

sub words {
    my ($self, $num) = @_;
    my @words = sample $num, @{+WORDS};
    return wantarray ? @words : "@words";
}

=head2 C<sentences( INTEGER )>

Returns INTEGER sentences in Chicken.

=cut

sub sentences {
    my ($self, $num) = @_;
    my @sentences;
    # Sentences remaining "goes to" 0, LOL.
    # (See https://stackoverflow.com/q/1642028/237955)
    while ($num --> 0) {
        push @sentences, $self->_get_sentence();
    }
    return wantarray ? @sentences : "@sentences";
}

=head2 C<paragraphs( INTEGER )>

Returns INTEGER paragraphs of Chicken text.

=cut

sub paragraphs {
    my ($self, $num) = @_;
    my @paragraphs;
    while ($num --> 0) {
        push @paragraphs, $self->_get_paragraph;
    }
    return wantarray ? @paragraphs : join "\n\n", @paragraphs;
}

sub _get_paragraph {
    my $self = shift;
    my $num = MIN_PARAGRAPH_SENTENCES + int rand MAX_PARAGRAPH_SENTENCES - MIN_PARAGRAPH_SENTENCES;
    my $paragraph = $self->sentences($num);
    return $paragraph;
}

sub _get_punctuation {
    return sample 1, @{+PUNCTUATIONS};
}

sub _get_sentence {
    my $self = shift;
    my $num = MIN_SENTENCE_WORDS + int rand MAX_SENTENCE_WORDS;
    my $words = ucfirst $self->words($num);
    return $words . _get_punctuation();
}

=head1 AUTHOR

Dan Church (h3xx<attyzatzat>gmx<dottydot>com)

=head1 SEE ALSO

L<Text::Lorem>

L<https://isotropic.org/papers/chicken.pdf>

=head1 COPYRIGHT

Copyright (C) 2023 Dan Church.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN as well
as:

L<https://codeberg.org/h3xx/perl-Chicken-Ipsum>

=head1 THANKS

Thanks to Sebastian Carlos's L<https://chickenipsum.lol/>
(L<https://github.com/sebastiancarlos/chicken-ipsum>) for the inspiration.

=cut
1;
