# -*- mode: perl -*-
# Copyright (C) 2017–2021  Alex Schroeder <alex@gnu.org>

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

=encoding utf8

=head1 NAME

App::Phoebe::Oddmuse - act as a Gemini proxy for an Oddmuse wiki

=head1 DESCRIPTION

This extension allows you to serve files from an Oddmuse wiki instead of a real
Phoebe wiki directory.

The tricky part is that most Oddmuse wikis don't use Gemini markup (“gemtext”)
and therefore care is required. The extension tries to transmogrify typical
Oddmuse markup (based on my own wikis) to Gemini.

Here's one way to configure it. I use Apache as my proxy server and have
multiple Oddmuse wikis running on the same machine, each only serving
C<localhost>. I need to recreate some of the Apache configuration, here.

    package App::Phoebe::Oddmuse;

    our %oddmuse_wikis = (
      "alexschroeder.ch" => "http://localhost:4023/wiki",
      "communitywiki.org" => "http://localhost:4019/wiki",
      "emacswiki.org" => "http://localhost:4002/wiki",
      "campaignwiki.org" => "http://localhost:4004/wiki", );

    our %oddmuse_wiki_names = (
      "alexschroeder.ch" => "Alex Schroeder",
      "communitywiki.org" => "Community Wiki",
      "emacswiki.org" => "Emacs Wiki",
      "campaignwiki.org" => "Campaign Wiki", );

    our %oddmuse_wiki_dirs = (
      "alexschroeder.ch" => "/home/alex/alexschroeder",
      "communitywiki.org" => "/home/alex/communitywiki",
      "emacswiki.org" => "/home/alex/emacswiki",
      "campaignwiki.org" => "/home/alex/campaignwiki", );

    our %oddmuse_wiki_links = (
      "communitywiki.org" => 1,
      "campaignwiki.org" => 1, );

    use App::Phoebe::Oddmuse;

=cut

package App::Phoebe::Oddmuse;
use App::Phoebe qw(@request_handlers @extensions @main_menu $server $log $full_url_regex
		   success result reserved_regex port gemini_link modified changes diff
		   colourize quote_html bogus_hash print_link decode_query);
use Mojo::UserAgent;
use Modern::Perl;
use MIME::Base64;
use URI::Escape;
use List::Util qw(uniq);
use File::Slurper qw(read_dir read_text write_text);
use Encode qw(encode_utf8 decode_utf8);
use DateTime::Format::ISO8601;
use utf8; # the source contains UTF-8 encoded strings
no warnings 'redefine';

# Oddmuse Wiki

our %oddmuse_wikis = (
  "alexschroeder.ch" => "http://localhost:4023/wiki",
  "communitywiki.org" => "http://localhost:4019/wiki",
  "emacswiki.org" => "http://localhost:4002/wiki" );

our %oddmuse_wiki_names = (
  "alexschroeder.ch" => "Alex Schroeder",
  "communitywiki.org" => "Community Wiki",
  "emacswiki.org" => "Emacs Wiki" );

our %oddmuse_wiki_dirs = (
  "alexschroeder.ch" => "/home/alex/alexschroeder",
  "communitywiki.org" => "/home/alex/communitywiki",
  "emacswiki.org" => "/home/alex/emacswiki" );

# The Oddmuse wiki uses WikiLinks
our %oddmuse_wiki_links = ("communitywiki.org" => 1);

# The Oddmuse wiki uses a different token as the answer to a security question
# (i.e. not the Phoebe server token). This only works if the Oddmuse wiki has
# just one security question (or accepts the same answer for all questions).
our %oddmuse_wiki_tokens = (
  "emacswiki.org" => "emacs" );

# Also allow percent encoded…
our $oddmuse_namespace_regex = '[\p{Uppercase}\d][%\w_  ]*';

*oddmuse_old_space_regex = \&App::Phoebe::space_regex;
*App::Phoebe::space_regex = \&oddmuse_new_space_regex;

sub oddmuse_new_space_regex {
  my $spaces = oddmuse_old_space_regex();
  return "$spaces|$oddmuse_namespace_regex" if $spaces;
  return $oddmuse_namespace_regex;
}

*oddmuse_old_space = \&App::Phoebe::space;
*App::Phoebe::space = \&oddmuse_new_space;

sub oddmuse_new_space {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  if (grep { $_ eq $host } keys %oddmuse_wikis) {
    # Let Oddmuse handle namespaces
    return $space;
  }
  return oddmuse_old_space($stream, $host, $space);
}

*oddmuse_old_save_page = \&App::Phoebe::save_page;
*App::Phoebe::save_page = \&oddmuse_new_save_page;

sub oddmuse_new_save_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $type = shift;
  my $data = shift;
  my $length = shift;
  my $port = port($stream);
  if (not grep { $_ eq $host } keys %oddmuse_wikis) {
    return oddmuse_old_save_page($stream, $host, $space, $id, $type, $data, $length);
  }
  if ($type ne "text/plain") {
    $data = "#FILE $type\n" . encode_base64($data);
  } elsif (not utf8::decode($data)) {
    $log->debug("The text is invalid UTF-8");
    result($stream, "59", "The text is invalid UTF-8");
    $stream->close_gracefully();
    return;
  }
  my @tokens = @{$server->{wiki_token}};
  push(@tokens, $oddmuse_wiki_tokens{$host}) if $oddmuse_wiki_tokens{$host};
  my $token = pop(@tokens); # the oddmuse wiki token, preferrably
  my $name = ref($stream->handle) eq 'IO::Socket::SSL' && $stream->handle->peer_certificate('cn') || "";
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->post(
    $oddmuse_wikis{$host}
    => {'X-Forwarded-For' => $stream->handle->peerhost}
    => form => {
      title => $id,
      text => $data,
      ns => $space,
      answer => $token,
      username => $name,
      gemini => 1 });
  $log->debug("Got " . $tx->result->code . " response");
  if ($tx->result->code == 302) {
    my $url = "gemini://$host:$port";
    $url .= "/$space" if $space;
    result($stream, "30", "$url/page/" . uri_escape_utf8($id) . "");
  } else {
    $stream->write("59 Got HTTP code " . $tx->result->code . " " . $tx->result->message
		   . " (" . $tx->req->url->to_abs . " " . $tx->req->params . ")\r\n");
  }
  $stream->close_gracefully();
}

