package Data::Classifier::NaiveBayes::Tokenizer;
use Moose;
use Lingua::Stem::Snowball;
use 5.008008;

has 'stemmer' => (
    is => 'rw',
    lazy_build => 1,
    handles => ['stem_in_place']);

has 'stemming' => (
    is => 'rw',);

has lang => (
    is => 'rw',
    default => sub { 'en' });

sub _build_stemmer { return Lingua::Stem::Snowball->new(lang => $_[0]->lang) } 

sub words {
    my ($self, $string, $token_callback) = @_;

    my @words = map { lc $_ } $string =~ /(\w+(?:[-']\w+)*)/g;

    my %ignore_words = map { $_ => 1 } $self->ignore_words;
    @words = grep { !$ignore_words{$_} } @words;

    $self->stemmer->stem_in_place(\@words) if $self->stemming;

    if ( $token_callback && ref $token_callback eq 'CODE' ) {
        @words = map { &{$token_callback}($_) } @words;
    }

    return \@words;
}

sub ignore_words {
    return (
    'a', 'about', 'above', 'across', 'after', 'afterwards', 
    'again', 'against', 'all', 'almost', 'alone', 'along', 
    'already', 'also', 'although', 'always', 'am', 'among', 
    'amongst', 'amoungst', 'amount', 'an', 'and', 'another', 
    'any', 'anyhow', 'anyone', 'anything', 'anyway', 'anywhere', 
    'are', 'around', 'as', 'at', 'back', 'be', 
    'became', 'because', 'become', 'becomes', 'becoming', 'been', 
    'before', 'beforehand', 'behind', 'being', 'below', 'beside', 
    'besides', 'between', 'beyond', 'bill', 'both', 'bottom', 
    'but', 'by', 'call', 'can', 'cannot', 'cant', 'dont',
    'co', 'computer', 'con', 'could', 'couldnt', 'cry', 
    'de', 'describe', 'detail', 'do', 'done', 'down', 
    'due', 'during', 'each', 'eg', 'eight', 'either', 
    'eleven', 'else', 'elsewhere', 'empty', 'enough', 'etc', 'even', 'ever', 'every', 
    'everyone', 'everything', 'everywhere', 'except', 'few', 'fifteen', 
    'fify', 'fill', 'find', 'fire', 'first', 'five', 
    'for', 'former', 'formerly', 'forty', 'found', 'four', 
    'from', 'front', 'full', 'further', 'get', 'give', 
    'go', 'had', 'has', 'hasnt', 'have', 'he', 
    'hence', 'her', 'here', 'hereafter', 'hereby', 'herein', 
    'hereupon', 'hers', 'herself', 'him', 'himself', 'his', 
    'how', 'however', 'hundred', 'i', 'ie', 'if', 
    'in', 'inc', 'indeed', 'interest', 'into', 'is', 
    'it', 'its', 'itself', 'keep', 'last', 'latter', 
    'latterly', 'least', 'less', 'ltd', 'made', 'many', 
    'may', 'me', 'meanwhile', 'might', 'mill', 'mine', 
    'more', 'moreover', 'most', 'mostly', 'move', 'much', 
    'must', 'my', 'myself', 'name', 'namely', 'neither', 
    'never', 'nevertheless', 'next', 'nine', 'no', 'nobody', 
    'none', 'noone', 'nor', 'not', 'nothing', 'now', 
    'nowhere', 'of', 'off', 'often', 'on', 'once', 
    'one', 'only', 'onto', 'or', 'other', 'others', 
    'otherwise', 'our', 'ours', 'ourselves', 'out', 'over', 
    'own', 'part', 'per', 'perhaps', 'please', 'put', 
    'rather', 're', 'same', 'see', 'seem', 'seemed', 
    'seeming', 'seems', 'serious', 'several', 'she', 'should', 
    'show', 'side', 'since', 'sincere', 'six', 'sixty', 
    'so', 'some', 'somehow', 'someone', 'something', 'sometime', 
    'sometimes', 'somewhere', 'still', 'such', 'system', 'take', 
    'ten', 'than', 'that', 'the', 'their', 'them', 
    'themselves', 'then', 'thence', 'there', 'thereafter', 'thereby', 
    'therefore', 'therein', 'thereupon', 'these', 'they', 'thick', 
    'thin', 'third', 'this', 'those', 'though', 'three', 
    'through', 'throughout', 'thru', 'thus', 'to', 'together', 
    'too', 'top', 'toward', 'towards', 'twelve', 'twenty', 
    'two', 'un', 'under', 'until', 'up', 'upon', 
    'us', 'very', 'via', 'was', 'we', 'well', 
    'were', 'what', 'whatever', 'when', 'whence', 'whenever', 
    'where', 'whereafter', 'whereas', 'whereby', 'wherein', 'whereupon', 
    'wherever', 'whether', 'which', 'while', 'whither', 'who', 
    'whoever', 'whole', 'whom', 'whose', 'why', 'will', 
    'with', 'within', 'without', 'would', 'yet', 'you', 'your', 'yours', 
    'yourself', 'yourselves'
    );
}

1;
=head1 NAME

Data::Classifier::NaiveBayes

=head1 SYNOPSIS

    my $tokenizer = Data::Classifier::NaiveBayes::Tokenizer->new;
    say @{$tokenizer->words("Hello World")};

=head1 DESCRIPTION

L<Data::Classifier::NaiveBayes> 

=head1 METHODS

=head1 SEE ALSO

L<Moose>, L<Lingua::Stem::Snowball>

=head1 AUTHOR

Logan Bell, C<< <logie@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2012, Logan Bell

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
