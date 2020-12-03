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
use MediaWiki::API;
use Text::SpanningTable;
use List::Util qw(sum min max);

our (@extensions, $server, $full_url_regex, $log);

# Wikipedia

push(@extensions, \&wikipedia);

my $link_regex = "([-,.()'%&!?;<> _1-9A-Za-z\x{0080}-\x{fffd}]|[-,.()'%&!?;<> _0-9A-Za-z\x{0080}-\x{fffd}][-,.()'#%&!?;<> _0-9A-Za-z\x{0080}-\x{fffd}]+)"; # disallow "0" and must match HTML and plain text (ie. > and &gt;)

sub wikipedia {
  my $stream = shift;
  my $url = shift;
  my $headers = shift;
  my $host = "vault.transjovian.org";
  my $port = port($stream);
  if ($url =~ m!^gemini://$host(?::$port)?/search/([a-z]+)/([^?;]+)!) {
    wikipedia_serve_search($stream, $1, decode_utf8(uri_unescape($2)));
  } elsif ($url =~ m!^gemini://$host(?::$port)?/text/([a-z]+)/([^?;]+)!) {
    wikipedia_serve_text($stream, $1, decode_utf8(uri_unescape($2)));
  } elsif ($url =~ m!^gemini://$host(?::$port)?/full/([a-z]+)/([^?;]+)!) {
    wikipedia_serve_full($stream, $1, decode_utf8(uri_unescape($2)));
  } elsif ($url =~ m!^gemini://$host(?::$port)?/raw/([a-z]+)/([^?;]+)!) {
    wikipedia_serve_raw($stream, $1, decode_utf8(uri_unescape($2)));
  } elsif ($url =~ m!^gemini://$host(?::$port)?/?$!) {
    $log->info("Asking for a language");
    $stream->write("10 Search in which language? (ar, cn, en, fr, ru, es, etc.)\r\n");
  } elsif ($url =~ m!^gemini://$host(?::$port)?/?\?([a-z]+)$!) {
    $log->info("Redirecting to ask for a term");
    my $lang = $1;
    $stream->write("30 gemini://$host:$port/$lang\r\n");
  } elsif ($url =~ m!^gemini://$host(?::$port)?/([a-z][a-z][a-z]?)$!) {
    $log->info("Asking for a term");
    my $lang = $1;
    $stream->write("10 Search term\r\n");
  } elsif ($url =~ m!^gemini://$host(?::$port)?/([a-z]+)\?([^?;]+)!) {
    $log->info("Redirecting to text");
    my $lang = $1;
    my $term = $2;
    $stream->write("30 gemini://$host:$port/search/$lang/$term\r\n");
  } elsif ($url =~ m!^gemini://$host(?::$port)?/robots\.txt$!) {
    $log->info("Serving robots.txt");
    success($stream, "text/plain");
    $stream->write("User-agent: *\n");
    $stream->write("Disallow: /\n");
  } elsif (my ($lang, $term) = $url =~ m!^GET /(?:search/|text/|full/)?(?:([a-z][a-z][a-z]?)/)?(.*) HTTP/1\.[01]$!
	   and ($host) = $headers->{host} =~ m!^$host(?::$port)?$!) {
    $lang ||= "www";
    my $url = "https://$lang.wikipedia.org/wiki/$term";
    $log->info("Redirecting to $url");
    $stream->write("HTTP/1.1 301 Back to Wikipedia!\r\n");
    $stream->write("Location: $url\r\n");
    $stream->write("Content-Type: text/plain\r\n");
    $stream->write("\r\n");
    $stream->write("See $url\n");
  } else {
    return 0;
  }
  return 1;
}

sub wikipedia_serve_search {
  my $stream = shift;
  my $lang = shift;
  my $term = shift;
  $log->info("Searching $lang/$term");
  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = "https://$lang.wikipedia.org/w/api.php";
  my $articles = $mw->list({
    action => 'query',
    list => 'prefixsearch',
    pssearch => $term, });
  if (not $articles) {
    $stream->write("43 Wikipedia says $mw->{error}->{code}: $mw->{error}->{details}\r\n");
    $stream->close_gracefully();
    return;
  }
  $stream->write("20 text/gemini;lang=$lang\r\n");
  $stream->write("# Searching for " . uri_unescape($term) . "\n");
  foreach (@$articles) {
    wikipedia_print_link($stream, $lang, $_->{title}, 'text', $_->{title});
  }
  $stream->write("\n\n");
  $stream->write("=> https://$lang.wikipedia.org/wiki/" . uri_escape_utf8($term) . " Source\n");
}

