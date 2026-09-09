# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI;
use Mojo::Base -base, -signatures;

use Cavil::CLI::Archive;
use Cavil::CLI::Client;
use Cavil::CLI::Config;
use Cavil::CLI::Progress;
use Cavil::CLI::Util qw(gate render_json render_text);
use Mojo::File       qw(path tempdir);
use Mojo::JSON       qw(to_json);
use Mojo::Util       qw(encode extract_usage getopt);
use Time::HiRes      ();

our $VERSION = '0.03';

has client => sub { Cavil::CLI::Client->new };

# Exit codes: clean, gate failed, usage/config problem, server/connection error.
use constant {EXIT_CLEAN => 0, EXIT_GATE => 1, EXIT_USAGE => 2, EXIT_SERVER => 3};

# Refuse before uploading an archive the server would reject anyway, so an accidental huge file (a build
# artifact, a data dump) fails fast with guidance instead of a slow doomed upload. Defaults to Cavil's own
# request limit; CAVIL_MAX_UPLOAD_MB raises it for an instance configured to accept more.
use constant UPLOAD_MAX_MB => 250;

sub _max_upload_bytes () {
  return (defined $ENV{CAVIL_MAX_UPLOAD_MB} ? $ENV{CAVIL_MAX_UPLOAD_MB} : UPLOAD_MAX_MB) * 1024 * 1024;
}

