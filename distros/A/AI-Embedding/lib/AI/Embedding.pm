package AI::Embedding;

use strict;
use warnings;

use HTTP::Tiny;
use JSON::PP;
use Data::CosineSimilarity;

our $VERSION = '1.11';
$VERSION = eval $VERSION;

my $http = HTTP::Tiny->new;

# Create Embedding object
sub new {
    my $class = shift;
    my %attr  = @_;

    $attr{'error'}      = '';

    $attr{'api'}        = 'OpenAI' unless $attr{'api'};
    $attr{'error'}      = 'Invalid API' unless $attr{'api'} eq 'OpenAI';
    $attr{'error'}      = 'API Key missing' unless $attr{'key'};

    $attr{'model'}      = 'text-embedding-ada-002' unless $attr{'model'};

    return bless \%attr, $class;
}

# Define endpoints for APIs
my %url    = (
    'OpenAI' => 'https://api.openai.com/v1/embeddings',
);

# Define HTTP Headers for APIs
my %header = (
    'OpenAI' => &_get_header_openai,
);

# Returns true if last operation was success
sub success {
    my $self = shift;
    return !$self->{'error'};
}

# Returns error if last operation failed
sub error {
    my $self = shift;
    return $self->{'error'};
}

# Header for calling OpenAI
sub _get_header_openai {
    my $self = shift;
    $self->{'key'} = '' unless defined $self->{'key'};
    return {
         'Authorization' => 'Bearer ' . $self->{'key'},
         'Content-type'  => 'application/json'
     };
 }

 # Fetch Embedding response
 sub _get_embedding {
     my ($self, $text) = @_;

     my $response = $http->post($url{$self->{'api'}}, {
         'headers' => {
             'Authorization' => 'Bearer ' . $self->{'key'},
             'Content-type'  => 'application/json'
         },
         content => encode_json {
             input  => $text,
             model  => $self->{'model'},
         }
     });
     if ($response->{'content'} =~ 'invalid_api_key') {
         die 'Incorrect API Key - check your API Key is correct';
     }
     return $response;
 }

 # TODO:
 # Make 'headers' use $header{$self->{'api'}}
 # Currently hard coded to OpenAI

 # Added purely for testing - IGNORE!
 sub _test {
     my $self = shift;
#    return $self->{'api'};
     return $header{$self->{'api'}};
 }

 # Return Embedding as a CSV string
 sub embedding {
     my ($self, $text, $verbose) = @_;

     my $response = $self->_get_embedding($text);
     if ($response->{'success'}) {
         my $embedding = decode_json($response->{'content'});
         return join (',', @{$embedding->{'data'}[0]->{'embedding'}});
     }
     $self->{'error'} = 'HTTP Error - ' . $response->{'reason'};
     return $response if defined $verbose;
     return undef;
 }

 # Return Embedding as an array
 sub raw_embedding {
     my ($self, $text, $verbose) = @_;

     my $response = $self->_get_embedding($text);
     if ($response->{'success'}) {
         my $embedding = decode_json($response->{'content'});
         return @{$embedding->{'data'}[0]->{'embedding'}};
     }
     $self->{'error'} = 'HTTP Error - ' . $response->{'reason'};
     return $response if defined $verbose;
     return undef;
 }

 # Return Test Embedding
 sub test_embedding {
     my ($self, $text, $dimension) = @_;
     $self->{'error'} = '';

     $dimension = 1536 unless defined $dimension;

     if ($text) {
         srand scalar split /\s+/, $text;
     }

     my @vector;
     for (1...$dimension) {
         push @vector, rand(2) - 1;
     }
     return join ',', @vector;
 }

# Convert a CSV Embedding into a hashref
sub _make_vector {
    my ($self, $embed_string) = @_;

    if (!defined $embed_string) {
        $self->{'error'} = 'Nothing to compare!';
        return;
    }

    my %vector;
    my @embed = split /,/, $embed_string;
    for (my $i = 0; $i < @embed; $i++) {
       $vector{'feature' . $i} = $embed[$i];
   }
   return \%vector;
}