*oddmuse_old_valid_token = \&App::Phoebe::valid_token;
*App::Phoebe::valid_token = \&oddmuse_new_valid_token;

sub oddmuse_new_valid_token {
  my ($stream, $host, $space, $id, $params) = @_;
  my $token = $params->{token}||"";
  if ($oddmuse_wiki_tokens{$host}) {
    $log->debug("Comparing $token with $oddmuse_wiki_tokens{$host}");
  } else {
    $log->debug("There is no specific token for this Oddmuse wiki");
  }
  return 1 if $oddmuse_wiki_tokens{$host} and $oddmuse_wiki_tokens{$host} eq $token;
  return oddmuse_old_valid_token(@_);
}

push(@extensions, \&oddmuse_process_request);

sub oddmuse_process_request {
  my $stream = shift;
  my $url = shift;
  my $headers = shift;
  my $hosts = "(" . join("|", keys %oddmuse_wikis) . ")";
  my $spaces = $oddmuse_namespace_regex;
  my $reserved = reserved_regex();
  my $port = port($stream);
  my ($host, $space, $id, $query, $n, $style, $token);
  if ($url =~ m!^gemini://$hosts(?::$port)?/robots\.txt$!) {
    # must come before redirection to regular pages since it contains no slash
    oddmuse_serve_robots($stream);
  } elsif (($host, $n, $space) = $url =~ m!^gemini://$hosts(:$port)?(?:/($spaces))?/(?:$reserved)$!) {
    result($stream, "31", "gemini://$host" . ($n ? ":$port" : "") . "/" . ($space ? $space : "") . ""); # this supports "up"
  } elsif (($host, $space, $id, $n) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/page/([^/]+)(?:/(\d+))?$!
	   and $id ne $server->{wiki_main_page}) {
    oddmuse_serve_page($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))), $n);
  } elsif (($host, $space, $id) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/tag/([^/]+)$!) {
    oddmuse_serve_tag($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))));
  } elsif (($host, $space, $id) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/raw/([^/]+)$!
	   and $id ne $server->{wiki_main_page}) {
    oddmuse_serve_raw($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))));
  } elsif (($host, $space, $id) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/html/([^/]+)$!) {
    oddmuse_serve_html($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))));
  } elsif (($host, $space, $n) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/(?:blog|more)(?:/(\d+))?$!) {
    oddmuse_serve_blog($stream, $host, decode_utf8(uri_unescape($space)), $n||10);
  } elsif (($host, $space, $n) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/index$!) {
    oddmuse_serve_index($stream, $host, decode_utf8(uri_unescape($space)));
  } elsif (($host, $space, $n, $style) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
    oddmuse_serve_changes($stream, $host, decode_utf8(uri_unescape($space)), $n||3, $style); # days!
  } elsif (($host, $n, $style) = $url =~ m!^gemini://$hosts(?::$port)?/do/all/changes(?:/(\d+))?(?:/(colour|fancy))?$!) {
    oddmuse_serve_changes($stream, $host, undef, $n||3, $style, 1); # days!
  } elsif (($host, $space, $id, $style) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/history/([^/]*)(?:/(colour|fancy))?$!) {
    oddmuse_serve_history($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))), $style);
  } elsif (($host, $space, $id, $n, $style) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/diff/([^/]*)(?:/(\d+))?(?:/(colour))?$!) {
    oddmuse_serve_diff($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))), $n, $style);
  } elsif ($url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/match$!) {
    result($stream, "10", "Find page by name (Perl regex)");
  } elsif (($host, $space, $query) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/match\?([^#]+)!) {
    oddmuse_serve_match($stream, $host, decode_utf8(uri_unescape($space)), decode_query($query));
  } elsif ($url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/search$!) {
    result($stream, "10", "Find page by content (Perl regex)");
  } elsif (($host, $space, $query) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/search\?([^#]+)!) {
    oddmuse_serve_search($stream, $host, decode_utf8(uri_unescape($space)), decode_query($query));
  } elsif (($host, $space, $id, $query) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/comment/([^/#?]+)(?:\?([^#]+))?$!) {
    oddmuse_comment($stream, $host, decode_utf8(uri_unescape($space)), free_to_normal(decode_utf8(uri_unescape($id))), decode_query($query));
  } elsif (($host, $space) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/atom$!) {
    oddmuse_serve_atom($stream, $host, decode_utf8(uri_unescape($space)), 'rc');
  } elsif (($host, $space) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/rss$!) {
    oddmuse_serve_rss($stream, $host, decode_utf8(uri_unescape($space)), 'rc');
  } elsif (($host, $space) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/blog/atom$!) {
    oddmuse_serve_atom($stream, $host, decode_utf8(uri_unescape($space)), 'journal');
  } elsif (($host, $space) = $url =~ m!^gemini://$hosts(?::$port)?(?:/($spaces))?/do/blog/rss$!) {
    oddmuse_serve_rss($stream, $host, decode_utf8(uri_unescape($space)), 'journal');
  } elsif (($query) = $url =~ m!^GET (\S*) HTTP/1\.[01]$!
	   and ($host) = $headers->{host} =~ m!^$hosts(?::$port)(.*)$!) {
    $log->info("Redirecting to https://$host$query");
    $stream->write("HTTP/1.1 301 Back to port 443!\r\n");
    $stream->write("Location: https://$host:443$query\r\n");
    $stream->write("\r\n");
  } else {
    # We still rely on things like /do/spaces
    # result($stream, "59", "I don't know how to handle this $url");
    return 0;
  }
  return 1;
}

sub oddmuse_serve_robots {
  my $stream = shift;
  $log->info("Serving robots.txt");
  success($stream, 'text/plain');
  $stream->write(<<'EOT');
User-agent: *
Disallow: /raw
Disallow: /html
Disallow: /diff
Disallow: /history
Disallow: /tag
Disallow: /do/comment
Disallow: /do/changes
Disallow: /do/rss
Disallow: /do/atom
Disallow: /do/blog/rss
Disallow: /do/blog/atom
Disallow: /do/new
Disallow: /do/more
Disallow: /do/match
Disallow: /do/search
# allowing /do/index!
Crawl-delay: 10
EOT
}

sub oddmuse_serve_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  # cannot use text() because we don't know if we're serving a file or plain
  # text when querying Oddmuse
  my $page = oddmuse_get_page($stream, $host, $space, $id, $revision) // return;
  if (my ($type, $data) = $page =~ /^#FILE (\S+) ?(?:\S+)?\n(.*)/s) {
    oddmuse_serve_file_page($stream, $id, $type, $data);
  } else {
    my $text = oddmuse_gemini_text($stream, $host, $space, $page, $id);
    oddmuse_serve_gemini_page($stream, $host, $space, $id, $text, $revision);
  }
}

# this is required when combining gopher with oddmuse!
*oddmuse_text_old = \&App::Phoebe::text;
*App::Phoebe::text = \&oddmuse_text_new;

sub oddmuse_text_new {
  my ($stream, $host, $space, $id, $revision) = @_;
  if (exists $oddmuse_wikis{$host}) {
    my $text = oddmuse_get_page(@_);
    return oddmuse_gemini_text($stream, $host, $space, $text, $id);
  } else {
    return oddmuse_text_old(@_);
  }
}

sub oddmuse_get_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $url = "$oddmuse_wikis{$host}";
  $url .= "/$space" if $space;
  $url .= "/raw/" . uri_escape_utf8($id);
  $url .= "?revision=$revision" if $revision;
  return oddmuse_get_raw($stream, $url);
}

# It would be cool if this were streaming...
sub oddmuse_get_raw {
  my $stream = shift;
  my $url = shift;
  $log->debug("Requesting $url");
  my $ua = Mojo::UserAgent->new;
  my $res = $ua->get($url => {'X-Forwarded-For' => $stream->handle->peerhost})->result;
  if ($res->is_success) {
    return $res->text;
  } elsif ($res->code == 404) {
    return "";
  }
  oddmuse_http_error($stream, $res->code, $res->message, $url); # false
}

sub oddmuse_http_error {
  my $stream = shift;
  my $code = shift;
  my $message = shift;
  my $url = shift;
  if ($code >= 200 and $code < 300) { $code = 20 }
  elsif ($code == 301) { $code = 31 }
  elsif ($code >= 300 and $code < 400) { $code = 30 }
  elsif ($code == 403) { $code = 60 }
  elsif ($code == 404) { $code = 51 }
  elsif ($code == 405) { $code = 59 }
  elsif ($code >= 400 and $code < 500) { $code = 50 }
  elsif ($code >= 500 and $code < 600) { $code = 40 }
  else { $code = 50 }
  $log->warn("$code $message requesting $url");
  $stream->write(encode_utf8 "$code $message\r\n");
  return; # false
}

sub oddmuse_serve_file_page {
  my $stream = shift;
  my $id = shift;
  my $type = shift;
  my $data = shift;
  $log->info("Serving $id as $type file");
  $data = decode_base64($data);
  $log->debug("Bytes: " . length($data));
  success($stream, $type);
  binmode(STDOUT, ":raw");
  $stream->write($data);
}

sub oddmuse_serve_gemini_page {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $text = shift;
  my $revision = shift;
  $log->info("Serve page $id");
  success($stream);
  $stream->write(encode_utf8 "# " . normal_to_free($id) . "\n");
  $stream->write(encode_utf8 $text);
  if (not $revision and $id !~ /^Comments_on_(.*)/) {
    my $comments = oddmuse_get_page($stream, $host, $space, "Comments_on_$id");
    if ($comments) {
      $stream->write("\n\n## Comments\n");
      $stream->write(encode_utf8 oddmuse_gemini_text($stream, $host, $space, $comments, $id));
    }
  }
  $stream->write(encode_utf8 oddmuse_footer($stream, $host, $space, $id));
}

sub oddmuse_gemini_text {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $text = shift;
  my $id = shift;
  # escape the preformatted blocks
  my $ref = 0;
  my @escaped;
  my $link_regex = "([-,.()'%&!?;<> _1-9A-Za-z\x{0080}-\x{fffd}]|[-,.()'%&!?;<> _0-9A-Za-z\x{0080}-\x{fffd}][-,.()'%&!?;<> _0-9A-Za-z\x{0080}-\x{fffd}]+)";
  my $wiki_word = '(\p{Uppercase}+\p{Lowercase}+\p{Uppercase}\p{Alphabetic}*)';
  # newline magic: the escaped block does not include the newline; it is
  # retained in $text so that the following rules still deal with newlines
  # correctly; when we replace the escaped blocks back in, they'll be without
  # the trailing newline and fit right in.
  $text =~ s/^(```.*?\n```)\n/push(@escaped, $1); "\x03" . $ref++ . "\x04\n"/mesg;
  $text =~ s/^<pre>\n?(.*?\n)<\/pre>\n?/push(@escaped, "```\n$1```\n"); "\x03" . $ref++ . "\x04\n"/mesg;
  $text =~ s/^((\|.*\|\n)*\|.*\|)/push(@escaped, "```\n$1\n```"); "\x03" . $ref++ . "\x04\n"/meg;
  my @blocks = split(/\n\n+|(?=\\\\\n)|\n(?=[*-]|=>)|\n\> *\n/, $text);
  for my $block (@blocks) {
    $block =~ s/^- /* /g; # fix list items
    $block =~ s/\s+/ /g; # unwrap lines
    $block =~ s/^\s+//; # trim
    $block =~ s/\s+$//; # trim
    my @links;
    $block =~ s/^(=>.*)\n?/push(@links, $1); ""/gem;
    $block =~ s/^$full_url_regex\n?/push(@links, "=> $1"); ""/ge;
    $block =~ s/\[([^]]+)\]\($full_url_regex\)/push(@links, oddmuse_gemini_link($stream, $host, $space, $1, $2)); $1/ge;
    $block =~ s/\[([^]]+)\]\(([^) ]+)\)/push(@links, oddmuse_gemini_link($stream, $host, $space, $1, $2)); $1/ge;
    $block =~ s/\[$full_url_regex\s+([^]]+)\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $2, $1)); $2/ge;
    $block =~ s/\[\[([a-z\/-]+):$full_url_regex\|([^]]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $3, $2)); $3/ge;
    # numbered entities are not hashtags, e.g. &#x2605; is ★
    $block =~ s/&#x([0-9a-f]{4});/chr(hex($1))/gie;
    $block =~ s/\[\[tag:([^]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $1, "tag\/$1")); $1/ge;
    $block =~ s/\[\[tag:([^]|]+)\|([^\]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $2, "tag\/$1")); $2/ge;
    $block =~ s/<journal search tag:(\S+)>\n*/push(@links, oddmuse_gemini_link($stream, $host, $space, "Explore the $1 tag", "tag\/$1")); ""/ge;
    $block =~ s/\[\[image(?:\/[^\/:]+)*:([^]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, "$1 (image)", $1)); ""/ge;
    $block =~ s/\[\[image(?:\/[^\/:]+)*:([^]|]+)\|([^\]|]*)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, "$2 (image)", $1)) if $2; ""/ge;
    $block =~ s/\[\[image(?:\/[^\/:]+)*:([^]|]+)\|([^\]|]*)\|([^\]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, "$2 (image)", $1), oddmuse_gemini_link($stream, $host, $space, "$2 (follow-up)", $3)); ""/ge;
    $block =~ s/\[\[image(?:\/[^\/:]+)*:([^]|]+)\|([^\]|]*)\|([^\]|]*)\|([^\]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, "$2 (image)", $1), oddmuse_gemini_link($stream, $host, $space, "$4 (follow-up)", $3)); ""/ge;
    # free links with text, e.g. [[Alex Schroeder|code monkey]]
    $block =~ s/\[\[$link_regex\|([^\]|]+)\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $2, $1)); $2/ge;
    # free links, e.g. [[Alex Schröder]]
    $block =~ s/\[\[$link_regex\]\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $1)); $1/ge;
    # but excluding special typing like [[h/p-note:I'm interested in ...]]
    $block =~ s/\[\[(?:[^]:]+:)?$link_regex\]\]/$1/g;
    # handle the ?action=index url abbreviation [Tau_Subsector:?action=index 39 pages]
    $block =~ s/\[($oddmuse_namespace_regex):\?action=index\s+([^\]]+)\]/push(@links, oddmuse_gemini_link($stream, $host, $1, $2, "do\/index")); $2/ge;
    # namespaces, e.g. on campaignwiki.org: [Tau_Subsector:HomePage Tau Subsector]
    $block =~ s/\[($oddmuse_namespace_regex):([^?#[:space:]]*) ([^\]]+)\]/push(@links, oddmuse_gemini_link($stream, $host, $1, $3, $2)); $3/ge;
    # wiki words with text, e.g. [AlexSchroeder code monkey]
    $block =~ s/\[$wiki_word ([^\]]+)\]/push(@links, oddmuse_gemini_link($stream, $host, $space, $2, $1)); $2/ge
      if $oddmuse_wiki_links{$host};
    $block =~ s/\[Self:\S+ ([^\]]+)\]/$1/ge;
    $block =~ s/\[new:([^\]:]+)[^\]]*\]/join(' ', split(':', $1)) . ': '/ge;
    $block =~ s/$wiki_word/push(@links, oddmuse_gemini_link($stream, $host, $space, $1)); $1/ge
      if $oddmuse_wiki_links{$host};
    $block =~ s/\[color=([^]]+)\]/colour($stream, $1)/ge;
    $block =~ s/\[\/color\]/colour($stream, "reset")/ge;
    $block =~ s/^(=+)(.*?)=*$/'#' x length($1) . ' ' . $2/gem;
    $block =~ s/<[a-z]+(?:\s+[a-z-]+="[^"]+")>//g;
    $block =~ s/<\/[a-z]+>//g;
    $block =~ s/^((?:> .*\n?)+)$/join(" ", split("\n> ", $1))/ge; # unwrap quotes
    $block =~ s/#(\w+) */push(@links, oddmuse_gemini_link($stream, $host, $space, normal_to_free($1), "tag\/$1")); ""/ge; # hashtags at the end
    $block .= "\n" if $block and @links; # no empty line if the block was all links
    $block .= join("\n", uniq(@links));
  }
  $text = join("\n\n", @blocks); # add paragraph separation
  $text =~ s/\n\\\\ //g; # remove paragraph separation for linebreaks
  $text =~ s/^\* (.*)\n(=> \S+ \1)/$2/mg; # remove list items that are just links
  $text =~ s/^(=?>.*\n)\n(?==>)/$1/mg; # remove empty lines between links or between links and quotes
  $text =~ s/^(\* .*\n)\n(?=\* )/$1/mg; # remove empty lines between list items
  $text =~ s/^Tags: .*/Tags:/m;
  $text =~ s/\x03(\d+)\x04/$escaped[$1]/ge;
  return $text . "\n";
}

