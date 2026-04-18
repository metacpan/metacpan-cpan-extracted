package App::DrivePlayer::MetadataFetcher;

use App::DrivePlayer::Setup;
use File::Temp   qw( tempfile );
use HTTP::Tiny;
use JSON::PP     qw( decode_json );
use URI::Escape  qw( uri_escape_utf8 );
use Time::HiRes  qw( sleep time usleep );

my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

Readonly my $USER_AGENT  => 'DrivePlayer/1.0 (https://github.com/mvsjes2/drive_player)';
Readonly my $ITUNES_BASE => 'https://itunes.apple.com/search';
Readonly my $MB_BASE     => 'https://musicbrainz.org/ws/2';
Readonly my $AID_BASE    => 'https://api.acoustid.org/v2/lookup';
Readonly my $DRIVE_URL   => 'https://www.googleapis.com/drive/v3/files/%s?alt=media';
Readonly my $MB_MIN_GAP  => 1.1;
Readonly my $DOWNLOAD_MB => 5;   # MB to download for fingerprinting

my $last_mb_req = 0;

has yield => (
    is      => 'ro',
    isa     => Maybe[CodeRef],
    default => sub { undef },
);

has acoustid_key => (
    is      => 'ro',
    isa     => Str,
    default => sub { '' },
);

has token_fn => (
    is      => 'ro',
    isa     => Maybe[CodeRef],
    default => sub { undef },
);

has _fp_stage => (
    is      => 'rw',
    default => sub { undef },
);

# Returns a short description of where the last fingerprint lookup stopped.
sub last_fp_stage { $_[0]->_fp_stage }

# ------------------------------------------------------------------
# Public: text-based lookup (iTunes -> MusicBrainz, with title cleaning)
# ------------------------------------------------------------------

