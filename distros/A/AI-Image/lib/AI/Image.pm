package AI::Image;

use strict;
use warnings;

use strict;
use warnings;

use Carp;
use HTTP::Tiny;
use JSON::PP;

our $VERSION = '0.1';
$VERSION = eval $VERSION;

my $http = HTTP::Tiny->new;

# Create Image object
sub new {
    my $class = shift;
    my %attr  = @_;

    $attr{'error'}      = '';

    $attr{'api'}        = 'OpenAI' unless $attr{'api'};
    $attr{'error'}      = 'Invalid API' unless $attr{'api'} eq 'OpenAI';
    $attr{'error'}      = 'API Key missing' unless $attr{'key'};

    $attr{'model'}      = 'dall-e-2' unless $attr{'model'};
    $attr{'size'}       = '512x512'  unless $attr{'size'};

    return bless \%attr, $class;
}

# Define endpoints for APIs
my %url    = (
    'OpenAI' => 'https://api.openai.com/v1/images/generations',
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

# Get URL from image prompt
sub image {
    my ($self, $prompt) = @_;

    my $response = $http->post($url{$self->{'api'}}, {
         'headers' => {
             'Authorization' => 'Bearer ' . $self->{'key'},
             'Content-type'  => 'application/json'
         },
         content => encode_json {
             model          => $self->{'model'},
             size           => $self->{'size'},
             prompt         => $prompt,
         }
     });
     if ($response->{'content'} =~ 'invalid_api_key') {
         croak 'Incorrect API Key - check your API Key is correct';
     }
     
     if ($self->{'debug'} and !$response->{'success'}) {
         croak $response if $self->{'debug'} eq 'verbose';
         croak $response->{'content'};
     }

     my $reply = decode_json($response->{'content'});

     return $reply->{'data'}[0]->{'url'};
}

__END__

=head1 NAME

AI::Image - Generate images using OpenAI's DALL-E

=head1 VERSION

Version 0.1

=head1 SYNOPSIS

    use AI::Image;

    my $ai = AI::Image->new(
        'key'   => 'sk-......',
    );
    
    my $image_url = $ai->image("A photorealistic image of a cat wearing a top hat and monocle.");

    print $image_url;

=head1 DESCRIPTION

This module provides a simple interface to generate images using OpenAI's DALL-E API.

=head1 API KEYS

A free OpenAI API can be obtained from L<https://platform.openai.com/account/api-keys>

=head1 MODELS

Although the API Key is free, each use incurs a cost.  This is dependent on the
model chosen and the size.  The 'dall-e-3' model produces better images but at a
higher cost.  Likewise, bigger images cost more.
The default model C<dall-e-2> with the default size of C<512x512> produces resonable
results at a low cost and is a good place to start using this module.

See also L<https://platform.openai.com/docs/models/overview>

=head1 METHODS

=head2 new

  my $ai = AI::Image->new(%params);

Creates a new AI::Image object.

=head3 Parameters

=over 4

=item key

C<required> Your OpenAI API key.

=item api

The API to use (currently only 'OpenAI' is supported).

=item model

The language model to use (default: 'dall-e-2').

See L<https://platform.openai.com/docs/models/overview>

=item size

The size for the generated image (default: '512x512').

=item debug

Used for testing.  If set to any true value, the image method
will return details of the error encountered instead of C<undef>

=back

=head2 image

  my $url = $ai->image($prompt);

Generates an image based on the provided prompt and returns the URL of the generated image.  The URL is valid for 1 hour.

=head3 Parameters

=over 4

=item prompt

The textual description of the desired image.

=back

=head2 success

  my $success = $ai->success();

Returns true if the last operation was successful.

=head2 error

  my $error = $ai->error();

Returns the error message if the last operation failed.

=head1 EXAMPLE

It is common that the generated image will want to be saved as a file.  This can be easily acheived
using the C<getstore> method of L<LWP::Simple>.

    use strict;
    use warnings;
    
    use LWP::Simple;
    use AI::Image;
    
    my $ai = AI::Image->new(
        'key'   => 'sk-......',
    );
    
    my $image_url = $ai->image("A dog reading a newspaper");
    
    getstore( $image_url, 'my_ai_image.png' );


=head1 SEE ALSO

L<https://openai.com> - OpenAI official website

=head1 AUTHOR

Ian Boddison <ian at boddison.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-image at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=bug-ai-image>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::Image

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-Image>

=item * Search CPAN

L<https://metacpan.org/release/AI::Image>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Ian Boddison

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