sub oddmuse_gemini_link {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $title = shift;
  my $id = shift;
  $id = "page/" . free_to_normal($id) if $id and $id !~ /\//;
  return gemini_link($stream, $host, $space, $title, $id);
}

# This is only used for the [color=foo]. I'm keeping this simple (the old eight
# colours) because that's what Emacs and therefore Elpher understand.
sub colour {
  my $stream = shift;
  my $colour = shift;
  my $code = { black => 30, red => 31, green => 32, yellow => 93, blue => 94, magenta => 35, cyan => 36, white => 37,
	       orange => 33, purple => 35, indigo => 34, violet => 35, # various synonyms
	       reset => 0 };
  return "" unless exists $code->{$colour};
  return "\e[$code->{$colour}m";
}

sub oddmuse_footer {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my @links;
  $stream->write("\n\n\n");
  if (my ($original) = $id =~ /^Comments_on_(.*)/) {
    push(@links, oddmuse_gemini_link($stream, $host, $space, "Back to the original page", $original));
  }
  my $token = $oddmuse_wiki_tokens{$host};
  $token = $server->{wiki_token}->[0] if not $token and $server->{wiki_token};
  $stream->write(encode_utf8 "(The access token for short comments is “$token”.)\n");
  push(@links, oddmuse_gemini_link($stream, $host, $space, "Leave a short comment", "do/comment/$id"));
  push(@links, oddmuse_gemini_link($stream, $host, $space, "How to leave a longer comment", "How_to_comment_without_a_browser"));
  push(@links, oddmuse_gemini_link($stream, $host, $space, "Raw comments", "raw/Comments_on_$id")) if $id !~ /^Comments_on_(.*)/;
  push(@links, oddmuse_gemini_link($stream, $host, $space, "Raw text", "raw/$id"));
  push(@links, oddmuse_gemini_link($stream, $host, $space, "HTML", "html/$id"));
  return join("\n", @links, "");
}