sub fetch {
    my ($self, %args) = @_;
    my $title  = $args{title}  or return;
    my $artist = _clean_field($args{artist} // '');
    my $album  = _clean_field($args{album}  // '');

    $log->debug("Text search: title='$title' artist='$artist'") if $log;

    # 1. Try with original values
    my $meta = $self->_fetch_itunes($title, $artist, $album)
            // $self->_fetch_musicbrainz($title, $artist, $album);
    if ($meta) {
        $log->debug("Text search hit for '$title'") if $log;
        return $meta;
    }

    # 2. Try with cleaned title
    my $clean = _clean_title($title);
    if ($clean eq $title) {
        $log->debug("Text search miss for '$title' (no clean variant)") if $log;
        return;
    }

    $log->debug("Retrying with cleaned title '$clean'") if $log;
    $meta = $self->_fetch_itunes($clean, $artist, $album)
         // $self->_fetch_musicbrainz($clean, $artist, $album);
    $log->debug($meta ? "Text search hit (cleaned) for '$title'" : "Text search miss for '$title'") if $log;
    return $meta;
}

# ------------------------------------------------------------------
# Public: AcoustID fingerprint lookup
# ------------------------------------------------------------------

sub fetch_by_fingerprint {
    my ($self, %args) = @_;
    my $drive_id = $args{drive_id} or return;
    $self->_fp_stage(undef);

    return unless $self->acoustid_key && $self->token_fn;
    return unless fpcalc_available();

    $self->_fp_stage('downloading audio');
    $log->info("Fingerprint: downloading audio for drive_id=$drive_id") if $log;
    my $tmpfile = $self->_download_partial($drive_id);
    unless ($tmpfile) {
        $self->_fp_stage('download failed (token expired or Drive error)');
        $log->warn("Fingerprint: download failed for drive_id=$drive_id") if $log;
        return;
    }

    $self->_fp_stage('running fpcalc');
    $log->debug("Fingerprint: running fpcalc on $tmpfile") if $log;
    my $fp = _fingerprint($tmpfile);
    unlink $tmpfile;
    unless ($fp) {
        $self->_fp_stage('fpcalc produced no fingerprint');
        $log->warn("Fingerprint: fpcalc produced no output for drive_id=$drive_id") if $log;
        return;
    }

    $self->_fp_stage('querying AcoustID');
    $log->debug("Fingerprint: querying AcoustID (duration=$fp->{duration}s)") if $log;
    my $aid = $self->_query_acoustid($fp);
    unless ($aid) {
        $self->_fp_stage('no AcoustID match (score too low or track unknown)');
        $log->info("Fingerprint: no AcoustID match for drive_id=$drive_id") if $log;
        return;
    }

    $self->_fp_stage('fetching MusicBrainz metadata');
    $log->info("Fingerprint: AcoustID matched MusicBrainz recording $aid") if $log;
    my $meta = $self->_fetch_musicbrainz_by_id($aid);
    $self->_fp_stage($meta ? undef : 'MusicBrainz returned no data');
    $log->info($meta ? "Fingerprint: metadata found for drive_id=$drive_id" : "Fingerprint: MusicBrainz returned no data for $aid") if $log;
    return $meta;
}

# ------------------------------------------------------------------
# Title cleaning
# ------------------------------------------------------------------

sub _clean_field {
    my ($s) = @_;
    $s =~ s/_/ /g;
    $s =~ s/\s+/ /g;
    $s =~ s/^\s+|\s+$//g;
    return $s;
}

sub _clean_title {
    my ($t) = @_;

    # Normalise underscores and whitespace before any pattern matching
    $t =~ s/_/ /g;
    $t =~ s/\s+/ /g;
    $t =~ s/^\s+|\s+$//g;

    # Strip leading track number: "01.", "01 -", "(01)", "[01]", "01 "
    $t =~ s/^\s*[\(\[]?\d{1,3}[\)\]]?[\s.\-]+//;

    # Strip feat/ft/featuring/with credits
    $t =~ s/\s*[\(\[](feat|ft|featuring|with)\.?\s+[^\)\]]+[\)\]]//ig;
    $t =~ s/\s+(feat|ft|featuring)\s+.+$//ig;

    # Strip common parenthetical junk (order matters: specific before generic)
    my @strip = (
        qr/\s*[\(\[]\s*(?:\d{4}\s+)?(?:digital\s+)?remaster(?:ed)?(?:\s+\d{4})?\s*[\)\]]/i,
        qr/\s*[\(\[]\s*live(?:\s+at\s+[^\)\]]+)?\s*[\)\]]/i,
        qr/\s*[\(\[]\s*(?:official\s+)?(?:audio|video|lyric\s+video|music\s+video)\s*[\)\]]/i,
        qr/\s*[\(\[]\s*(?:radio|single|album|extended|original|instrumental|acoustic|demo|mono|stereo)\s+(?:edit|version|mix|take)?\s*[\)\]]/i,
        qr/\s*[\(\[]\s*(?:explicit|clean|censored)\s*[\)\]]/i,
        qr/\s*[\(\[]\s*(?:hd|hq|\d+hz|\d+\s*hz|4k)\s*[\)\]]/i,
        qr/\s*-\s*(?:single|ep|soundtrack)\s*$/i,
        qr/\s*[\(\[]\s*(?:19|20)\d{2}\s*[\)\]]/,
    );
    for my $re (@strip) { $t =~ s/$re//g }

    return _clean_field($t);
}

# ------------------------------------------------------------------
# iTunes
# ------------------------------------------------------------------

