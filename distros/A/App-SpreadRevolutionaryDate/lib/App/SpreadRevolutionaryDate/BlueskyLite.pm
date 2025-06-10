#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2025 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.014;
use utf8;
package App::SpreadRevolutionaryDate::BlueskyLite;
$App::SpreadRevolutionaryDate::BlueskyLite::VERSION = '0.51';
# ABSTRACT: Simple Class to post status to BlueSky.

use LWP::UserAgent;
use DateTime;
use JSON qw(encode_json decode_json);
use URI;
use Encode qw(decode_utf8);
use File::Type;
use File::Basename;

use namespace::autoclean;

sub _fetch_embed_url_card {
  my $self = shift;
  my $url = shift || return;

  my $card = {uri => $url};

  my $ua = LWP::UserAgent->new(env_proxy => 1, timeout => 10, agent =>'App::SpreadRevolutionaryDate bot');
  my $response = $ua->get($url);
  return unless $response->is_success;
  my $content = $response->content;
  return unless $content;

  if ($content =~ /<meta\s+property="og:title"\s+content="([^"]+)"/) {
    my $title = $1;
    ($card->{title}) = decode_utf8($title);
  } else {
    $card->{title} = '';
  }
  if ($content =~ /<meta\s+property="og:description"\s+content="([^"]+)"/) {
    my $description = $1;
    ($card->{description}) = decode_utf8($description);
  } else {
    $card->{description} = '';
  }
  if ($content =~ /<meta\s+property="og:image"\s+content="([^"]+)"/) {
    my $img_url = $1;
    unless ($img_url =~ m!://!) {
      $url = "$url/" unless $url =~ m!/$!;
      $img_url = $url . $img_url;
    }
    my $img_response = $ua->get($img_url);
    return unless $img_response->is_success;

    my $blob_req = HTTP::Request->new('POST', 'https://bsky.social/xrpc/com.atproto.repo.uploadBlob');
    $blob_req->header('Content-Type' => $img_response->header('Content-Type'));
    $blob_req->content($img_response->content);
    my $blob_response = $self->{ua}->request($blob_req);
    return unless $blob_response->is_success;

    my $blob_content = decode_json($blob_response->decoded_content);
    ($card->{thumb}) = $blob_content->{blob};
  }

  return $card;
}

sub _lookup_repo {
  my $self = shift;
  my $account = shift || return;
  $account .= '.bsky.social' unless $account =~ /[⋅]/;
  my $uri = URI->new('https://bsky.social/xrpc/com.atproto.identity.resolveHandle');
  $uri->query_form(handle => $account);
  my $response = $self->{ua}->get($uri);
  return if !$response->is_success;

  my $content = decode_json($response->decoded_content);
  return $content->{did};
}