sub run ($self) {
  getopt
    'url=s'             => \my $url_opt,
    'name=s'            => \my $name,
    'priority=i'        => \my $priority,
    'fail-on-risk=i'    => \my $fail_on_risk,
    'external-link=s'   => \my $external_link,
    'sbom:s'            => \my $sbom,
    'notice:s'          => \my $notice,
    'respect-gitignore' => \my $respect_gitignore,
    'exclude-path=s@'   => \my $exclude_path,
    'timeout=i'         => \my $timeout,
    'format=s'          => \my $format,
    'show'              => \my $show,
    'no-color'          => \my $no_color,
    'quiet'             => \my $quiet,
    'h|help'            => \my $help;

  return print(extract_usage) ? EXIT_CLEAN : EXIT_CLEAN if $help;

  my ($command, $path) = @ARGV;
  unless (defined $command && ($command eq 'check' || $command eq 'whoami' || $command eq 'config')) {
    print STDERR extract_usage;
    return EXIT_USAGE;
  }

  my $config = Cavil::CLI::Config->new;

  # Saving settings needs no server, and is the only place a URL may be given: see below.
  return $self->_config($config, $url_opt, $show) if $command eq 'config';

  if (defined $url_opt) {
    print STDERR "--url only applies to 'cavil-cli config'; set CAVIL_URL (with CAVIL_API_KEY) to aim elsewhere\n";
    return EXIT_USAGE;
  }

  # Server and token are resolved together, from one source, and never mixed. Taking the URL from one place and
  # the token from another is how a token saved for one instance ends up being sent to a different one. For the
  # same reason there is no --token at all: an argument is world-readable in ps and stays in shell history.
  my ($url, $token)
    = defined $ENV{CAVIL_URL}
    || defined $ENV{CAVIL_API_KEY} ? ($ENV{CAVIL_URL}, $ENV{CAVIL_API_KEY}) : @{$config->load}{qw(url token)};
  unless (defined $url && defined $token) {
    print STDERR "A Cavil URL and API token are required, from the same source:\n"
      . "  run 'cavil-cli config' to save both, or set CAVIL_URL and CAVIL_API_KEY together\n";
    return EXIT_USAGE;
  }

  $format //= 'text';
  return $self->_whoami({url => $url, token => $token, format => $format}) if $command eq 'whoami';

  my %seen;
  my @exclude_paths = grep { !$seen{$_}++ } map {s{/\z}{}r} grep {length} @{$exclude_path // []}, split /[\s,]+/,
    ($ENV{CAVIL_EXCLUDE_PATHS} // '');

  my $color = $format eq 'text' && !$no_color && !$ENV{NO_COLOR} && -t STDOUT;

  return $self->_check(
    $path // '.',
    {
      url               => $url,
      token             => $token,
      name              => $name,
      priority          => $priority // 5,
      fail_on_risk      => $fail_on_risk,
      external_link     => $external_link,
      sbom              => $sbom,
      notice            => $notice,
      respect_gitignore => $respect_gitignore ? 1 : 0,
      exclude_paths     => \@exclude_paths,
      timeout           => $timeout // 900,
      format            => $format,
      color             => $color,
      progress          => (!$quiet && -t STDERR ? 1 : 0)
    }
  );
}

# Save the Cavil URL and API token to the config file, or show what is stored. The token is read from a hidden
# prompt, or from stdin when piped; there is no option to pass it, anywhere. --show never prints it.
sub _config ($self, $config, $url, $show) {
  my $saved = $config->load;

  if ($show) {
    print STDOUT 'Configuration file: ' . $config->file . "\n";
    print STDOUT '  url:   ' . ($saved->{url} // '(not set)') . "\n";
    print STDOUT '  token: ' . ($saved->{token} ? '******** (set)' : '(not set)') . "\n";
    return EXIT_CLEAN;
  }

  # The URL is not secret, so it may come from --url; otherwise prompt, offering the current value as default.
  if (defined $url) { $saved->{url} = $url }
  else {
    my $current = $saved->{url};
    print STDERR 'Cavil URL' . (defined $current ? " [$current]" : '') . ': ';
    my $line = readline STDIN;
    chomp $line           if defined $line;
    $saved->{url} = $line if defined $line && length $line;
  }

  # The token is secret: hidden prompt on a terminal, one stdin line when piped. Empty input keeps the existing.
  my $entered = _read_secret('Cavil API token' . ($saved->{token} ? ' [keep existing]' : '') . ': ');
  $saved->{token} = $entered if defined $entered && length $entered;

  unless (length($saved->{url} // '') && length($saved->{token} // '')) {
    print STDERR "A Cavil URL and API token are both required\n";
    return EXIT_USAGE;
  }

  $config->save($saved);
  print STDOUT 'Saved configuration to ' . $config->file . " (token hidden)\n";
  return EXIT_CLEAN;
}

# Read one line without echoing it, so a typed token never appears on screen. Only toggles the terminal when
# stdin is one; piped input (tests, scripts) is read as a plain line.
sub _read_secret ($prompt) {
  print STDERR $prompt;
  my $hide = -t STDIN;
  system('stty', '-echo') if $hide;
  my $line = readline STDIN;
  if ($hide) { system('stty', 'echo'); print STDERR "\n" }
  chomp $line if defined $line;
  return $line;
}

# Confirm the url and token work by asking the instance who the token belongs to, and time the round trip so a
# user can also see the instance is reachable and responsive.
sub _whoami ($self, $opts) {
  my $client = $self->client->url($opts->{url})->token($opts->{token});

  my $t0   = Time::HiRes::time;
  my $info = eval { $client->whoami };
  my $ms   = int((Time::HiRes::time - $t0) * 1000);
  if (my $err = $@) {
    chomp(my $msg = $err);
    print STDERR "Not authenticated with $opts->{url}:\n  $msg\n"
      . "Check the saved config ('cavil-cli config --show'), or CAVIL_URL / CAVIL_API_KEY.\n";
    return EXIT_SERVER;
  }

  if ($opts->{format} eq 'json') {
    print STDOUT encode('UTF-8', to_json({%$info, round_trip_ms => $ms}) . "\n");
    return EXIT_CLEAN;
  }

  my $roles = @{$info->{roles} || []} ? join(', ', @{$info->{roles}}) : 'none';
  print STDOUT encode('UTF-8',
        "Authenticated as $info->{user} (id @{[$info->{id} // '?']}) on $opts->{url}\n"
      . "  roles: $roles\n"
      . "  write access: @{[$info->{write_access} ? 'yes' : 'no']}\n"
      . "  round-trip: $ms ms\n");
  return EXIT_CLEAN;
}

# Upload the working tree, wait for the standard review, then print the verdict and gate the exit code on risk.
sub _check ($self, $dir, $opts) {
  my $client   = $self->client->url($opts->{url})->token($opts->{token});
  my $progress = Cavil::CLI::Progress->new(enabled => $opts->{progress});
  $client->on_wait(sub { $progress->spin });

  # Confirm access before packaging what may be a large tree, and fail with a clear reason if the key cannot.
  eval { $client->whoami };
  if (my $err = $@) {
    $progress->finish;
    chomp(my $msg = $err);
    print STDERR "Not authenticated with $opts->{url}:\n  $msg\n";
    return EXIT_SERVER;
  }

  my $name = $opts->{name}          // _package_name($dir);
  my $link = $opts->{external_link} // _external_link($dir);

  my $tmp     = tempdir;
  my $archive = $tmp->child('upload.tar.gz')->to_string;
  $progress->start("Packaging $name");
  my $checksum = eval {
    Cavil::CLI::Archive->new(
      dir               => $dir,
      respect_gitignore => $opts->{respect_gitignore},
      excludes          => $opts->{exclude_paths}
    )->build($archive);
  };
  if (my $err = $@) { $progress->finish; chomp(my $m = $err); print STDERR "$m\n"; return EXIT_USAGE; }

  my $max_bytes = _max_upload_bytes();
  my $size      = -s $archive;
  if ($size > $max_bytes) {
    $progress->finish;
    printf STDERR "The archive is %d MiB, over the %d MiB upload limit. Trim it with a .cavilignore file or "
      . "--exclude-path (or remove large generated files), then try again.\n", $size / 1024 / 1024,
      $max_bytes / 1024 / 1024;
    return EXIT_USAGE;
  }

  $progress->start('Uploading');
  my $saved = eval {
    $client->upload($archive,
      {name => $name, priority => $opts->{priority}, checksum => $checksum, external_link => $link});
  };
  if (my $err = $@) { $progress->finish; chomp(my $m = $err); print STDERR "$m\n"; return EXIT_SERVER; }
  my $id = $saved->{saved}{id};

  $progress->start('Reviewing');
  my $json     = eval { _poll($client, $id, $opts->{timeout}, $progress) };
  my $poll_err = $@;
  $progress->finish;
  if ($poll_err) { chomp(my $m = $poll_err); print STDERR "$m\n"; return EXIT_SERVER }

  my $info = _verdict($json, $opts, $id, $name);

  # Optional documents, requested when --sbom / --notice are present (with or without an explicit path).
  $progress->start('Fetching documents') if defined $opts->{sbom} || defined $opts->{notice};
  $info->{sbom} = _save_document($client, $id, 'spdx', $opts->{sbom}, "$name.spdx.json", $opts->{timeout})
    if defined $opts->{sbom};
  $info->{notice} = _save_document($client, $id, 'notice', $opts->{notice}, "$name.NOTICE.txt", $opts->{timeout})
    if defined $opts->{notice};

  my $output = $opts->{format} eq 'json' ? render_json($info) : render_text($info, color => $opts->{color});
  print STDOUT encode('UTF-8', $output);

  return gate($info->{risk}, $info->{threshold})->{failed} ? EXIT_GATE : EXIT_CLEAN;
}

# Server pipeline stages, mapped to what the progress line shows, so the wait names what is happening rather
# than sitting on a bare "Reviewing".
my %STAGE_LABEL = (
  queued     => 'Queued for review',
  unpacking  => 'Unpacking',
  indexing   => 'Indexing',
  analyzing  => 'Analyzing',
  finalizing => 'Finalizing report'
);

# Poll the report until it is ready, showing the current pipeline stage between attempts; die on timeout.
sub _poll ($client, $id, $timeout, $progress) {
  my $deadline = Time::HiRes::time + $timeout;
  while (1) {
    my $res = $client->report($id, 'json');
    return $res->{data} if $res->{ready};
    $progress->label($STAGE_LABEL{$res->{stage} // ''} // 'Reviewing');
    die "Timed out after ${timeout}s waiting for the review (package $id)\n" if Time::HiRes::time >= $deadline;
    for (1 .. 10) { $progress->spin; Time::HiRes::sleep(0.2) }
  }
}

# Normalize a report response into the flat verdict the renderers consume.
sub _verdict ($json, $opts, $id, $name) {
  my $pkg = $json->{package} // {};
  my $rep = $json->{report}  // {};

  my $accept    = $json->{acceptable_risk} // 3;
  my $threshold = $opts->{fail_on_risk}    // ($accept + 1);

  my @licenses
    = sort { $b->{risk} <=> $a->{risk} || $a->{name} cmp $b->{name} }
    map    { {name => $_, risk => $rep->{licenses}{$_}{risk}, spdx => $rep->{licenses}{$_}{spdx}} }
    keys %{$rep->{licenses} // {}};

  my $risk = $json->{risk};
  return {
    id              => $id,
    name            => $name,
    risk            => $risk,
    acceptable_risk => $accept,
    threshold       => $threshold,
    state           => $pkg->{state},
    unresolved      => $pkg->{unresolved_matches} // 0,
    licenses        => \@licenses,
    report_url      => "$opts->{url}/reviews/details/$id",
    gate            => (gate($risk, $threshold)->{failed} ? 'fail' : 'pass')
  };
}

# Download a generated document to a file, polling while the server builds it. Returns the path written.
sub _save_document ($client, $id, $key, $requested, $default, $timeout) {
  my $file     = length($requested // '') ? $requested : $default;
  my $deadline = Time::HiRes::time + $timeout;
  while (1) {
    my $body = $client->document($id, $key);
    if (defined $body) { path($file)->spew($body); return $file }
    last if Time::HiRes::time >= $deadline;
    Time::HiRes::sleep(1);
  }
  print STDERR "Timed out waiting for the $key document\n";
  return undef;
}

# A package name Cavil accepts (^[A-Za-z0-9.-]+$), derived from the directory being checked.
sub _package_name ($dir) {
  my $base = path($dir)->to_abs->basename;
  $base =~ s/[^A-Za-z0-9.\-]+/-/g;
  $base =~ s/^-+|-+$//g;
  return length $base ? $base : 'project';
}

# Best-effort provenance for the review: the git remote and short commit, when the tree is a checkout.
sub _external_link ($dir) {
  my $rev = _git($dir, 'rev-parse', '--short', 'HEAD') // return undef;
  my $url = _git($dir, 'config',    '--get',   'remote.origin.url');
  return defined $url ? "$url\@$rev" : $rev;
}

sub _git ($dir, @args) {
  my $cmd = join ' ', 'git', '-C', quotemeta($dir), map { quotemeta $_ } @args;
  my $out = `$cmd 2>/dev/null`;
  return undef if !defined $out || $? != 0;
  chomp $out;
  return length $out ? $out : undef;
}

1;

=encoding utf8

=head1 NAME

Cavil::CLI - Submit a project to Cavil for a legal review and gate CI on the result

=head1 SYNOPSIS

  Usage: cavil-cli <command> [DIR] [OPTIONS]

    # Save the URL and token once (prompts for the token without echoing it)
    cavil-cli config --url https://legaldb.suse.de

    # Confirm the URL and token are set up right (and time the round trip)
    cavil-cli whoami

    # Upload the current directory for a legal review and print the verdict
    cavil-cli check

    # Check another directory, and also download the SBOM
    cavil-cli check ./project --sbom

    # Machine-readable output for CI (URL and token from the environment)
    CAVIL_URL=https://legaldb.suse.de CAVIL_API_KEY=1234 cavil-cli check --format json

  Commands:
    check [DIR]              Upload a project for a legal review and report its licensing risk (default DIR: .)
    whoami                   Show the user the token belongs to, to verify login
    config                   Save the URL and token to ~/.config/cavil-cli (--show to display, token masked)

  Credentials come from the saved config ("cavil-cli config"), or CAVIL_URL/CAVIL_API_KEY in CI, always as a
  pair from one source. There is no --token (an argument is world-readable in ps and stays in shell history),
  and --url is only accepted by "config", since aiming elsewhere would send it a token saved for this server.

  The uploaded archive is the working tree as it sits on disk, including installed vendored dependencies
  (node_modules and the like) that a full legal review must cover; only .git and excludes are dropped. If the
  archive is over the server's upload limit (250 MiB by default, or CAVIL_MAX_UPLOAD_MB) the check refuses
  before uploading and tells you to trim it, so an accidental large file does not start a doomed upload.

  Options:
        --url <url>          Cavil server URL, when saving settings ("config" only)
        --name <name>        Package name to review under (default: the directory name)
        --priority <n>       Review priority 1-8 (default 5)
        --fail-on-risk <n>   Exit non-zero at this risk or above (default: the instance's acceptable risk + 1)
        --external-link <s>  Source label for traceability (default: the git remote and commit, if any)
        --sbom [<file>]      Download the SPDX SBOM (default file: <name>.spdx.json)
        --notice [<file>]    Download the NOTICE attribution file (default file: <name>.NOTICE.txt)
        --respect-gitignore  Also drop .gitignore'd paths from the archive (off by default, to keep vendored code)
        --exclude-path <p>   Drop this path from the archive (a tar pattern). Repeatable; also CAVIL_EXCLUDE_PATHS
        --timeout <n>        Seconds to wait for the review before giving up (default 900)
        --format <format>    Output format, "text" (default) or "json"
        --no-color           Disable coloured output
        --quiet              Do not show the progress line while working
    -h, --help               Show this summary of available options

=head1 DESCRIPTION

A command-line client that uploads the project you are working on to a Cavil instance, runs its standard legal
review, and reports the licensing risk, for a developer's laptop or a CI gate. See C<docs/Architecture.md> for
the design.

=cut
