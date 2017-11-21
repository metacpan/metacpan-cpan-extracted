package App::WatchLater::YouTube;

use 5.016;
use strict;
use warnings;

=head1 NAME

App::WatchLater::YouTube - The YouTube Data API

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

This is a simple module for making requests to the YouTube Data API.
Authorization is required, and can be obtained by registering for an API key
from the Google Developer L<API
Console|https://console.developers.google.com/apis/credentials>. Alternatively,
obtain user authorization through OAuth2 using the yt-oauth(1) script.

    my $api = App::WatchLater::YouTube->new(
        access_token => ...,
        api_key      => ...,
    );

    # returns the body of the HTTP response as a string
    my $body = $api->request('GET', '/videos', {
      id => 'Ks-_Mh1QhMc',
      part => 'snippet'
    });
    ...

=head1 EXPORT

=over 4

=item *

C<find_video_id> - exported by default.

=back

=cut

BEGIN {
  require Exporter;
  our @ISA       = qw(Exporter);
  our @EXPORT    = qw(find_video_id);
  our @EXPORT_OK = qw(find_video_id);
}

=head1 SUBROUTINES/METHODS

=head2 find_video_id

    my $video_id = find_video_id($url);

Find a YouTube video ID from a YouTube watch URL. Also accepts I<youtu.be>
shortened URLs and literal video IDs.

=cut

my $regex = qr/[a-z0-9_-]+/i;

sub find_video_id {
  local $_ = shift;
  return $1 if m{youtube\.com/watch.*\bv=($regex)};
  return $1 if m{youtu.be/($regex)};
  return $1 if m{^($regex)$};
  die "'$_' is not a valid video ID";
}

=head2 new

    my $api = App::WatchLater::YouTube->new(%opts)

This constructor returns a new API object. Attributes include:

=over 4

=item *

C<http> - an instance of HTTP::Tiny. If none is provided, a default new instance
is used.

=item *

C<api_key> - an API key.

=item *

C<access_token> - an OAuth2 access token.

=back

At least one of C<api_key> and C<access_token> must be provided. If both are
provided, C<access_token> is used for authorization.

=cut

use Carp;
use HTTP::Tiny;
use JSON;

BEGIN {
  my ($ok, $why) = HTTP::Tiny->can_ssl;
  croak $why unless $ok;
}

sub new {
  my ($class, %opts) = @_;

  my $http  = $opts{http} // HTTP::Tiny->new;
  my $key   = $opts{api_key};
  my $token = $opts{access_token};

  defined $key || defined $token
    or croak "no API key or access token, aborting";

  bless {
    http  => $http,
    key   => $key,
    token => $token,
  } => $class;
}

=head2 request

    my $body = $api->request($method, $endpoint, %params);

Send a request to the specified API endpoint using the given HTTP method. Query
parameters may be specified in C<%params>. Croaks if the request fails.

=cut

sub request {
  my ($self, $method, $endpoint, %params) = @_;
  my $url = 'https://www.googleapis.com/youtube/v3' . $endpoint;

  my %headers;

  if (defined $self->{token}) {
    $headers{Authorization} = 'Bearer ' . $self->{token};
  } else {
    $params{key} ||= $self->{key};
  }

  my $query = $self->{http}->www_form_urlencode(\%params);
  my $response = $self->{http}->request($method, "$url?$query", {
    headers => \%headers,
  });
  croak "$response->{status} $response->{reason}" unless $response->{success};
  $response->{content};
}

=head2 get_video

    my \%snippet = $api->get_video($video_id);

Retrieves a YouTube video resource, including the snippet, for the video given
by C<$video_id>. Croaks if no such video is found.

=cut

sub get_video {
  my ($self, $video_id) = @_;
  my $json = $self->request(
    'GET', '/videos',
    id   => $video_id,
    part => 'snippet',
  );
  my $obj = decode_json($json);
  my $item = $obj->{items}[0] or croak "no video with id $video_id";
  $item->{snippet};
}

=head1 AUTHOR

Aaron L. Zeng, C<< <me at bcc32.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-watchlater at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-WatchLater>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::WatchLater::YouTube


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-WatchLater>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-WatchLater>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-WatchLater>

=item * Search CPAN

L<http://search.cpan.org/dist/App-WatchLater/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Aaron L. Zeng.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.


=cut

1;                              # End of App::WatchLater::YouTube