sub oddmuse_serve_tag {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $tag = shift;
  success($stream);
  $log->info("Serving tag $tag");
  $stream->write("This page lists all the pages tagged $tag.\n");
  print_link($stream, $host, $space, normal_to_free($tag), "page/$tag");
  $stream->write("\n");
  my $url = "$oddmuse_wikis{$host}?raw=1&search=tag:$tag";
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  shift @entries; # skip head
  foreach my $entry (@entries) {
    my $data = parse_data($entry);
    my $id = $data->{title};
    print_link($stream, $host, $space, normal_to_free($id), "page/$id");
  }
}

sub parse_data {
  my $data = shift;
  my %result = (description => "");
  while ($data =~ /(\S+?): (.*?)(?=\n[^ \t]|\Z)/gs) {
    my ($key, $value) = ($1, $2);
    $value =~ s/\n\t/\n/g;
    $result{$key} = $value;
  }
  return \%result;
}

sub oddmuse_serve_raw {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $url = "$oddmuse_wikis{$host}";
  $url .= "/$space" if $space;
  $url .= "/raw/" . uri_escape_utf8($id);
  $url .= "?revision=$revision" if $revision;
  my $page = oddmuse_get_raw($stream, $url) // return;
  if (my ($type, $data) = $page =~ /^#FILE (\S+) ?(?:\S+)?\n(.*)/s) {
    oddmuse_serve_file_page($stream, $id, $type, $data);
    return;
  }
  $log->info("Serving raw $id");
  success($stream, 'text/plain; charset=UTF-8');
  $stream->write(encode_utf8 $page);
}