sub _fetch_itunes {
    my ($self, $title, $artist, $album) = @_;

    my $term = join(' ', grep { length } $artist, $title);
    my $url  = $ITUNES_BASE . '?term=' . uri_escape_utf8($term)
             . '&entity=song&media=music&limit=5';

    my $data    = $self->_get_plain($url) or return;
    my $results = $data->{results}        or return;
    return unless @$results;

    my $best = _best_itunes_match($results, $title, $artist, $album);
    return unless $best;

    my %meta;
    $meta{title}        = $best->{trackName}       if $best->{trackName};
    $meta{artist}       = $best->{artistName}       if $best->{artistName};
    $meta{album}        = $best->{collectionName}   if $best->{collectionName};
    $meta{genre}        = $best->{primaryGenreName} if $best->{primaryGenreName};
    $meta{track_number} = $best->{trackNumber}      if $best->{trackNumber};
    ($meta{year})       = ($best->{releaseDate} // '') =~ /^(\d{4})/;
    return \%meta;
}

sub _best_itunes_match {
    my ($results, $want_title, $want_artist, $want_album) = @_;
    my $score = sub {
        my ($r) = @_;
        my $s = 0;
        $s += 3 if $want_title  && _fuzzy($r->{trackName},     $want_title);
        $s += 2 if $want_artist && _fuzzy($r->{artistName},     $want_artist);
        $s += 1 if $want_album  && _fuzzy($r->{collectionName}, $want_album);
        return $s;
    };
    my ($best) = sort { $score->($b) <=> $score->($a) } @$results;
    return unless $want_title && _fuzzy($best->{trackName}, $want_title);
    return $best;
}

sub _fuzzy {
    my ($hay, $needle) = @_;
    return unless defined $hay && defined $needle && length $needle;
    return index(lc($hay), lc($needle)) >= 0
        || index(lc($needle), lc($hay)) >= 0;
}

# ------------------------------------------------------------------
# MusicBrainz (text search, fuzzy, progressive relaxation)
# ------------------------------------------------------------------

sub _fetch_musicbrainz {
    my ($self, $title, $artist, $album) = @_;

    my @attempts;
    push @attempts, 'recording:' . _mb_q($title) . '~ AND artist:' . _mb_q($artist)
                  . '~ AND release:' . _mb_q($album) . '~'
        if $artist && $album;
    push @attempts, 'recording:' . _mb_q($title) . '~ AND artist:' . _mb_q($artist) . '~'
        if $artist;
    push @attempts, 'recording:' . _mb_q($title) . '~';

    for my $query (@attempts) {
        my $url = "$MB_BASE/recording?query=" . uri_escape_utf8($query)
                . '&fmt=json&limit=5&inc=releases+artist-credits+tags+genres';
        my $data = $self->_get_mb($url) or next;
        my $recs = $data->{recordings}  or next;
        next unless @$recs;
        my $meta = $self->_parse_mb_with_release($recs->[0]);
        return $meta if $meta && %$meta;
    }
    return;
}

sub _fetch_musicbrainz_by_id {
    my ($self, $mb_id) = @_;
    my $url  = "$MB_BASE/recording/$mb_id?fmt=json&inc=releases+artist-credits+tags+genres";
    my $rec  = $self->_get_mb($url) or return;
    return $self->_parse_mb_with_release($rec);
}

sub _parse_mb_with_release {
    my ($self, $rec) = @_;
    my %meta = %{ _parse_mb($rec) };

    # If we didn't get a genre from the recording, try the release-group level
    if (!$meta{genre} && (my $rel = _best_mb_release($rec->{releases} // []))) {
        my $rg_url = "$MB_BASE/release/$rel->{id}?fmt=json&inc=release-groups+genres+tags";
        my $rd = $self->_get_mb($rg_url);
        if ($rd) {
            $meta{genre} //= _best_mb_genre($rd->{genres}, $rd->{tags});
            if (!$meta{genre} && (my $rg = $rd->{'release-group'})) {
                my $rg_full_url = "$MB_BASE/release-group/$rg->{id}?fmt=json&inc=genres+tags";
                my $rgd = $self->_get_mb($rg_full_url);
                $meta{genre} //= _best_mb_genre($rgd->{genres}, $rgd->{tags}) if $rgd;
            }
        }
    }
    return \%meta;
}

sub _parse_mb {
    my ($rec) = @_;
    my %meta;
    $meta{title} = $rec->{title} if $rec->{title};
    if (my $credits = $rec->{'artist-credit'}) {
        $meta{artist} = join(', ',
            map  { $_->{name} // $_->{artist}{name} // () }
            grep { ref $_ eq 'HASH' } @$credits
        );
    }
    if (my $rel = _best_mb_release($rec->{releases} // [])) {
        $meta{album} = $rel->{title};
        ($meta{year}) = ($rel->{date} // '') =~ /^(\d{4})/;
    }
    $meta{genre} = _best_mb_genre($rec->{genres}, $rec->{tags});
    return \%meta;
}

# Prefer MB's curated genres over folksonomy tags; pick the highest-count entry.
sub _best_mb_genre {
    my ($genres, $tags) = @_;
    if ($genres && @$genres) {
        my ($top) = sort { $b->{count} <=> $a->{count} } @$genres;
        return ucfirst($top->{name}) if $top;
    }
    if ($tags && @$tags) {
        my ($top) = sort { $b->{count} <=> $a->{count} } @$tags;
        return ucfirst($top->{name}) if $top;
    }
    return;
}

sub _best_mb_release {
    my ($releases) = @_;
    return unless @$releases;
    my @dated = grep { $_->{date} } @$releases;
    return @dated ? $dated[0] : $releases->[0];
}

sub _mb_q {
    my ($s) = @_;
    $s =~ s/["\\+\-&|!(){}\[\]^~*?:\/]/\\$&/g;
    return $s;
}

# ------------------------------------------------------------------
# AcoustID
# ------------------------------------------------------------------

sub fpcalc_available {
    return -x '/usr/bin/fpcalc' || -x '/usr/local/bin/fpcalc';
}

sub ffprobe_available {
    return -x '/usr/bin/ffprobe' || -x '/usr/local/bin/ffprobe';
}

sub flac_available {
    return eval { require Audio::FLAC::Header; 1 } // 0;
}

# Read embedded Vorbis Comment tags + duration from a FLAC file on Drive.
# Downloads only the first 512 KB (enough for any FLAC header).
# Returns a hashref of metadata fields, or undef on failure/no tags.
sub read_embedded_tags {
    my ($self, $drive_id) = @_;
    return unless flac_available();

    my $tmpfile = $self->_download_partial($drive_id, 512 * 1024);
    return unless $tmpfile;

    my $flac = eval { Audio::FLAC::Header->new($tmpfile) };
    unlink $tmpfile;
    return unless $flac;

    my $raw  = $flac->tags() // {};
    my %tags = map { lc($_) => $raw->{$_} } keys %$raw;

    my %meta;
    $meta{title}        = $tags{title}       if $tags{title};
    $meta{artist}       = $tags{artist}      if $tags{artist};
    $meta{album}        = $tags{album}       if $tags{album};
    $meta{genre}        = $tags{genre}       if $tags{genre};
    $meta{comment}      = $tags{comment}     if $tags{comment};
    if ($tags{tracknumber} && $tags{tracknumber} =~ /^(\d+)/) {
        $meta{track_number} = $1 + 0;
    }
    if ($tags{date} && $tags{date} =~ /^(\d{4})/) {
        $meta{year} = $1 + 0;
    }

    # Duration from FLAC stream info block
    my $info = $flac->info();
    if ($info && $info->{TOTALSAMPLES} && $info->{SAMPLERATE}) {
        $meta{duration_ms} = int($info->{TOTALSAMPLES} / $info->{SAMPLERATE} * 1000);
    } elsif ($flac->{trackTotalLengthSeconds}) {
        $meta{duration_ms} = int($flac->{trackTotalLengthSeconds} * 1000);
    }

    return %meta ? \%meta : undef;
}

# Probe a Drive file for duration (milliseconds) using ffprobe.
# Returns undef if ffprobe is unavailable or the probe fails.
sub probe_duration_ms {
    my ($class, $drive_id, $token) = @_;
    return unless ffprobe_available();

    my $ffprobe = -x '/usr/bin/ffprobe' ? '/usr/bin/ffprobe' : 'ffprobe';
    my $url     = sprintf($DRIVE_URL, $drive_id);
    my $header  = "Authorization: $token\r\n";

    my $out = q{};
    my $pid = open(my $fh, '-|', $ffprobe,
        '-v',            'error',
        '-headers',      $header,
        '-show_entries', 'format=duration',
        '-of',           'default=noprint_wrappers=1:nokey=1',
        $url,
    );
    if ($pid) {
        $out = do { local $/; <$fh> };
        close $fh;
    }
    return unless $out =~ /^(\d+(?:\.\d+)?)/m;
    return int($1 * 1000);
}

# Keep private alias for internal calls
sub _fpcalc_available { fpcalc_available() }

sub _download_partial {
    my ($self, $drive_id, $max_bytes) = @_;
    my $token = $self->token_fn->();
    unless ($token) {
        $log->warn("Fingerprint: no bearer token available") if $log;
        return;
    }

    my $url     = sprintf $DRIVE_URL, uri_escape_utf8($drive_id);
    my $max     = ($max_bytes // ($DOWNLOAD_MB * 1024 * 1024)) - 1;
    my $ua      = HTTP::Tiny->new(agent => $USER_AGENT, timeout => 30);
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.audio', UNLINK => 0);
    binmode $fh;

    my $res = $ua->request('GET', $url, {
        headers       => {
            Authorization => $token,
            Range         => "bytes=0-$max",
        },
        data_callback => sub { print {$fh} $_[0] },
    });
    close $fh;

    if ($res->{success} || $res->{status} == 206) {
        $log->debug("Fingerprint: downloaded " . (-s $tmpfile) . " bytes for drive_id=$drive_id") if $log;
        return $tmpfile;
    }

    $log->warn("Fingerprint: HTTP $res->{status} downloading drive_id=$drive_id: $res->{reason}") if $log;
    unlink $tmpfile;
    return;
}

sub _fingerprint {
    my ($tmpfile) = @_;
    my $fpcalc = -x '/usr/bin/fpcalc' ? '/usr/bin/fpcalc' : 'fpcalc';
    my $json   = qx($fpcalc -json -length 120 \Q$tmpfile\E 2>/dev/null);
    return unless $json;
    my $data = eval { decode_json($json) } or return;
    return unless $data->{fingerprint} && $data->{duration};
    return { fingerprint => $data->{fingerprint}, duration => int($data->{duration}) };
}

sub _query_acoustid {
    my ($self, $fp) = @_;
    my $url = $AID_BASE
            . '?client='      . uri_escape_utf8($self->acoustid_key)
            . '&meta=recordings+compress'
            . '&duration='    . $fp->{duration}
            . '&fingerprint=' . uri_escape_utf8($fp->{fingerprint});

    my $data    = $self->_get_plain($url) or return;
    my $results = $data->{results}        or return;
    return unless @$results;

    # Pick the result with the highest score
    my ($best) = sort { $b->{score} <=> $a->{score} } @$results;
    return unless $best->{score} && $best->{score} > 0.5;

    my $recordings = $best->{recordings} or return;
    return unless @$recordings;
    return $recordings->[0]{id};
}

# ------------------------------------------------------------------
# HTTP helpers
# ------------------------------------------------------------------

sub _get_plain {
    my ($self, $url) = @_;
    my $ua  = HTTP::Tiny->new(agent => $USER_AGENT, timeout => 5);
    my $res = $ua->get($url);
    return unless $res->{success};
    return eval { decode_json($res->{content}) };
}

sub _get_mb {
    my ($self, $url) = @_;
    my $gap = $MB_MIN_GAP - (time() - $last_mb_req);
    $self->_yield_sleep($gap) if $gap > 0;
    $last_mb_req = time();
    return $self->_get_plain($url);
}

sub _yield_sleep {
    my ($self, $secs) = @_;
    my $yield = $self->yield;
    if ($yield) {
        my $end = time() + $secs;
        while (time() < $end) {
            $yield->();
            usleep(50_000);
        }
    } else {
        sleep($secs);
    }
}

1;

__END__

=head1 NAME

App::DrivePlayer::MetadataFetcher - Fetch track metadata from iTunes, MusicBrainz, and AcoustID

=head1 SYNOPSIS

  use App::DrivePlayer::MetadataFetcher;

  my $fetcher = App::DrivePlayer::MetadataFetcher->new(
      yield        => sub { ... },          # optional: pump GTK events during waits
      acoustid_key => 'YOUR_KEY',           # optional: enables fingerprint lookup
      token_fn     => sub { 'Bearer ...' }, # optional: required for fingerprinting
  );

  # Text-based lookup (iTunes first, MusicBrainz fallback, with title cleaning)
  my $meta = $fetcher->fetch(title => 'Come Together', artist => 'Beatles');

  # Acoustic fingerprint lookup (requires fpcalc + AcoustID key)
  my $meta = $fetcher->fetch_by_fingerprint(drive_id => $id);

=head1 DESCRIPTION

Tries multiple strategies in order to find metadata for a track:

=over 4

=item 1.

iTunes Search API with original title/artist (fuzzy, no rate limit).

=item 2.

MusicBrainz with original title/artist (fuzzy ~ operator, progressive relaxation).

=item 3.

Both sources again with a cleaned title (track numbers, remaster tags, feat.
credits, and other common junk stripped).

=item 4.

AcoustID acoustic fingerprinting via C<fpcalc>: downloads the first 5 MB of
the Drive file, generates a Chromaprint fingerprint, queries AcoustID, then
fetches full metadata from MusicBrainz.  Requires C<acoustid_key> and
C<token_fn> to be set, and C<fpcalc> to be installed
(C<sudo apt install libchromaprint-tools>).

=back

=head1 METHODS

=head2 new

  my $f = App::DrivePlayer::MetadataFetcher->new(%args);

Optional args: C<yield> (CodeRef), C<acoustid_key> (Str), C<token_fn> (CodeRef
returning a Bearer token string).

=head2 fetch

  my $hashref = $f->fetch(title => $t, artist => $a, album => $al);

Returns a hashref with any of: C<title artist album year genre track_number>.
Returns C<undef> on no match.

=head2 fetch_by_fingerprint

  my $hashref = $f->fetch_by_fingerprint(drive_id => $id);

Identifies the track by acoustic fingerprint.  Returns C<undef> if fpcalc
is not installed, no AcoustID key is configured, or no match is found.

=cut
