# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI::Client;
use Mojo::Base -base, -signatures;

use Mojo::URL;
use Mojo::UserAgent;

has 'on_wait';    # optional coderef, called ~10x/sec while a request is in flight (drives the spinner)
has token => sub { die "A Cavil API token is required (run 'cavil-cli config', or set CAVIL_API_KEY)\n" };
has ua    => sub { Mojo::UserAgent->new->connect_timeout(30)->inactivity_timeout(120) };
has url   => sub { die "A Cavil URL is required (run 'cavil-cli config', or set CAVIL_URL)\n" };

# The identity the API token belongs to: a quick way to confirm the url and token are set up right.
sub whoami ($self) {
  return $self->_request('GET', '/api/v1/whoami')->json;
}

# Submit a source archive for a standard legal review. Returns {saved => {...}, duplicate => bool}; the same
# archive under the same name is idempotent (duplicate true). A 403 (key may not submit), 400 (checksum
# mismatch) and 413 (archive over the server limit) are the user's to fix, so they surface as friendly messages.
sub upload ($self, $tarball, $meta) {

  # ephemeral asks for a one-off report with no lasting side effects (no open review left in the legal backlog),
  # which is all this client ever wants. Servers without the planned ad-hoc mode ignore it, so it is always sent.
  my $form = {
    name      => $meta->{name},
    priority  => $meta->{priority},
    checksum  => $meta->{checksum},
    ephemeral => 1,
    tarball   => {file => $tarball},
    (defined $meta->{external_link} ? (external_link => $meta->{external_link}) : ())
  };
  my $res = $self->_request('POST', '/api/v1/packages/upload', {form => $form, ok_codes => [400, 403, 413]});
  die "This Cavil key may not submit packages (needs a read-write key with admin access)\n" if $res->code == 403;
  die "The archive is too large for this Cavil instance; trim it with a .cavilignore file or --exclude-path\n"
    if $res->code == 413;
  die "Upload rejected: @{[$res->json->{error} // 'bad request']}\n" if $res->code == 400;
  return $res->json;
}

# Fetch a report. Returns {ready => 1, data => ...} when it exists, or {ready => 0, stage => ...} while it is
# still being built (the endpoint answers 408 with the pipeline stage until the package is analyzed).
sub report ($self, $id, $format = 'json') {
  my $res = $self->_request('GET', "/api/v1/report/$id.$format", {ok_codes => [408]});
  return {ready => 1, data  => ($format eq 'json' ? $res->json : $res->text)} if $res->code == 200;
  return {ready => 0, stage => eval { $res->json->{stage} }};
}

# Fetch a generated document (spdx or notice), or undef while it is still being generated (408). Bytes are
# returned ready to write; the user agent transparently decompresses the server's gzip.
sub document ($self, $id, $key) {
  my $res = $self->_request('GET', "/api/v1/documents/$id/$key", {ok_codes => [408]});
  return undef if $res->code == 408;
  return $res->body;
}

sub _headers ($self) {
  return {Authorization => 'Bearer ' . $self->token};
}

sub _request ($self, $method, $path, $options = {}) {
  my $ua   = $self->ua;
  my @body = $options->{json} ? (json => $options->{json}) : $options->{form} ? (form => $options->{form}) : ();
  my $tx   = $ua->build_tx($method => $self->_url($path) => $self->_headers, @body);

  # A recurring timer on the UA's own loop fires during the blocking request (that loop is what start() runs),
  # so the caller's spinner keeps moving while we wait on the server.
  my $spin = $self->on_wait;
  my $tid  = $spin ? $ua->ioloop->recurring(0.1 => $spin) : undef;
  $tx = $ua->start($tx);
  $ua->ioloop->remove($tid) if defined $tid;

  return $tx->result unless my $err = $tx->error;

  # No status code means the request never reached the server: always fatal. An expected status (ok_codes, e.g.
  # 408 while a report builds) is handed back for the caller to act on; anything else is a friendly die with no
  # Carp file/line suffix leaking to the user.
  die "Connection error from Cavil ($method $path): $err->{message}\n" unless $err->{code};
  return $tx->result if grep { $_ == $err->{code} } @{$options->{ok_codes} // []};
  die "$err->{code} response from Cavil ($method $path): $err->{message}\n";
}

sub _url ($self, $path) {
  return Mojo::URL->new($self->url . $path);
}

1;