sub oddmuse_serve_html {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $url = "$oddmuse_wikis{$host}";
  $url .= "/$space" if $space;
  $url .= "/" . uri_escape_utf8($id);
  $url .= "?revision=$revision" if $revision;
  my $page = oddmuse_get_raw($stream, $url) // return;
  $log->info("Serving $id as HTML");
  success($stream, 'text/html');
  $stream->write(encode_utf8 $page);
}

sub free_to_normal {
  my $title = shift;
  $title =~ s/^ +//g;
  $title =~ s/ +$//g;
  $title =~ s/ +/_/g;
  return $title;
}

sub normal_to_free {
  my $title = shift;
  $title =~ s/_/ /g;
  return $title;
}

# this is required when combining gopher with oddmuse!
*blog_pages_old = \&App::Phoebe::blog_pages;
*App::Phoebe::blog_pages = \&blog_pages;

sub blog_pages {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  if (exists $oddmuse_wikis{$host}) {
    my $url = "$oddmuse_wikis{$host}?raw=1;action=index;match=^\\d\\d\\d\\d\\-\\d\\d-\\d\\d;n=$n";
    return map { s/_/ /g; $_ } split(/\n/, oddmuse_get_raw($stream, $url) // '');
  }
  return blog_pages_old($stream, $host, $space, $n);
}

sub oddmuse_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  my @pages = blog_pages($stream, $host, $space, $n);
  return unless @pages;
  for my $id (@pages) {
    print_link($stream, $host, $space, normal_to_free($id), "page/$id");
  }
  print_link($stream, $host, $space, "More...", "do/blog/" . 10 * $n);
}

sub oddmuse_serve_blog {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  $log->info("Serving $n blog items for $host");
  success($stream);
  $stream->write("# Blog\n");
  $stream->write("Serving the last $n items.\n");
  oddmuse_blog($stream, $host, $space, $n);
}

sub oddmuse_serve_index {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  $log->info("Serving all pages for $host");
  success($stream);
  $stream->write("# All Pages\n");
  # we need to call our own: if we import pages from App:Phoebe, we get a copy
  # and would have to remap that just like we do App::Phoebe::pages below
  my @pages = oddmuse_pages_new($stream, $host, $space);
  return unless @pages;
  for my $id (@pages) {
    print_link($stream, $host, $space, normal_to_free($id), "page/$id");
  }
}

