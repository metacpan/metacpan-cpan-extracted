package AI::Classifier::Text::Analyzer;
{
  $AI::Classifier::Text::Analyzer::VERSION = '0.03';
}

use strict;
use warnings;
use 5.010;
use Moose;

use Text::WordCounter;

has word_counter => ( is => 'ro', default => sub{ Text::WordCounter->new() } );
has global_feature_weight => ( is => 'ro', isa => 'Num', default => 2 );

sub analyze_urls {
    my ( $self, $text, $features ) = @_;
    my @urls;
    my $p = URI::Find->new(
        sub {
            my ($uri, $t) = @_;
            push @urls, $uri;
            eval{
                my $host = $uri->host;
                $host =~ s/^www\.//;
                $features->{ lc $host }++;
                for (split /\//, $uri->path) {
                    if (length $_ > 3 ) {
                        $features->{ lc $_}++;
                    }
                }
            }
        }
    );
    $p->find($text);
    my $weight = $self->global_feature_weight;
    if (!@urls) {
        $features->{NO_URLS} = $weight;
    }
    if (scalar @urls > length( $text ) / 120 ) {
        $features->{MANY_URLS} = $weight;
    }
    {
        my %urls;
        for my $url ( @urls ) {
            if( $urls{$url}++ > 3 ){
                $features->{REPEATED_URLS} = $weight;
                last;
            }
        }
    }
}

sub filter {
    my ( $self, $text ) = @_;
    $text =~ s/<[^>]+>//g;
    return $text;
}

sub analyze {
    my( $self, $text, $features ) = @_;
    $features ||= {};
    $self->analyze_urls( \$text, $features );
    $text = $self->filter( $text );
    $self->word_counter->word_count( $text, $features );
    return $features;
}

__PACKAGE__->meta->make_immutable;

1;

=pod

=head1 NAME

AI::Classifier::Text::Analyzer - computing feature vectors from documents

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use AI::Classifier::Text::Analyzer;

    my $analyzer = AI::Classifier::Text::Analyzer->new();
    
    my $features = $analyzer->analyze( 'aaaa http://www.example.com/bbb?xx=yy&bb=cc;dd=ff' );

=head1 DESCRIPTION

Computes feature vectors of text using some heuristics and adds words count 
(using L<Text::WordCounter> by default).

The object is immutable - but some methods use a second parameter as an accumulator for the
features found in given text.

It uses some specific values and methods that work for our case - but are not guaranteed
to bring good results universally - see the source for details!

=head1 ATTRIBUTES

=over 4

=item C<word_counter>

Object with a word_count method that will calculate the frequency of words in a text document.
By default L<Text::WordCounter>.

=item C<global_feature_weight>

The weight assigned for computed features of the text document. By default 2.

=back

=head1 METHODS

=over 4

=item C<< new(word_counter => $foo, global_feature_weight => 3) >>

Creates a new AI::Classifier::Text::Analyzer object. Both arguments are optional.

=item C<analyze($document, $features)>

Computes the feature vector of the given document and adds the initial vector of C<$features>.

=item C<analyze_urls($document, $features)>

Computes a vector special url related features of a given text - currently there are used 
C<NO_URLS>, C<MANY_URLS> and C<REPEATED_URLS> features.  

=item C<filter($document)>

Removes html related parts from the text.

=back

=head1 SEE ALSO

AI::NaiveBayes (3), AI::Classifier::Text(3)

=head1 AUTHOR

Zbigniew Lukasiak <zlukasiak@opera.com>, Tadeusz Sośnierz <tsosnierz@opera.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Opera Software ASA.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: computing feature vectors from documents

