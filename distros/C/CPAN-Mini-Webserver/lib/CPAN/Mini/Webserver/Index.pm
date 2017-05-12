use strict;
use warnings;

package CPAN::Mini::Webserver::Index;

# ABSTRACT: search term index for a CPAN::Mini web server

our $VERSION = '0.58'; # VERSION

use Moose;
use List::MoreUtils qw(uniq);
use Search::QueryParser;
use String::CamelCase qw(wordsplit);
use Text::Unidecode;
use Search::Tokenizer;
use Pod::Simple::Text;
use Lingua::StopWords qw( getStopWords );

has 'index' => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'full_text' => ( is => 'ro' );
has 'index_subs' => ( is => 'ro' );

sub add {
    my ( $self, $key, $words ) = @_;

    my $index = $self->index;
    push @{ $index->{$_} }, $key for @{$words};

    return;
}

sub create_index {
    my ( $self, $parse_cpan_authors, $parse_cpan_packages ) = @_;

    $self->_index_items_with( "_author_words",  $parse_cpan_authors->authors );
    $self->_index_items_with( "_dist_words",    $parse_cpan_packages->latest_distributions );
    $self->_index_items_with( "_package_words", $parse_cpan_packages->packages );

    $self->_index_sub_routines( $parse_cpan_packages->packages ) if $self->index_subs;

    return;
}

sub _index_sub_routines {
    my ( $self, @packages ) = @_;

    $self->{subs}{ $_ } = 1 for map { $_->subs } @packages;

    return;
}

sub _index_items_with {
    my ( $self, $method, @items ) = @_;

    for my $item ( @items ) {
        my @words = $self->$method( $item );
        @words = uniq map { lc } @words;
        $self->add( $item, \@words );
    }

    return;
}

sub _author_words {
    my ( $self, $author ) = @_;
    my @words = ( $author->name, $author->pauseid );
    return @words;
}

sub _dist_words {
    my ( $self, $dist ) = @_;
    my @words = split '-', unidecode $dist->dist;
    @words = map { $_, wordsplit( $_ ) } @words;
    return @words;
}

sub _package_words {
    my ( $self, $package ) = @_;
    my @words = split '::', unidecode $package->package;
    @words = map { $_, wordsplit( $_ ) } @words;

    push @words, $self->_full_text_words( $package ) if $self->full_text;

    return @words;
}

sub _full_text_words {
    my ( $self, $package ) = @_;
    my @words = split '::', unidecode $package->package;
    @words = map { $_, wordsplit( $_ ) } @words;

    my $content = $package->file_content;
    my $text;
    my $parser = Pod::Simple::Text->new;
    $parser->no_whining( 1 );
    $parser->no_errata_section( 1 );
    $parser->output_string( \$text );
    $parser->parse_string_document( $content );

    my $stopwords = { %{ getStopWords('en') }, NAME => 1, DESCRIPTION => 1, USAGE => 1, RETURNS => 1 };
    my $iterator = Search::Tokenizer->new( regex => qr/\p{Word}+/, lower => 0, stopwords => $stopwords )->( $text );
    while (my ($term, $len, $start, $end, $index) = $iterator->()) {
        push @words, $term;
    }

    return @words;
}

sub search {
    my ( $self, $q ) = @_;

    my $qp = Search::QueryParser->new( rxField => qr/NOTAFIELD/, );
    my $query = $qp->parse( $q, 1 );
    return if !$query;

    my $index = $self->index;
    my @results;

    for my $part ( @{ $query->{'+'} } ) {
        my $value = $part->{value};
        my @words = split /(?:\:\:| |-)/, unidecode lc $value;
        for my $word ( @words ) {
            my @word_results = @{ $index->{$word} || [] };
            if ( @results ) {
                my %seen;
                $seen{$_} = 1 for @word_results;
                @results = grep { $seen{$_} } @results;
            }
            else {
                @results = @word_results;
            }
        }
    }

    for my $part ( @{ $query->{'-'} } ) {
        my $value        = $part->{value};
        my @word_results = $self->search_word( $value );
        my %seen;
        $seen{$_} = 1 for @word_results;
        @results = grep { !$seen{$_} } @results;
    }

    return @results;
}

sub search_word {
    my ( $self, $word ) = @_;

    my $index = $self->index;
    my @words = split /(?:\:\:| |-)/, unidecode lc $word;
    @words = grep exists( $index->{$_} ), @words;

    my @results = map @{ $index->{$_} }, @words;
    return @results;
}

1;



=pod

=head1 NAME

CPAN::Mini::Webserver::Index - search term index for a CPAN::Mini web server

=head1 VERSION

version 0.58

=head1 DESCRIPTION

This module indexes words for the search feature in CPAN::Mini::Webserver.

=head1 AUTHORS

=over 4

=item *

Leon Brocard <acme@astray.com>

=item *

Christian Walde <walde.christian@googlemail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Christian Walde.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