# Return a comparator to compare to a set vector
sub comparator {
    my($self, $embed) = @_;
    $self->{'error'} = '';

    my $vector1 = $self->_make_vector($embed);
    return sub {
        my($embed2) = @_;
        my $vector2 = $self->_make_vector($embed2);
        return $self->_compare_vector($vector1, $vector2);
    };
}

# Compare 2 Embeddings
sub compare {
    my ($self, $embed1, $embed2) = @_;

    my $vector1 = $self->_make_vector($embed1);
    my $vector2;
    if (defined $embed2) {
        $vector2 = $self->_make_vector($embed2);
    } else {
        $vector2 = $self->{'comparator'};
    }

    if (!defined $vector2) {
        $self->{'error'} = 'Nothing to compare!';
        return;
    }

    if (scalar keys %$vector1 != scalar keys %$vector2) {
        $self->{'error'} = 'Embeds are unequal length';
        return;
    }

    return $self->_compare_vector($vector1, $vector2);
}

# Compare 2 Vectors
sub _compare_vector {
    my ($self, $vector1, $vector2) = @_;
    my $cs = Data::CosineSimilarity->new;
    $cs->add( label1 => $vector1 );
    $cs->add( label2 => $vector2 );
    return $cs->similarity('label1', 'label2')->cosine;
}

1;

__END__

=encoding utf8

=head1 NAME

AI::Embedding - Perl module for working with text embeddings using various APIs

=head1 VERSION

Version 1.11

=head1 SYNOPSIS

    use AI::Embedding;

    my $embedding = AI::Embedding->new(
        api => 'OpenAI',
        key => 'your-api-key'
    );

    my $csv_embedding  = $embedding->embedding('Some sample text');
    my $test_embedding = $embedding->test_embedding('Some sample text');
    my @raw_embedding  = $embedding->raw_embedding('Some sample text');

    my $cmp = $embedding->comparator($csv_embedding2);

    my $similarity = $cmp->($csv_embedding1);
    my $similarity_with_other_embedding = $embedding->compare($csv_embedding1, $csv_embedding2);

=head1 DESCRIPTION

The L<AI::Embedding> module provides an interface for working with text embeddings using various APIs. It currently supports the L<OpenAI|https://www.openai.com> L<Embeddings API|https://platform.openai.com/docs/guides/embeddings/what-are-embeddings>. This module allows you to generate embeddings for text, compare embeddings, and calculate cosine similarity between embeddings.

Embeddings allow the meaning of passages of text to be compared for similarity.  This is more natural and useful to humans than using traditional keyword based comparisons.