sub oddmuse_serve_match {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $term = shift;
  $log->info("Serving pages matching $term");
  success($stream);
  $stream->write(encode_utf8 "# Pages matching ‘$term’\n");
  # we need to call our own: if we import pages from App:Phoebe, we get a copy
  # and would have to remap that just like we do App::Phoebe::pages below
  my @pages = oddmuse_pages_new($stream, $host, $space, $term);
  for my $id (@pages) {
    print_link($stream, $host, $space, normal_to_free($id), "page/$id");
  }
}

sub oddmuse_serve_search {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $term = shift;
  $log->info("Serving search for $term");
  success($stream);
  $stream->write(encode_utf8 "# Search ‘$term’\n");
  my $url = "$oddmuse_wikis{$host}?raw=1&search=" . uri_escape_utf8($term);
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  shift @entries; # skip head
  foreach my $entry (@entries) {
    my $data = parse_data($entry);
    my $id = $data->{title};
    print_link($stream, $host, $space, normal_to_free($id), "page/$id");
  }
}

# this is required when combining gopher with oddmuse!
*oddmuse_pages_old = \&App::Phoebe::pages;
*App::Phoebe::pages = \&oddmuse_pages_new;

sub oddmuse_pages_new {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $re = shift;
  if (exists $oddmuse_wikis{$host}) {
    my $url = "$oddmuse_wikis{$host}?raw=1;action=index";
    $url .= ";ns=$space" if $space;
    $url .= ";match=" . uri_escape_utf8($re) if $re;
    return map { s/_/ /g; $_ } split(/\n/, oddmuse_get_raw($stream, $url));
  }
  return oddmuse_pages_old($stream, $host, $space, $re);
}

# this is required when combining gopher with oddmuse!
*oddmuse_search_old = \&App::Phoebe::search;
*App::Phoebe::search = \&oddmuse_search_new;

sub oddmuse_search_new {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $re = shift;
  if (exists $oddmuse_wikis{$host}) {
    my $url = "$oddmuse_wikis{$host}?raw=1";
    $url .= ";ns=$space" if $space;
    $url .= ";context=0;search=" . uri_escape($re) if $re;
    return map { s/_/ /g; $_ } split(/\n/, oddmuse_get_raw($stream, $url));
  }
  return oddmuse_search_old($stream, $host, $space, $re, @_);
}

sub oddmuse_serve_changes {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $n = shift;
  my $style = shift;
  my $all = shift;
  $log->info("Serving changes for $n days");
  success($stream);
  $stream->write("# Changes\n");
  if (not $style) { print_link($stream, $host, $space, "Colour changes", "do/changes/$n/colour") }
  elsif ($style eq "colour") { print_link($stream, $host, $space, "Fancy changes", "do/changes/$n/fancy") }
  elsif ($style eq "fancy") { print_link($stream, $host, $space, "Normal changes", "do/changes/$n") }
  print_link($stream, $host, $space, "Atom Feed", "do/atom");
  print_link($stream, $host, $space, "RSS Feed", "do/rss");
  my $url = "$oddmuse_wikis{$host}?raw=1;action=rc;all=1;showedit=1;days=$n";
  if ($space) {
    $url .= ";ns=$space";
  } if (not $all) {
    $url .= ";local=1";
  }
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  shift @entries; # skip head
  my $log;
  foreach my $entry (@entries) {
    my $data = parse_data($entry);
    # namespaces
    my $ns = $space;
    my $title = $data->{title};
    if (not $ns and $title =~ /:/) {
      ($ns, $title) = split(/:/, $title);
    }
    # timestamp from 2020-07-22T20:59Z back to a number
    my $ts = $data->{"last-modified"};
    $ts =~ s/Z/:00Z/; # apparently seconds are mandatory?
    $ts = DateTime::Format::ISO8601->parse_datetime($ts)->epoch();
    # author from some string back to a bogus hash: [0-7]{4}
    my $author = $data->{generator};
    $author = bogus_hash($stream, encode_utf8($author)) unless $author =~ /^[0-7]{4}$/;
    push(@$log, [
	   $ts,
	   free_to_normal($title),
	   $data->{revision},
	   $author,
	   $host,
	   $ns,
	   1]);   # show space
  }
  # taking the head of the @$log to get new log entries
  $stream->write("Showing up to $n days.\n");
  changes($stream,
    scalar(@$log), # just show them all
    sub { $stream->write("## " . shift . "\n") },
    sub { $stream->write(encode_utf8 shift . " by " . colourize($stream, shift, $style) . "\n") },
    sub {
      my ($host, $space, $title, $id) = @_;
      $title =~ s/_/ /g;
      print_link($stream, $host, $space, $title, $id) },
    sub { $stream->write(encode_utf8 join("\n", @_, "")) },
    sub { @{shift(@$log) } if @$log },
    sub { 1 }, # show a diff link, always
      );
  # there is always more...
  $stream->write("\n");
  print_link($stream, $host, $space, "More...", "do/changes/" . 2 * $n . ($style ? "/$style" : ""));
}