sub wikipedia_serve_raw {
  my $stream = shift;
  my $lang = shift;
  my $term = shift;
  $log->info("Getting $lang/$term");
  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = "https://$lang.wikipedia.org/w/api.php";
  my $result = $mw->api({
    action => 'parse',
    prop => 'wikitext',
    formatversion => '2',
    page => $term, });
  $stream->write("20 text/plain\r\n");
  $stream->write(encode_utf8 $result->{parse}->{wikitext});
}

sub wikipedia_print_link {
  my $stream = shift;
  my $lang = shift;
  my $term = shift;
  my $type = shift||"text";
  my $title = shift||$term;
  $stream->write("=> /$type/$lang/" . uri_escape_utf8($term) . " $title\n");
}

sub wikipedia_serve_text {
  my $stream = shift;
  my $lang = shift;
  my $term = shift;
  $log->info("Getting $lang/$term");
  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = "https://$lang.wikipedia.org/w/api.php";
  my $result = $mw->api({
    action => 'parse',
    prop => 'wikitext',
    formatversion => '2',
    page => $term, });
  $stream->write("20 text/gemini;lang=$lang\r\n");
  my $title = $result->{parse}->{title};
  my $text = wikipedia_extract($stream, $lang, $result->{parse}->{wikitext});
  $stream->write(encode_utf8 "# $title\n");
  $stream->write(encode_utf8 "$text\n\n");
  wikipedia_print_link($stream, $lang, $term, 'full', "Full text");
  wikipedia_print_link($stream, $lang, $term, 'raw', "Raw text");
  $stream->write("=> https://$lang.wikipedia.org/wiki/" . uri_escape_utf8($term) . " Source\n");
}

sub wikipedia_extract {
  my $stream = shift;
  my $lang = shift;
  my $text = shift;
  my @sections = split(/\n+==.*==\n+/, $text);
  return wikipedia_text($stream, $lang, $sections[0]);
}

