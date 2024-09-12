# Copyright (C) 2024  Alex Schroeder <alex@gnu.org>
#
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
# with this program. If not, see <http://www.gnu.org/licenses/>.

=head1 NAME

App::BookmarkFeed - Create a RSS feed from Markdown files

=head1 SYNOPSIS

    use App::BookmarkFeed;
    App::BookmarkFeed::main(@ARGV);

=head1 DESCRIPTION

The bookmark-feed turns external links in a bunch of Markdown pages into a RSS
feed.

The arguments are all file names. All but the last file are existing Markdown
files to be checked for new links. The last file is the resulting feed file. It
is overwritten.

=head1 SEE ALSO

L<bookmark-feed> documents the details of how the Markdown pages are processed.

=head1 REFERENCES

L<RSS 2.0 Specification|https://cyber.harvard.edu/rss/rss.html>

=cut

package App::BookmarkFeed;

our $VERSION = 1.01;

use v5.36;
use File::Basename;
use File::Spec;
use Mojo::SQLite;
use Mojo::Template;
use File::Slurper qw(read_text write_text);
use CommonMark qw(:node :event);
use DateTime;
use DateTime::Format::ISO8601;

sub main (@files) {
  my $feed_file = pop(@files);
  die "Usage:\nbookmark-feed markdown-files... feed-file\n" unless @files;
  my ($filename, $dirs, $suffix) = fileparse($feed_file, ".rss", ".xml");
  my $db_file = File::Spec->catfile($dirs, $filename . ".db");
  my $sql = Mojo::SQLite->new("sqlite:$db_file");
  $sql->migrations->from_data->migrate;
  my $db = $sql->db;
  for (@files) { die "$_ is not readable\n" unless -r $_ }
  my @items;
  for my $file (@files) {
    my $dt = DateTime->from_epoch(epoch => (stat($file))[9]);
    my $md = read_text($file);
    my $parser = CommonMark::Parser->new;
    $parser->feed($md);
    my $doc = $parser->finish;
    push(@items, to_items($doc, $dt));
  }
  update($db, @items);
  write_feed($db, $feed_file);
}

sub to_items ($doc, $dt) {
  my $iter = $doc->iterator;
  my @items;
  while (my ($ev_type, $node) = $iter->next) {
    if ($node->get_type == NODE_LINK) {
      if ($ev_type == EVENT_ENTER) {
        if ($node->get_url =~ /^(https?|gemini|gopher):/) {
          my $last = $node->parent->last_child;
          # links in a paragraph that end in a colon are skipped
          next if $last->get_type == NODE_TEXT and $last->get_literal =~ /:$/;
          push(@items, to_item($node, $dt));
        }
      }
    }
  }
  return @items;
}

# An item is a hash with keys url, title, description; url and title are plain
# text, description is HTML.
sub to_item ($node, $dt) {
  my $item = {
    url => $node->get_url,
    date => $dt,
  };
  my $child = $node->first_child;
  if ($child && $child->get_type == NODE_TEXT) {
    $item->{title} = $child->get_literal;
  }
  while ($node = $node->parent) {
    my $node_type = $node->get_type;
    if ($node_type == NODE_PARAGRAPH
        || $node_type == NODE_BLOCK_QUOTE
        || $node_type == NODE_ITEM) {
      my $html = $node->render_html;
      $item->{description} = $html;
      last;
    }
  }
  return $item
}

sub update ($db, @items) {
  for my $item (@items) {
    if ($db->query('select 1 from items where url = ?', $item->{url})->hash) {
      delete $item->{date};
      $db->update('items', $item, {url => $item->{url}});
    } else {
      $db->insert('items', $item);
    }
  }
}

sub write_feed ($db, $feed_file) {
  my $mt = Mojo::Template->new(vars => 1);
  my $items = $db->select('items',
                          [qw(date url title description)],
                          { },
                          {
                            order_by => {-desc => 'date'},
                            limit => 40,
                          })->hashes;
  $_->{date} = DateTime::Format::ISO8601
      ->parse_datetime($_->{date})
      ->strftime("%a, %d %b %Y %H:%M:%S %z")
      for @$items;
  my $feed = $mt->render(<<'EOT', { items => $items});
<rss version="2.0">
  <channel>
    <docs>http://blogs.law.harvard.edu/tech/rss</docs>
    <title>Bookmarks</title>
% for my $item (@$items) {
    <item>
      <title><%== $item->{title} %></title>
      <link><%= $item->{url} %></link>
      <guid><%= $item->{url} %></guid>
      <description><%== $item->{description} %></description>
      <pubDate><%= $item->{date} %></pubDate>
    </item>
% }
  </channel>
</rss>
EOT
  write_text($feed_file, $feed);
}

1;

__DATA__
@@ migrations
-- 1 up
create table items (date date, url text, title text, description text);
-- 1 down
drop table urls;
