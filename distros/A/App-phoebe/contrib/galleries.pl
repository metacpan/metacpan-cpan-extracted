# -*- mode: perl -*-
# Copyright (C) 2017–2020  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <https://www.gnu.org/licenses/>.

package App::Phoebe;
use Modern::Perl;

our (@extensions, $log);

# galleries

push(@extensions, \&galleries);

my $parent = "/home/alex/alexschroeder.ch/gallery";

sub gallery_title {
  my $dir = shift;
  $dir =~ s/-/ /g;
  return join(' ', map {ucfirst} split(' ', $dir));
}

sub galleries {
  my $stream = shift;
  my $url = shift;
  my $host = "alexschroeder.ch";
  my $port = port($stream);
  if ($url =~ m!^gemini://$host(?::$port)?/do/gallery$!) {
    success($stream);
    $log->info("Serving galleries");
    $stream->write("# Galleries\n");
    for my $dir (
      sort {
	my ($year_a, $title_a) = split(/-/, $a, 2);
	my ($year_b, $title_b) = split(/-/, $b, 2);
	return ($year_b <=> $year_a || $title_a cmp $title_b);
      } grep {
	-d "$parent/$_"
      } read_dir($parent)) {
      gallery_print_link($stream, "alexschroeder.ch", gallery_title($dir), "do/gallery/$dir");
    };
    return 1;
  } elsif (my ($dir) = $url =~ m!^gemini://$host(?::$port)?/do/gallery/([^/?]*)$!) {
    if (not -d "$parent/$dir") {
      $stream->write("40 This is not actuall a gallery\r\n");
      return 1;
    }
    if (not -r "$parent/$dir/data.json") {
      $stream->write("40 This gallery does not contain a data.json file like the one created by sitelen-mute or fgallery\r\n");
      return 1;
    }
    my $bytes = read_binary("$parent/$dir/data.json");
    if (not $bytes) {
      $stream->write("40 Cannot read the data.json file in this gallery\r\n");
      return 1;
    }
    my $data;
    eval { $data = decode_json $bytes };
    $log->error("decode_json: $@") if $@;
    if ($@ or not %$data) {
      $stream->write("40 Cannot decode the data.json file in this gallery\r\n");
      return 1;
    }
    success($stream);
    $log->info("Serving gallery $dir");
    if (-r "$parent/$dir/index.html") {
      my $dom = Mojo::DOM->new(read_text("$parent/$dir/index.html"));
      $log->info("Parsed index.html");
      my $title = $dom->at('*[itemprop="name"]');
      $title = $title ? $title->text : gallery_title($dir);
      $stream->write("# $title\n");
      my $description = $dom->at('*[itemprop="description"]');
      $stream->write($description->text . "\n") if $description;
      $stream->write("## Images\n");
    } else {
      $stream->write("# " . gallery_title($dir) . "\n");
    }
    for my $image (@{$data->{data}}) {
      $stream->write("\n");
      $stream->write(join("\n", grep /\S/, @{$image->{caption}}) . "\n") if $image->{caption};
      gallery_print_link($stream, "alexschroeder.ch", "Thumbnail", "do/gallery/$dir/" . $image->{thumb}->[0]);
      gallery_print_link($stream, "alexschroeder.ch", "Image", "do/gallery/$dir/" . $image->{img}->[0]);
    }
    return 1;
  } elsif (my ($file, $extension) = $url =~ m!^gemini://$host(?::$port)?/do/gallery/([^/?]*/(?:thumbs|imgs)/[^/?]*\.(jpe?g|png))$!i) {
    if (not -r "$parent/$file") {
      $stream->write("40 Cannot read $file\r\n");
    } else {
      success($stream, $extension =~ /^png$/i ? "image/png" : "image/jpg");
      $log->info("Serving image $file");
      print(read_binary("$parent/$file"));
    }
    return 1;
  }
  return;
}

sub gallery_print_link {
  my $stream = shift;
  my $host = shift;
  my $title = shift;
  my $id = shift;
  return print_link($stream, $host, undef, $title, $id);
}