sub _generate_facets {
  my $self = shift;
  my $text = shift || return;
  my $facets = [];
  my $embed;
  my $pos = 0;
  foreach my $w (split /\s+/, $text) {
    my ($type, $attrib, $val);
    $w =~ s/[.,:;'"!\?()]+$//;
    $w =~ s/^[.,:;'"!\?()]+//g;
    if ($w =~ /^https?\:\/\//) {
      $type = 'app.bsky.richtext.facet#link';
      $attrib = 'uri';
      $val = $w;
    } elsif ($self->{did} && $w =~ /^@/) {
      $val = $self->_lookup_repo(substr($w, 1));
      if (defined $val) {
        $type = 'app.bsky.richtext.facet#mention';
        $attrib = 'did';
      }
    } elsif ($w =~ /^#/) {
      $val = substr($w, 1);
      if (defined $val) {
        $type = 'app.bsky.richtext.facet#tag';
        $attrib = 'tag';
      }
    }

    if (defined $type) {
      utf8::encode(my $text_bytes = $text);
      $pos = index($text_bytes, $w, $pos);
      my $end = $pos + length($w);

      push @$facets, {
        features => [
          {
            '$type' => $type,
            $attrib => $val,
          },
        ],
        index => {
          byteStart => $pos,
          byteEnd   => $end,
        },
      };

      unless ($embed) {
        my $card = $self->_fetch_embed_url_card($val);
        if ($card) {
          $embed = {
                '$type'    => 'app.bsky.embed.external',
                'external' => $card,
          };
        }
      }

      $pos = $end;
    }
  }
  return ($facets, $embed);
}


sub new {
  my ($class, %args) = @_;

  my %self;
  $self{ua} = LWP::UserAgent->new(env_proxy => 1, timeout => 10, agent =>'App::SpreadRevolutionaryDate bot');
  $self{ua}->default_header('Accept' => 'application/json');

  my %payload = (
    identifier => $args{'identifier'},
    password   => $args{'password'},
  );
  my $json = encode_json(\%payload);

  my $req = HTTP::Request->new('POST', 'https://bsky.social/xrpc/com.atproto.server.createSession');
  $req->header('Content-Type' => 'application/json');
  $req->content($json);
  my $response = $self{ua}->request($req);

  if ($response->is_success) {
    my $content = decode_json($response->decoded_content);
    my $did = $content->{did};
    my $access_jwt = $content->{accessJwt};
    $self{ua}->default_header('Authorization' => 'Bearer ' . $access_jwt);
    $self{did} = $did;
  }

  my $self = bless(\%self, $class);
  return $self;
}


sub create_post {
  my ($self, $text, $img, $reply) = @_;

  my ($facets, $embed) = $self->_generate_facets($text);
  my $payload = {
    repo => $self->{did},
    collection => 'app.bsky.feed.post',
    record => {
      text => $text,
      facets => $facets,
      ($embed ?
        (embed => $embed)
        : ()
      ),
      createdAt => DateTime->now->iso8601 . 'Z',
    },
  };

  if ($img) {
    $img = {path => $img} unless ref($img) && ref($img) eq 'HASH' && $img->{path};
    my $ft = File::Type->new();
    my $mime_type = $ft->mime_type($img->{path});

    my $img_alt = $img->{alt} // ucfirst(fileparse($img->{path}, qr/\.[^.]*/));

    my $img_bytes;
    open my $fh, '<', $img->{path} or die "Cannot read $img->{path}: $!\n";
    {
        local $/;
        $img_bytes = <$fh>;
    }
    close $fh;

    my $blob_req = HTTP::Request->new('POST', 'https://bsky.social/xrpc/com.atproto.repo.uploadBlob');
    $blob_req->header('Content-Type' => $mime_type);
    $blob_req->content($img_bytes);
    my $blob_response = $self->{ua}->request($blob_req);
    return unless $blob_response->is_success;

    my $blob_content = decode_json($blob_response->decoded_content);
    $payload->{record}->{embed} = {
        '$type'    => 'app.bsky.embed.images',
        images => [
            {
                alt => $img_alt,
                image => $blob_content->{blob},
            },
        ],
    };
  }

  if ($reply) {
      $payload->{record}->{reply} = $reply;
  }

  my $json = encode_json($payload);
  my $req = HTTP::Request->new('POST', 'https://bsky.social/xrpc/com.atproto.repo.createRecord');
  $req->header('Content-Type' => 'application/json');
  $req->content($json);
  my $response = $self->{ua}->request($req);
  if ($response->is_success) {
      return decode_json($response->decoded_content);
  } else {
      return $response;
  }
}


# A module must return a true value. Traditionally, a module returns 1.
# But this module is a revolutionary one, so it discards all old traditions.
# Idea borrowed from Jean Forget's DateTime::Calendar::FrenchRevolutionary.
"Quand le gouvernement viole les droits du peuple,
l'insurrection est pour le peuple le plus sacré
et le plus indispensable des devoirs";

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SpreadRevolutionaryDate::BlueskyLite - Simple Class to post status to BlueSky.

=head1 VERSION

version 0.51

=head1 Methods

=head2 new

Constructor class method. Takes identifier and passwords mandatory arguments. Returns an C<App::SpreadRevolutionaryDate::BlueskyLite> object.

=head2 create_post

Creates a Bluesky post.

=head1 SEE ALSO

=over

=item L<spread-revolutionary-date>

=item L<App::SpreadRevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::Target>

=item L<App::SpreadRevolutionaryDate::Target::Bluesky>

=item L<App::SpreadRevolutionaryDate::Target::Twitter>

=item L<App::SpreadRevolutionaryDate::Target::Mastodon>

=item L<App::SpreadRevolutionaryDate::Target::Freenode>

=item L<App::SpreadRevolutionaryDate::Target::Freenode::Bot>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat>

=item L<App::SpreadRevolutionaryDate::Target::Liberachat::Bot>

=item L<App::SpreadRevolutionaryDate::MsgMaker>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Calendar>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::fr>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::en>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::it>

=item L<App::SpreadRevolutionaryDate::MsgMaker::RevolutionaryDate::Locale::es>

=item L<App::SpreadRevolutionaryDate::MsgMaker::PromptUser>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Telechat>

=item L<App::SpreadRevolutionaryDate::MsgMaker::Gemini>

=back

=head1 AUTHOR

Gérald Sédrati <gibus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2025 by Gérald Sédrati.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