An Embedding is a multi-dimensional vector representing the meaning of a piece of text.  The Embedding vector is created by an AI Model.  The default model (OpenAI's C<text-embedding-ada-002>) produces a 1536 dimensional vector.  The resulting vector can be obtained as a Perl array or a Comma Separated String. As the Embedding will typically be used homogeneously, having it as a CSV String is usually more convenient.  This is suitable for storing in a C<TEXT> field of a database.

=head2 Comparator

Embeddings are used to compare similarity of meaning between two passages of text.  A typical work case is to store a number of pieces of text (e.g. articles or blogs) in a database and compare each one to some user supplied search text.  L<AI::Embedding> provides a C<compare> method compare two Embeddings.

Alternatively, the C<comparator> method can be called with one Embedding.  The C<comparator> returns a reference to a method that takes a single Embedding to be compared to the Embedding from which the Comparator was created.

When comparing multiple Embeddings to the same Embedding (such as search text) it is faster to use a C<comparator>.

=head1 CONSTRUCTOR

=head2 new

    my $embedding = AI::Embedding->new(
        api         => 'OpenAI',
        key         => 'your-api-key',
        model       => 'text-embedding-ada-002',
    );

Creates a new AI::Embedding object. It requires the 'key' parameter. The 'key' parameter is the API key provided by the service provider and is required.

Parameters:

=over

=item *

C<key> - B<required> The API Key

=item *

C<api> - The API to use.  Currently only 'OpenAI' is supported and this is the default.

=item *

C<model> - The language model to use.  Defaults to C<text-embedding-ada-002> - see L<OpenAI docs|https://platform.openai.com/docs/guides/embeddings/what-are-embeddings>

=back

=head1 METHODS

=head2 success

Returns true if the last method call was successful

=head2 error

Returns the last error message or an empty string if B<success> returned true

=head2 embedding

    my $csv_embedding = $embedding->embedding('Some text passage', [$verbose]);

Generates an embedding for the given text and returns it as a comma-separated string. The C<embedding> method takes a single parameter, the text to generate the embedding for.

Returns a (rather long) string that can be stored in a C<TEXT> database field.

If the method call fails it sets the L</"error"> message and returns C<undef>.  If the optional C<verbose> parameter is true, the complete L<HTTP::Tiny> response object is also returned to aid with debugging issues when using this module.

=head2 raw_embedding

    my @raw_embedding = $embedding->raw_embedding('Some text passage', [$verbose]);

Generates an embedding for the given text and returns it as an array. The C<raw_embedding> method takes a single parameter, the text to generate the embedding for.

It is not normally necessary to use this method as the Embedding will almost always be used as a single homogeneous unit.

If the method call fails it sets the L</"error"> message and returns C<undef>.  If the optional C<verbose> parameter is true, the complete L<HTTP::Tiny> response object is also returned to aid with debugging issues when using this module.

=head2 test_embedding

    my $test_embedding = $embedding->test_embedding('Some text passage', $dimensions);

Used for testing code without making a chargeable call to the API.

Provides a CSV string of the same size and format as L<embedding> but with meaningless random data.

Returns a random embedding.  Both parameters are optional.  If a text string is provided, the returned embedding will always be the same random embedding otherwise it will be random and different every time.  The C<dimension> parameter controls the number of elements of the returned CSV string.  If omitted, the string will have the C<text-embedding-ada-002> default of 1536 elements.

=head2 comparator

    $embedding->comparator($csv_embedding2);

Sets a vector as a C<comparator> for future comparisons and returns a reference to a method for using the C<comparator>.

The B<comparator> method takes a single parameter, the comma-separated Embedding string to use as the comparator.

The following two are functionally equivalent.  However, where multiple Embeddings are to be compared to a single Embedding, using a L<Comparator> is significantly faster.

    my $similarity = $embedding->compare($csv_embedding1, $csv_embedding2);


    my $cmp = $embedding->comparator($csv_embedding2);
    my $similarity = $cmp->($csv_embedding1);

See L</"Comparator">

The returned method reference returns the cosine similarity between the Embedding used to call the C<comparator> method and the Embedding supplied to the method reference.  See L<compare> for an explanation of the cosine similarity.

=head2 compare

    my $similarity_with_other_embedding = $embedding->compare($csv_embedding1, $csv_embedding2);

Compares two embeddings and returns the cosine similarity between them. The B<compare> method takes two parameters: $csv_embedding1 and $csv_embedding2 (both comma-separated embedding strings).

Returns the cosine similarity as a floating-point number between -1 and 1, where 1 represents identical embeddings, 0 represents no similarity, and -1 represents opposite embeddings.

The absolute number is not usually relevant for text comparision.  It is usually sufficient to rank the comparison results in order of high to low to reflect the best match to the worse match.

=head1 SEE ALSO

L<https://openai.com> - OpenAI official website

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-embedding at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=bug-ai-embedding>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Embedding

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Embedding>

=item * Search CPAN

L<https://metacpan.org/release/AI::Embedding>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the help and support provided by members of Perl Monks L<https://perlmonks.org/>.

Especially L<Ken Cotterill (KCOTT)|https://metacpan.org/author/KCOTT> for assistance with unit tests and L<Hugo van der Sanden (HVDS)|https://metacpan.org/author/HVDS> for suggesting the current C<comparator> implementaion.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Ian Boddison.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
