package App::Raider::WebTools;
our $VERSION = '0.003';
# ABSTRACT: MCP::Server factory with web search and fetch tools (Net::Async::WebSearch + Net::Async::HTTP)

use strict;
use warnings;
use Future::AsyncAwait;
use HTTP::Request::Common qw( GET );
use MCP::Server;
use Net::Async::HTTP;
use Net::Async::WebSearch;
use Net::Async::WebSearch::Provider::DuckDuckGo;
use Net::Async::WebSearch::Provider::Brave;
use Net::Async::WebSearch::Provider::Serper;
use Net::Async::WebSearch::Provider::Google;
use HTML::TreeBuilder;

use Exporter 'import';
our @EXPORT_OK = qw( build_web_tools_server );


sub _flatten_html {
  my ($html) = @_;
  my $t = HTML::TreeBuilder->new_from_content($html);
  $_->delete for $t->look_down(_tag => qr/^(?:script|style|noscript)$/);
  my $text = $t->as_text;
  $t->delete;
  $text =~ s/[ \t]+/ /g;
  $text =~ s/\n{3,}/\n\n/g;
  return $text;
}

sub build_web_tools_server {
  my %args = @_;
  my $loop            = $args{loop} or die "loop is required\n";
  my $max_fetch_bytes = $args{max_fetch_bytes} // 2_000_000;

  my $http = Net::Async::HTTP->new(
    user_agent  => 'raider/0.001',
    max_in_flight => 4,
  );
  $loop->add($http);

  my $ws = Net::Async::WebSearch->new(http => $http);
  $loop->add($ws);

  $ws->add_provider(Net::Async::WebSearch::Provider::DuckDuckGo->new);

  if ($ENV{BRAVE_API_KEY}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Brave->new(
      api_key => $ENV{BRAVE_API_KEY},
    ));
  }
  if ($ENV{SERPER_API_KEY}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Serper->new(
      api_key => $ENV{SERPER_API_KEY},
    ));
  }
  if ($ENV{GOOGLE_API_KEY} && $ENV{GOOGLE_CSE_ID}) {
    $ws->add_provider(Net::Async::WebSearch::Provider::Google->new(
      api_key => $ENV{GOOGLE_API_KEY},
      cx      => $ENV{GOOGLE_CSE_ID},
    ));
  }

  my $server = MCP::Server->new(name => 'app-raider-web', version => '1.0');

  $server->tool(
    name         => 'web_search',
    description  => 'Search the web across multiple providers (DuckDuckGo always; Brave/Serper/Google added when their API keys are in the environment). Returns ranked merged results.',
    input_schema => {
      type       => 'object',
      properties => {
        query => { type => 'string',  description => 'Search query' },
        limit => { type => 'integer', description => 'Max results (default 8)' },
      },
      required => ['query'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $query = $in->{query};
      my $limit = $in->{limit} // 8;
      my $f = $ws->search(query => $query, limit => $limit);
      my $out = eval { $f->get };
      return $tool->text_result("Error: $@", 1) if $@;
      my @lines;
      my $i = 0;
      for my $r (@{$out->{results} // []}) {
        $i++;
        my $title = $r->title // '(no title)';
        my $url   = $r->url   // '';
        my $sn    = $r->snippet // '';
        $sn =~ s/\s+/ /g;
        push @lines, "[$i] $title";
        push @lines, "    $url";
        push @lines, "    $sn" if length $sn;
      }
      if (my $errs = $out->{errors}) {
        for my $e (@$errs) {
          push @lines, "(error from $e->{provider}: $e->{error})";
        }
      }
      return $tool->text_result(@lines ? join("\n", @lines) : "No results.");
    },
  );

  $server->tool(
    name         => 'web_fetch',
    description  => 'Fetch a URL and return its body. HTML is flattened to readable text. Binary/large bodies are truncated.',
    input_schema => {
      type       => 'object',
      properties => {
        url    => { type => 'string',  description => 'URL to fetch' },
        as_html => { type => 'boolean', description => 'Keep raw HTML instead of flattening to text (default false)' },
      },
      required => ['url'],
    },
    code => sub {
      my ($tool, $in) = @_;
      my $url = $in->{url};
      my $req = GET($url);
      $req->header('User-Agent' => 'raider/0.001');
      my $f = $http->do_request(request => $req);
      my $resp = eval { $f->get };
      return $tool->text_result("Error: $@", 1) if $@;
      unless ($resp->is_success) {
        return $tool->text_result(
          sprintf("HTTP %s for %s", $resp->status_line, $url), 1);
      }
      my $body = $resp->decoded_content // '';
      if (length($body) > $max_fetch_bytes) {
        $body = substr($body, 0, $max_fetch_bytes) . "\n[truncated]\n";
      }
      my $ctype = $resp->header('Content-Type') // '';
      if (!$in->{as_html} && $ctype =~ m{text/html}i) {
        $body = _flatten_html($body);
      }
      my $header = sprintf("URL: %s\nStatus: %s\nContent-Type: %s\n\n",
        $url, $resp->status_line, $ctype);
      return $tool->text_result($header . $body);
    },
  );

  return $server;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Raider::WebTools - MCP::Server factory with web search and fetch tools (Net::Async::WebSearch + Net::Async::HTTP)

=head1 VERSION

version 0.003

=head2 build_web_tools_server

    my $server = App::Raider::WebTools::build_web_tools_server(
        loop           => $loop,         # required
        max_fetch_bytes => 2_000_000,
    );

Returns an L<MCP::Server> instance with two tools:

=over

=item * C<web_search(query, [limit])>  -- multi-provider search via
L<Net::Async::WebSearch>. DuckDuckGo is always enabled (keyless). Brave,
Serper and Google are auto-added when C<BRAVE_API_KEY>, C<SERPER_API_KEY>,
or both C<GOOGLE_API_KEY> + C<GOOGLE_CSE_ID> are set in the environment.

=item * C<web_fetch(url)>  -- fetch a URL via L<Net::Async::HTTP>. Returns
the response body (HTML is flattened to readable text, up to
C<max_fetch_bytes>).

=back

=head1 SEE ALSO

=over

=item * L<MCP::Server>

=item * L<Net::Async::WebSearch>

=item * L<Net::Async::HTTP>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
