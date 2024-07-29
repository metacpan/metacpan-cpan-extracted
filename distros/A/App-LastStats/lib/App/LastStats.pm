use Feature::Compat::Class;

class App::LastStats {

  use strict;
  use warnings;
  no warnings 'experimental::class';
  use feature 'say';

  use Net::LastFM;
  use Getopt::Long;
  use JSON;

  our $VERSION = '0.0.2';

  field $username :param = 'davorg';
  field $period   :param = '7day';
  field $format   :param = 'text';
  field $count    :param = 10;
  field $lastfm   = Net::LastFM->new(
    api_key    => $ENV{LASTFM_API_KEY},
    api_secret => $ENV{LASTFM_SECRET},
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
      'user=s'   => \$username,
      'period=s' => \$period,
      'format=s' => \$format,
      'count=i'  => \$count,
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
    username => 'davorg',
    period   => '7day',
    format   => 'text',
    count    => 10,
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

=head1 AUTHOR

Dave Cross <dave@perlhacks.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
