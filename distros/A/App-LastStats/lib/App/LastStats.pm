use Feature::Compat::Class;

package App::LastStats; # For MetaCPAN

class App::LastStats {

  use strict;
  use warnings;
  use feature 'say';

  no if $^V >= v5.38, warnings => 'experimental::class';

  use Net::LastFM;
  use Getopt::Long;
  use JSON;

  our $VERSION = '0.0.8';

  field $username   :param = 'davorg';
  field $period     :param = '7day';
  field $format     :param = 'text';
  field $count      :param = 10;
  field $api_key    :param = $ENV{LASTFM_API_KEY};
  field $api_secret :param = $ENV{LASTFM_API_SECRET};
  field $lastfm     = Net::LastFM->new(
    api_key    => $api_key,
    api_secret => $api_secret,
  );
  field $method   = 'user.getTopArtists';
  field $data;
  field @artists;

  field $renderer = {
    text => \&render_text,
    html => \&render_html,
    json => \&render_json,
  };

  method run {
    GetOptions(
      'user=s'      => \$username,
      'period=s'    => \$period,
      'format=s'    => \$format,
      'count=i'     => \$count,
      'api-key=s'   => \$api_key,
      'api-secret=s'=> \$api_secret,
    );

    $self->validate;
    $self->laststats;
    $self->render;
  }

  method validate {
    $period = lc $period;
    $format = lc $format;

    my @valid_periods = qw(overall 7day 1month 3month 6month 12month);
    unless (grep { $_ eq $period } @valid_periods) {
      die "Invalid period: $period\n";
    }

    unless (exists $renderer->{$format}) {
      die "Invalid format: $format\n";
    }
  }

  method render_text {
    say "* $_->{name} ($_->{playcount})" for @artists;
  }

  method render_json {
    my $pos = 1;

    my @data = map { {
      position => $pos++,
      name     => $_->{name},
      count    => $_->{playcount},
    } } @artists;
    say JSON->new->canonical(1)->encode(\@data);
  }

  method render_html {
    my $html = "<ol>\n";
    $html .= "  <li>$_->{name} ($_->{playcount})</li>\n" for @artists;
    $html .= "</ol>";
    say $html;
  }

  method render {
    my $method = $renderer->{$format};
    $self->$method;
  }

  method laststats {
    my $page = 1;

    while (@artists < $count) {

      $data = $lastfm->request_signed(
        method => $method,
        user   => $username,
        period => $period,
        limit  => $count,
        page   => $page++,
      );

      last unless @{$data->{topartists}{artist}};

      push @artists, @{$data->{topartists}{artist}};
    }

    $#artists = $count - 1 if @artists > $count;
  }
}

1;

__END__

=head1 NAME

App::LastStats - A module to fetch and display Last.fm statistics

=head1 SYNOPSIS

  use App::LastStats;

  my $stats = App::LastStats->new(
    username   => 'davorg',
    period     => '7day',
    format     => 'text',
    count      => 10,
    api_key    => 'your_api_key',
    api_secret => 'your_api_secret',
  );

  $stats->run;

=head1 DESCRIPTION

App::LastStats is a module that fetches and displays Last.fm statistics for a given user. It allows you to specify the time period, format, and number of artists to display.

=head1 METHODS

=head2 run

Fetches and displays the Last.fm statistics based on the provided options.

=head2 validate

Validates the provided options.

=head2 render_text

Renders the statistics in plain text format.

=head2 render_json

Renders the statistics in JSON format.

=head2 render_html

Renders the statistics in HTML format.

=head2 render

Renders the statistics using the specified format.

=head2 laststats

Fetches the Last.fm statistics for the specified user and time period.

=head1 API

You will need an API key and secret in order to use this program. You can
get these from L<https://www.last.fm/api/account/create>.

The API key and secret can be passed as arguments to the constructor (as
in the sample code above). Alternatively, they can be read from
environment variables called C<LASTFM_API_KEY> and C<LASTFM_API_SECRET>.

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
