package CheerLights::API;

use strict;
use warnings;
use LWP::UserAgent;
use JSON;
use Exporter 'import';

our @EXPORT_OK = qw(
    get_current_color
    get_current_hex
    get_current_color_name
    get_color_history
    color_name_to_hex
    hex_to_rgb
    is_valid_color
);

our $VERSION = '1.00';

my $CHEERLIGHTS_FEED_URL = "https://api.thingspeak.com/channels/1417/feed.json";

sub get_current_color {
    my $url = "$CHEERLIGHTS_FEED_URL?results=1";
    my $response = _fetch_url($url);
    return unless $response;

    my $data = decode_json($response);
    my $color_name = $data->{feeds}[0]{field1};
    my $hex_code = $data->{feeds}[0]{field2};

    return {
        color => $color_name,
        hex => $hex_code
    };
}

sub get_current_hex {
    my $color_data = get_current_color();
    return $color_data ? $color_data->{hex} : undef;
}

sub get_current_color_name {
    my $color_data = get_current_color();
    return $color_data ? $color_data->{color} : undef;
}

sub get_color_history {
    my ($count) = @_;
    $count ||= 10;  # Default count to 10 if not provided
    my $url = "$CHEERLIGHTS_FEED_URL?results=$count";
    my $response = _fetch_url($url);
    return unless $response;

    my $data = decode_json($response);
    my @feeds = @{$data->{feeds}};
    my @history;

    foreach my $entry (@feeds) {
        push @history, {
            color => $entry->{field1},
            hex => $entry->{field2},
            timestamp => $entry->{created_at}
        };
    }

    return \@history;
}

sub color_name_to_hex {
    my ($color_name) = @_;
    my %color_map = (
        red       => '#FF0000',
        green     => '#00FF00',
        blue      => '#0000FF',
        cyan      => '#00FFFF',
        white     => '#FFFFFF',
        warmwhite => '#FDF5E6',
        purple    => '#800080',
        magenta   => '#FF00FF',
        yellow    => '#FFFF00',
        orange    => '#FFA500',
        pink      => '#FFC0CB',
        oldlace   => '#FDF5E6',
    );

    return $color_map{lc $color_name};
}

sub hex_to_rgb {
    my ($hex_code) = @_;
    $hex_code =~ s/^#//;  # Remove the leading '#'
    return map { hex($_) } ($hex_code =~ /(..)(..)(..)/);
}

sub is_valid_color {
    my ($color_name) = @_;
    my @valid_colors = qw(
        red green blue cyan white warmwhite
        purple magenta yellow orange pink oldlace
    );

    return grep { $_ eq lc $color_name } @valid_colors;
}

# Private function to fetch the content from a URL
sub _fetch_url {
    my ($url) = @_;
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get($url);

    if ($response->is_success) {
        return $response->decoded_content;
    } else {
        warn "Failed to fetch URL: " . $response->status_line;
        return;
    }
}

1;  # Ensure the module returns a true value

__END__

=head1 NAME

CheerLights::API - A Perl module for accessing the CheerLights API.

=head1 SYNOPSIS

  use CheerLights::API qw(get_current_color get_current_hex get_color_history);

  my $current_color = get_current_color();
  print "Current color: $current_color->{color}, Hex: $current_color->{hex}\n";

  my $hex = get_current_hex();
  print "Current hex color: $hex\n";

  my $history = get_color_history(5);
  foreach my $entry (@$history) {
      print "Color: $entry->{color}, Hex: $entry->{hex}, Timestamp: $entry->{timestamp}\n";
  }

=head1 DESCRIPTION

This module provides functions for interacting with the CheerLights API, allowing you to get the current color, its history, and more.

=head1 FUNCTIONS

=head2 get_current_color

=head2 get_current_hex

=head2 get_current_color_name

=head2 get_color_history

=head2 color_name_to_hex

=head2 hex_to_rgb

=head2 is_valid_color

=head1 AUTHOR

Hans Scharler <hans@nothans.com>

=head1 COPYRIGHT AND LICENSE

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