sub oddmuse_serve_history {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $style = shift;
  success($stream);
  $log->info("Serve history for $id");
  $stream->write("# Page history for " . normal_to_free($id) . "\n");
  if (not $style) { print_link($stream, $host, $space, "Colour history", "history/$id/colour") }
  elsif ($style eq "colour") { print_link($stream, $host, $space, "Fancy history", "history/$id/fancy") }
  elsif ($style eq "fancy") { print_link($stream, $host, $space, "Normal history", "history/$id") }
  my $url = "$oddmuse_wikis{$host}?raw=1;action=history;id=" . uri_escape_utf8($id);
  $url .= ";ns=$space" if $space;
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  shift @entries; # skip head
  my $log;
  foreach my $entry (@entries) {
    my $data = parse_data($entry);
    # timestamp from 2020-07-22T20:59Z back to a number
    my $ts = $data->{"last-modified"};
    $ts =~ s/Z/:00Z/; # apparently seconds are mandatory?
    $ts = DateTime::Format::ISO8601->parse_datetime($ts)->epoch();
    # author from some string back to a bogus hash: [0-7]{4}
    my $author = $data->{generator};
    $author = bogus_hash($stream, encode_utf8($author)) unless $author =~ /^[0-7]{4}$/;
    push(@$log, [
	   $ts,
	   free_to_normal($data->{title}),
	   $data->{revision},
	   $author,
	   $host,
	   $space, # space
	   0]);   # show space
  }
  # taking the head of the @$log to get new log entries
  changes($stream,
    scalar(@$log), # just show them all
    sub { $stream->write("## " . shift . "\n") },
    sub { $stream->write(shift . " by " . colourize($stream, shift, $style) . "\n") },
    sub {
      my ($host, $space, $title, $id) = @_;
      $title =~ s/_/ /g;
      print_link($stream, $host, $space, $title, $id) },
    sub { $stream->write(join("\n", @_, "")) },
    sub { @{shift(@$log) } if @$log },
    sub { 1 }, # show a diff link, always
      );
}

sub oddmuse_serve_diff {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $revision = shift;
  my $style = shift;
  $log->info("Serving the diff of $id");
  success($stream);
  $stream->write("# Differences for " . normal_to_free($id) . "\n");
  if (not $style) { print_link($stream, $host, $space, "Colour diff", "diff/$id/$revision/colour") }
  else { print_link($stream, $host, $space, "Normal diff", "diff/$id/$revision") }
  $stream->write("Showing the differences between revision $revision and the current revision.\n");
  my $url = $oddmuse_wikis{$host} . ($space ? "/$space" : "") . "/raw/" . uri_escape_utf8($id);
  my $new = oddmuse_get_raw($stream, $url);
  $url .= "?revision=$revision" if $revision;
  my $old = oddmuse_get_raw($stream, $url);
  if (not $style) {
    diff($old, $new,
	 sub { $stream->write(encode_utf8 "$_\n") for @_ },
	 sub { $stream->write(encode_utf8 "> $_\n") for map { $_||"⏎" } @_ },
	 sub { $stream->write(encode_utf8 "> $_\n") for map { $_||"⏎" } @_ },
	 sub { "｢$_[0]｣" });
  } else {
    diff($old, $new,
	 sub { $stream->write(encode_utf8 "$_\n") for @_ },
	 sub { $stream->write(encode_utf8 "> \033[31m$_\033[0m\n") for map { $_||"⏎" } @_ },
	 sub { $stream->write(encode_utf8 "> \033[32m$_\033[0m\n") for map { $_||"⏎" } @_ },
	 sub { "\033[1m$_[0]\033[22m" });
  }
}

sub oddmuse_serve_rss {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $action = shift;
  my $scheme = 'gemini';
  my $port = port($stream);
  $log->info("Serving Gemini RSS");
  success($stream, "application/rss+xml");
  $stream->write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
  $stream->write("<rss version=\"2.0\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n");
  my $url = "$oddmuse_wikis{$host}?action=$action;raw=1;full=1";
  if ($space) {
    $url .= ";ns=$space";
  }
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  my $entry = shift @entries;
  my $data = parse_data($entry);
  $stream->write("<channel>\n");
  $stream->write(encode_utf8 "<title>" . quote_html($data->{title}) . "</title>\n");
  $stream->write(encode_utf8 "<description>" . quote_html($data->{description}) . "</description>\n");
  $stream->write("<link>$scheme://$host:$port/</link>\n");
  $stream->write("<atom:link rel=\"self\" type=\"application/rss+xml\" href=\"$scheme://$host:$port/do/rss\" />\n");
  $stream->write("<generator>Phoebe + Config</generator>\n");
  $stream->write("<docs>http://blogs.law.harvard.edu/tech/rss</docs>\n");
  my $dir = $oddmuse_wiki_dirs{$host};
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(modified("$dir/pageidx"));
  $stream->write("<updated>"
      . sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year + 1900, $mon + 1, $mday, $hour, $min, $sec)
      . "</updated>\n");
  while (@entries) {
    $data = parse_data(shift(@entries));
    $stream->write("<item>\n");
    # namespaces
    my $ns;
    my $title = $data->{title};
    if ($title =~ /:/) {
      ($ns, $title) = split(/:/, $title);
    }
    my $id = free_to_normal($title);
    $stream->write(encode_utf8 "<title>" . quote_html($data->{title}) . "</title>\n");
    my $link = "gemini://$host:$port/" . ($ns ? "$ns/" : "") . "page/" . uri_escape_utf8($id);
    $stream->write("<link>$link</link>\n");
    $stream->write("<guid>$link</guid>\n");
    $link = "gemini://$host:$port/" . ($ns ? "$ns/" : "") . "page/Comments_on_" . uri_escape_utf8($id);
    $stream->write("<comments>$link</comments>\n");
    my $summary = quote_html(oddmuse_gemini_text($stream, $host, $space, $data->{description}, $id));
    $stream->write(encode_utf8 "<description>$summary</description>\n") if $summary;
    # timestamp from 2020-07-22T20:59Z back to a number
    my $ts = $data->{"last-modified"};
    $ts =~ s/Z/:00Z/; # apparently seconds are mandatory?
    $ts = DateTime::Format::ISO8601->parse_datetime($ts)->epoch();
    my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($ts); # Sat, 07 Sep 2002 00:00:01 GMT
    $stream->write("<pubDate>"
	. sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT", qw(Sun Mon Tue Wed Thu Fri Sat)[$wday], $mday,
		  qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)[$mon], $year + 1900, $hour, $min, $sec)
	. "</pubDate>\n");
    $stream->write("</item>\n");
  };
  $stream->write("</channel>\n");
  $stream->write("</rss>\n");
}