sub wikipedia_text {
  my $stream = shift; # only used to pass to gemini_link for the port
  my $lang = shift;
  my $text = shift;
  # escape some stuff
  my $ref = 0;
  my @escaped;
  # main articles and other templates
  $text =~ s/^\{\{\s*main\s*\|(.+?)\}\}/push(@escaped, gemini_link($stream, "vault.transjovian.org", undef, "Main article: $1", "text\/$lang\/$1")); "\x03" . $ref++ . "\x04\n"/simeg;
  # e.g. gemini://vault.transjovian.org/text/en/Zuihitsu
  $text =~ s/\{\{\s*nihongo\s*\|(.+?)\|(.+?)\}\}/$1 ($2)/sig;
  # strip citations
  $text =~ s/\{\{\s*cite\s+[^{}]+\}\}//sig;
  # handle quotes (now without the citations)
  $text =~ s/\{\{\s*quote\s*\|(?:text=)?(.+?)\}\}/｢$1｣/sig;
  # strip all other templates
  do {} while $text =~ s/\{\{[^{}]+\}\}//g;
  # strip remaining empty brackets
  $text =~ s/\(\s*\)//g;
  # handle tables
  $text =~ s/^(\{\|.+?\|\})\n?/push(@escaped, wikipedia_table($1)); "\x03" . $ref++ . "\x04"/mesg;
  my @blocks = split(/\n\n+|\n(?=[*#=])|<br\s+\/>/, $text);
    for my $block (@blocks) {
    $block =~ s/\s+/ /g; # unwrap lines
    $block =~ s/^\s+//; # trim
    $block =~ s/\s+$//; # trim
    $block = wikipedia_format($block);
  }
  $text = join("\n\n", @blocks);
  # replace the preformatted blocks
  $text =~ s/\x03(\d+)\x04/$escaped[$1]/g;
  return $text;
}

sub wikipedia_table {
  my $text = shift;
  my $caption = "";
  my $data;
  my @row;
  $log->debug("Parsing table");
  for (split(/\n/, $text)) {
    if (/^\{\|.*/) { $log->debug("start of table"); }
    elsif (/^\|\+\s*(.*)/) { $log->debug("caption"); $caption = $1 . "\n" }
    elsif (/^\|-\s*/) { $log->debug("new row"); push(@$data, [@row]) if @row; @row = () }
    elsif (/^!\s*(.*)/) { $log->debug("new header"); push(@row, split(/!!/, $1)) }
    elsif (/^\|\s*(.*)/) { $log->debug("new cell"); push(@row, split(/\|\|/, $1)) }
    elsif (/^\|\}/) { $log->debug("end of table"); push(@$data, [@row]) if @row }
  }
  my $width = wikipedia_process($data);
  my $total = sum(@$width);
  my @cols = map { min(30, max(8, int($_ * 120 / $total))) } @$width;
  $log->debug("Column widths: @cols");
  eval {
    my $t = Text::SpanningTable->new(@cols);
    $t->newlines(1);
    for my $row (@$data) {
      $t->row(@$row);
    }
    $text = $caption . $t->draw;
  };
  $log->debug("Table done $@");
  return "```\n$text\n```\n";
}

sub wikipedia_process {
  my $data = shift;
  my @width; # width of each column
  my $r = 0;
  for my $row (@$data) {
    $log->debug("Processing row: @$row");
    my $i = 0;
    for my $cell (@$row) {
      $i++, next unless $cell;
      my ($attributes, $text);
      if ($cell =~ /^((?:\s*[a-z-]+=(?:"[^"\n]+"|\w+))*)\s*\|\s*(.*)/) {
	($attributes, $text) = ($1, $2);
      } else {
	($attributes, $text) = ("", $cell);
      }
      $text = wikipedia_format($text);
      $i++, next unless $text;
      $log->debug("Processing cell '$cell' to '$text'");
      my $width = max(map { length } split/\n/, $text);
      $log->warn("'$text' of '$cell' has no width") unless $width;
      $width[$i] = $width if not $width[$i] or $width > $width[$i];
      if ($attributes =~ /colspan=(?:"(\d+)"|(\d))/) {
	$text = [$1||$2, $text];
	# $width[$i] = 0;
      } else {
	$text = [1, $text];
      }
      if ($attributes =~ /rowspan="(\d+)"/) {
	$log->debug("Rowspan $1 starting at (row $r, col $i)");
	for my $n (1 .. $1 - 1) {
	  last if $r + $n > $#$data;
	  splice(@{$data->[$r + $n]}, $i, 0, "");
	}
      }
      $cell = $text;
      $i++;
    }
    $r++;
  }
  $log->debug("Max column width: @width");
  return \@width;
}

sub wikipedia_format {
  my $text = shift;
  $text =~ s/<(ref|gallery)(?:\s+[a-z-]+=(?:"[^"\n]+"|\w+))*>.*<\/\1>//g;
  $text =~ s/<[a-z]+(?:\s+[a-z-]+=(?:"[^"\n]+"|\w+))*\s*\/?>//g;
  $text =~ s/<\/[a-z]+>//g;
  $text =~ s/(={1,6})(.+?)\1 */("#" x length($1)) . " $2\n\n"/ge;
  $text =~ s/'''([^'\n]+)'''/**$1**/g;
  $text =~ s/''([^'\n]+)''/*$1*/g;
  $text =~ s/\[$full_url_regex ([^]]+)\]/$2/g;
  $text =~ s/\[\[$link_regex\|([^\]|]+)\]\]/$2/g;
  $text =~ s/\[\[$link_regex\]\]/$1/g;
  $text =~ s/\[\[(?:File|Image|Category):.*?\]\] *//g;
  $text =~ s/&nbsp;/ /g;
  return $text;
}

sub wikipedia_serve_full {
  my $stream = shift;
  my $lang = shift;
  my $term = shift;
  $log->info("Serving full $lang/$term");
  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = "https://$lang.wikipedia.org/w/api.php";
  my $result = $mw->api({
    action => 'parse',
    prop => 'wikitext',
    formatversion => '2',
    page => $term, });
  $stream->write("20 text/gemini;lang=$lang\r\n");
  my $title = $result->{parse}->{title};
  my $text = wikipedia_text($stream, $lang, $result->{parse}->{wikitext});
  $stream->write(encode_utf8 "# $title\n");
  $stream->write(encode_utf8 "$text\n\n");
  wikipedia_print_link($stream, $lang, $term, 'text', "Short text");
  $stream->write("=> https://$lang.wikipedia.org/wiki/" . uri_escape_utf8($term) . " Source\n");
}