sub oddmuse_serve_atom {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $action = shift;
  my $port = port($stream);
  $log->info("Serving Gemini Atom");
  success($stream, "application/atom+xml");
  $stream->write(qq{<?xml version="1.0" encoding="UTF-8"?>\n});
  $stream->write("<feed xmlns=\"http://www.w3.org/2005/Atom\">\n");
  $stream->write("<link href=\"gemini:/$host:$port/\"/>\n");
  $stream->write("<link rel=\"self\" type=\"application/atom+xml\" href=\"gemini://$host:$port/do/atom\"/>\n");
  $stream->write("<id>gemini:/$host:$port/do/atom</id>\n");
  my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(modified("$oddmuse_wiki_dirs{$host}/pageidx"));
  $stream->write("<updated>"
      . sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ", $year + 1900, $mon + 1, $mday, $hour, $min, $sec)
      . "</updated>\n");
  $stream->write("<generator uri=\"gemini://$host:$port/\" version=\"1.0\">Phoebe + Config</generator>\n");
  # now get the data and print the entries
  my $url = "$oddmuse_wikis{$host}?action=$action;raw=1;full=1";
  if ($space) {
    $url .= ";ns=$space";
  }
  my $page = oddmuse_get_raw($stream, $url) // return;
  my @entries = split(/\n\n+/, $page);
  my $data = parse_data(shift @entries);
  $stream->write(encode_utf8 "<title>" . quote_html($data->{title}) . "</title>\n");
  while (@entries) {
    $data = parse_data(shift @entries);
    $stream->write("<entry>\n");
    my $name = $data->{title};
    my $id = free_to_normal($name);
    $stream->write(encode_utf8 "<title>$name</title>\n");
    my $link = "gemini://$host:$port/page/" . uri_escape_utf8($id);
    $stream->write("<link href=\"$link\"/>\n");
    $stream->write("<id>$link</id>\n");
    my $summary = quote_html(oddmuse_gemini_text($stream, $host, $space, $data->{description}, $id));
    $stream->write(encode_utf8 "<content type=\"text\">$summary</content>\n") if $summary;
    $stream->write("<updated>$data->{'last-modified'}</updated>\n");
    $stream->write("</entry>\n");
  };
  $stream->write("</feed>\n");
}

sub oddmuse_comment {
  my $stream = shift;
  my $host = shift;
  my $space = shift;
  my $id = shift;
  my $query = shift; # token or comment
  my $port = port($stream);
  if (not $id) {
    $log->debug("The URL lacks a page name");
    result($stream, "59", "The URL lacks a page name");
    return;
  }
  my $name = oddmuse_fingerprint_name($stream, $host, $query);
  return unless defined $name;
  if (not $query) {
    result($stream, "10", "Short comment");
    return;
  }
  $id = "Comments_on_$id" unless $id =~ /^Comments_on_/;
  my $token = $oddmuse_wiki_tokens{$host};
  $token = $server->{wiki_token}->[0] if not $token and $server->{wiki_token};
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->post(
    $oddmuse_wikis{$host}
    => {'X-Forwarded-For' => $stream->handle->peerhost}
    => form => {
      title => $id,
      ns => $space,
      aftertext => $query,
      username => $name,
      answer => $token,
      gemini => 1 });
  $log->debug("Got " . $tx->result->code . " response");
  if ($tx->result->code == 302) {
    my $url = "gemini://$host:$port";
    $url .= "/$space" if $space;
    result($stream, "30", "$url/page/" . uri_escape_utf8($id) . "");
    return;
  }
  $stream->write("59 Got HTTP code " . $tx->result->code . " " . $tx->result->message
      . " (" . $tx->req->url->to_abs . " " . $tx->req->params . ")\r\n");
}

# If the fingerprint exists in our file, no need to ask for the $token; it
# expires after a day (24 * 60 * 60 seconds). If no fingerprint is found, ask
# for a cert.
sub oddmuse_fingerprint_name {
  my $stream = shift;
  my $host = shift;
  my $token = shift;
  # This requires SSL_verify_mode => SSL_VERIFY_PEER and SSL_verify_callback =>
  # \&verify_fingerprint (which must not reject self-signed certificates).
  my $fingerprint = $stream->handle->get_fingerprint();
  if (not $fingerprint) {
    result($stream, "60", "You need a client certificate with a common name to edit this wiki");
    return;
  }
  my $dir = $server->{wiki_dir};
  my @lines;
  my $now = time();
  # Read the known fingerprint from the file.
  my %fingerprints;
  my $file = "$dir/fingerprints";
  %fingerprints = split(/\s+/, read_text($file)) if -e $file;
  # Forget about fingerprints older than 10min.
  for my $fp (keys %fingerprints) {
    delete $fingerprints{$fp} if $fingerprints{$fp} > $now + 600;
  }
  my @tokens;
  push(@tokens, $oddmuse_wiki_tokens{$host}) if $oddmuse_wiki_tokens{$host};
  push(@tokens, @{$server->{wiki_token}}) unless @tokens;
  if (not $fingerprints{$fingerprint}) {
    if (not $token) {
      result($stream, "10", "Token required to edit this wiki");
    } elsif (not grep { $token eq $_ } @tokens) {
      result($stream, "59", "Wrong token");
    } else {
      result($stream, "10", "Short comment");
      $fingerprints{$fingerprint} = $now;
    }
    # Save new or updated fingerprint timestamp.
    write_text($file, join("\n", map { "$_ $fingerprints{$_}" } keys %fingerprints));
    # Return undefined so that the user needs to react to the message above.
    return;
  }
  # Fingerprint found!
  $fingerprints{$fingerprint} = $now;
  # Save new or updated fingerprint timestamp.
  write_text($file, join("\n", map { "$_ $fingerprints{$_}" } keys %fingerprints));
  # User wants to provide no name: use "" so that we have a defined name.
  return ($stream->handle->peer_certificate('cn') || "");
}
