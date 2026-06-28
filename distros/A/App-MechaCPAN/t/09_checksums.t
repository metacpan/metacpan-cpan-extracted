use strict;
use warnings;
use Test::More;

require q[./t/helper.pm];

# A minimal-but-realistic CHECKSUMS body. PAUSE wraps this in a clearsigned
# PGP message; the lines between the header and __END__ are what
# CPAN::Checksums emits.
my $basic_dd = <<'EOF';
# CHECKSUMS file written on Thu May 16 12:34:56 2024 GMT by CPAN::Checksums v3.04
$cksum = {
  'NoDeps-1.0.tar.gz' => {
    'md5'         => '0123456789abcdef0123456789abcdef',
    'md5-ungz'    => 'fedcba9876543210fedcba9876543210',
    'mtime'       => '2024-05-16',
    'sha256'      => 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    'sha256-ungz' => 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    'size'        => 1234
  },
  'NoDeps-1.0.meta' => {
    'md5'    => '11111111111111111111111111111111',
    'sha256' => 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'mtime'  => '2024-05-16',
    'size'   => 256
  },
};
__END__
EOF

sub clearsign
{
  my $payload = shift;
  return join '',
    "0&&<<''; # this PGP-signed message is also valid perl\n",
    "-----BEGIN PGP SIGNED MESSAGE-----\n",
    "Hash: SHA256\n",
    "\n",
    $payload,
    "-----BEGIN PGP SIGNATURE-----\n",
    "\n",
    "iQEcBAEBCAAGBQJfFAKEMINOTAREALSIGNATUREBASE64==\n",
    "=AAAA\n",
    "-----END PGP SIGNATURE-----\n";
}

sub run_verify_for_success
{
  my $body = shift;

  local $@;
  my $result = eval { App::MechaCPAN::_verify_checksums_body($body) };
  my $err    = $@;

  isnt( $result, '', 'run_verify_for_success did produce a result' );
  is( $err, '', 'run_verify_for_success did not have an error' );

  diag($err)
    if $err;

  return $result;
}

sub run_verify_for_error
{
  my $body = shift;

  local $@;
  my $result = eval { App::MechaCPAN::_verify_checksums_body($body) };
  my $err    = $@;

  is( $result, undef, 'run_verify_for_error did not have a result' );
  isnt( $err, undef, 'run_verify_for_error did have an error' );

  return $err;
}

# happy path: a properly clearsigned CHECKSUMS file
{
  my $text   = clearsign($basic_dd);
  my $result = run_verify_for_success($text);
  isnt( $result, undef, 'accepts a well-formed clearsigned CHECKSUMS document' );
}

# rejects: empty/undef input
{
  my $err = run_verify_for_error('');
  like( $err, qr/header-line mismatch/, 'rejects empty body' );
  $err = run_verify_for_error(undef);
  like( $err, qr/header-line mismatch/, 'rejects undef body' );
}

# tolerates extra whitespace / trailing newlines around the PGP frame
{
  my $text   = "\n\n" . clearsign($basic_dd) . "\n\n";
  my $result = run_verify_for_success($text);
  isnt( $result, undef, 'tolerates surrounding whitespace' );
}

my $verify = sub {die};

# rejects: not a clearsigned message at all
{
  my $text = $basic_dd;
  my $err  = run_verify_for_error($text);
  like( $err, qr/header-line mismatch/, 'rejects bare body with no perl prologue' );

  $text = "0&&<<''; # this PGP-signed message is also valid perl\n$text";
  $err  = run_verify_for_error($text);
  like( $err, qr/PGP header mismatch/, 'rejects bare body with no PGP wrapper' );
}

# rejects: prologue altered so the heredoc terminator is non-empty
# (a hostile mirror might leave the PGP frame intact but break the
# "also valid perl" invariant, causing a naive eval to fail)
{
  my $text = clearsign($basic_dd);
  $text =~ s/^0\&\&<<''/0\&\&<<'NOPE'/xms;
  my $err = run_verify_for_error($text);
  like( $err, qr/header-line mismatch/, 'rejects tampered prologue with non-empty heredoc terminator' );
}

# rejects: signed-message header present but no signature block
{
  my $text = "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\n" . $basic_dd;
  my $err  = run_verify_for_error($text);
  like( $err, qr/header-line mismatch/, 'rejects truncated CHECKSUMS missing the signature block' );
}

# rejects: signature block present but no signed-message header
{
  my $text = $basic_dd . "-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG v2\n\nAAAA\n-----END PGP SIGNATURE-----\n";
  my $err  = run_verify_for_error($text);
  like( $err, qr/header-line mismatch/, 'rejects truncated CHECKSUMS missing the signature block' );
}

# rejects: payload doesn't define $cksum at all
{
  my $text = clearsign("# nothing interesting here\n__END__\n");
  my $err  = run_verify_for_error($text);
  like( $err, qr/Unexpected perl code/, 'rejects payload with no $cksum assignment' );
}

# rejects: payload defines something other than a hashref
{
  my $text = clearsign("\$cksum = 'not a hashref';\n__END__\n");
  my $err  = run_verify_for_error($text);
  like( $err, qr/Unexpected perl code/, 'rejects payload where $cksum is not a hashref' );
}

# rejects: payload tries to do something dangerous (eval should be sandboxed)
{
  my $bad = <<'EOF';
$cksum = {
  'pwned' => {
  }
};
system("touch /tmp/mechacpan_pwned_$$");
__END__
EOF
  my $text = clearsign($bad);
  my $err  = run_verify_for_error($text);
  like( $err, qr/Unexpected footer/, 'rejects payload where $cksum is not a hashref' );
  is( -e "/tmp/mechacpan_pwned_$$", undef, 'sandboxed payload cannot reach system()' );

  unlink "/tmp/mechacpan_pwned_$$"
    if -e "/tmp/mechacpan_pwned_$$";
}

# tolerates CRLF line endings end-to-end
{
  my $text = clearsign($basic_dd);
  $text =~ s/\n/\r\n/g;
  my $result = run_verify_for_success($text);
  isnt( $result, undef, 'accepts CRLF line endings' );
}

# rejects: hash body lines have no leading indentation at all
{
  my $bad = <<'EOF';
$cksum = {
'NoDeps-1.0.tar.gz' => {
'md5' => '0123456789abcdef0123456789abcdef'
},
};
__END__
EOF
  my $text = clearsign($bad);
  my $err  = run_verify_for_error($text);
  like( $err, qr/missing indentation/, 'rejects hash body with no indentation' );
}

# rejects: body-loop must reject any line shape other than the three
# accepted forms (sub-hash opener, key/value pair, close-brace)
{
  # trailing junk on the closing `};` (anchored ^};$ regression guard)
  my $bad = $basic_dd;
  $bad =~ s/^};$/};garbage/m;
  my $err = run_verify_for_error( clearsign($bad) );
  like( $err, qr/Unexpected perl code/, 'rejects trailing text on hash-close line' );

  # stray comment in the body (intro loop allows `#`, body loop must not)
  $bad = $basic_dd;
  $bad =~ s/^(\s+'NoDeps-1\.0\.meta')/  # stray comment\n$1/m;
  $err = run_verify_for_error( clearsign($bad) );
  like( $err, qr/Unexpected perl code/, 'rejects comments inside hash body' );

  # three-level nesting (a value is `{` instead of a scalar)
  $bad = <<'EOF';
$cksum = {
  'NoDeps-1.0.tar.gz' => {
    'sub' => {
      'md5' => '0123456789abcdef0123456789abcdef'
    }
  },
};
__END__
EOF
  $err = run_verify_for_error( clearsign($bad) );
  like( $err, qr/Unexpected perl code/, 'rejects three-level nested hash' );
}

# rejects: key must be a single-quoted simple identifier
{
  my $bad = $basic_dd;
  $bad =~ s/'NoDeps-1\.0\.tar\.gz'/"NoDeps-1.0.tar.gz"/;
  my $err = run_verify_for_error( clearsign($bad) );
  like( $err, qr/Unexpected perl code/, 'rejects double-quoted key' );

  $bad = $basic_dd;
  $bad =~ s/'NoDeps-1\.0\.tar\.gz'/42/;
  $err = run_verify_for_error( clearsign($bad) );
  like( $err, qr/Unexpected perl code/, 'rejects unquoted numeric key' );
}

# rejects: one-line empty hash (`$cksum = {};` not on its own opener line)
{
  my $text = clearsign("\$cksum = {};\n__END__\n");
  my $err  = run_verify_for_error($text);
  like( $err, qr/Unexpected perl code/, 'rejects one-line empty hash' );
}

# rejects: empty hash body — `$cksum = {` immediately followed by `};`
# leaves no first-body-line to capture indent from
{
  my $text = clearsign("\$cksum = {\n};\n__END__\n");
  my $err  = run_verify_for_error($text);
  like( $err, qr/missing indentation/, 'rejects empty hash body (no entries)' );
}

# rejects: tampering with the PGP wrapper around an otherwise-valid payload
{
  # truncated signature — no -----END PGP SIGNATURE----- line
  # (regression guard for the $result[-1] vs $content[-1] check)
  my $text = clearsign($basic_dd);
  $text =~ s/^-----END PGP SIGNATURE-----\n//m;
  my $err = run_verify_for_error($text);
  like( $err, qr/missing PGP signature end/, 'rejects truncated signature block' );

  # trailing data after the -----END PGP SIGNATURE----- line
  $text = clearsign($basic_dd) . "extra garbage after the end\n";
  $err  = run_verify_for_error($text);
  like( $err, qr/Unexpected data after end/, 'rejects content after -----END PGP SIGNATURE-----' );

  # wrong PGP signed-message marker
  $text = clearsign($basic_dd);
  $text =~ s/-----BEGIN PGP SIGNED MESSAGE-----/-----BEGIN PGP MESSAGE-----/;
  $err = run_verify_for_error($text);
  like( $err, qr/PGP header mismatch/, 'rejects wrong PGP signed-message marker' );
}

# ============================================================
# get_cpan_checksums — full path, with all network/verifier
# dependencies stubbed out at the package level.
# ============================================================

# rejects: non-HTTPS URLs
{
  local $@;
  eval { App::MechaCPAN::get_cpan_checksums('http://cpan.example.com/CHECKSUMS') };
  like( $@, qr/must be HTTPS/, 'rejects http:// URL' );

  eval { App::MechaCPAN::get_cpan_checksums('ftp://cpan.example.com/CHECKSUMS') };
  like( $@, qr/must be HTTPS/, 'rejects ftp:// URL' );

  eval { App::MechaCPAN::get_cpan_checksums('cpan.example.com/CHECKSUMS') };
  like( $@, qr/must be HTTPS/, 'rejects scheme-less URL' );
}

# rejects: URL not ending in CHECKSUMS
{
  local $@;
  eval { App::MechaCPAN::get_cpan_checksums('https://cpan.example.com/foo.tar.gz') };
  like( $@, qr/must end with CHECKSUMS/, 'rejects URL not ending in CHECKSUMS' );

  eval { App::MechaCPAN::get_cpan_checksums('https://cpan.example.com/CHECKSUMS.gz') };
  like( $@, qr/must end with CHECKSUMS/, 'rejects CHECKSUMS.gz' );
}

{
  # mock pieces of get_cpan_checksums so we're not running verifiers nor downloading files
  my $verifier_called   = 0;
  my $verifier_searched = 0;
  my $fetch_called      = 0;
  our $body;
  our $verifier = sub { $verifier_called++; return };
  our $keyring  = App::MechaCPAN::humane_tmpfile('keyring.pgp');

  no warnings 'redefine';
  local *App::MechaCPAN::fetch_file = sub
  {
    my ( $url, $dest ) = @_;
    $fetch_called++;
    $$dest = $body
      if defined $body;
    return;
  };
  local *App::MechaCPAN::cpan_keyring      = sub {$keyring};
  local *App::MechaCPAN::_resolve_verifier = sub { $verifier_searched++; $verifier };

  my $url = 'https://cpan.example.com/authors/id/A/AT/ATRODO/CHECKSUMS';

  # $CHKSIGS=0 — signature path skipped entirely; valid body returns cleanly,
  # Nothing is fetched nor a verifier is checked for
  {
    local $App::MechaCPAN::CHKSIGS = 0;
    local $body                    = clearsign($basic_dd);

    {
      $verifier_called = 0;
      $fetch_called    = 0;
      local $@;
      my $ok = eval { App::MechaCPAN::get_cpan_checksums($url); 1 };
      is( $ok, 1, '$CHKSIGS=0 returns cleanly on a valid body' )
        or diag $@;

      is( $fetch_called,    0, 'fetch_file was not invoked when $CHKSIGS=0' );
      is( $verifier_called, 0, 'verifier was not invoked when $CHKSIGS=0' );
    }
  }

  # best-effort ($CHKSIGS undef) + verifier resolves + valid body —
  # verifier closure is invoked with (CHECKSUMS-file-path, keyring-path)
  {
    my @verifier_args;
    my $body_seen;

    local $App::MechaCPAN::CHKSIGS;
    local $body     = clearsign($basic_dd);
    local $verifier = sub
    {
      $verifier_called++;
      @verifier_args = @_;
      open my $fh, '<', $verifier_args[0];
      $body_seen = do { local $/; <$fh> };
      return;
    };

    {
      $verifier_called = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums($url) };
      my $error = $@;
      is( $error, '', 'get_cpan_checksums ran without error' );
      isnt( $ok, undef, 'get_cpan_checksums ran completely' );
      is( ref $ok, 'HASH', 'get_cpan_checksums results is a hash' );

      is( $verifier_called,      1,          'verifier was called' );
      is( scalar @verifier_args, 2,          'verifier received two arguments' );
      is( $verifier_args[1],     "$keyring", 'second arg is the stubbed keyring path' );
      isnt( $body_seen, undef, 'verifier body was modified' );
      isnt( $body_seen, '',    'verifier could read the CHECKSUMS file off disk' );
      like( $body_seen, qr/cksum/, 'CHECKSUMS file content reached the verifier' );
    }
  }

  # $CHKSIGS undef + no verifier = best-effort; returns cleanly
  {
    local $App::MechaCPAN::CHKSIGS;
    local $body     = clearsign($basic_dd);
    local $verifier = undef;

    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums($url); 1 };
      my $error = $@;

      is( $ok,                1,  'get_cpan_checksums did completely run' );
      is( $error,             '', 'get_cpan_checksums did not throw an error' );
      is( $verifier_searched, 1,  'verifier search was called once' );
    }
  }

  # $CHKSIGS=1 + no verifier available — fatal
  {
    local $App::MechaCPAN::CHKSIGS = 1;
    local $body                    = clearsign($basic_dd);
    local $verifier                = undef;

    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums($url); 1 };
      my $error = $@;

      isnt( $ok,    1,  'get_cpan_checksums did not completely run' );
      isnt( $error, '', 'get_cpan_checksums threw an error' );
      like( $error, qr/verification program/, '$CHKSIGS=1 with no resolvable verifier dies' );
      is( $verifier_searched, 1, 'verifier search was called once' );
    }
  }

  # verifier dies — its failure propagates to the caller
  {
    local $App::MechaCPAN::CHKSIGS = 1;
    local $body                    = clearsign($basic_dd);
    local $verifier                = sub { die "BAD SIGNATURE\n" };

    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums($url); 1 };
      my $error = $@;

      isnt( $ok,    1,  'get_cpan_checksums did not completely run' );
      isnt( $error, '', 'get_cpan_checksums threw an error' );
      is( $verifier_searched, 1, 'verifier search was called once' );
      like( $error, qr/BAD SIGNATURE/, 'verifier failure propagates' );
    }
  }

  # $CHKSIGS undef + missing module = returns nothing
  {
    local $App::MechaCPAN::CHKSIGS;
    local $body     = clearsign($basic_dd);
    local $verifier = sub
    {
      $verifier_called++;
      return;
    };

    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums( $url, 'NoDeps-1.0.tar.gz' ); };
      my $error = $@;

      isnt( $ok, undef, 'get_cpan_checksums with known module did completely run' );
      is( ref $ok,            'HASH', 'get_cpan_checksums returns a hashref' );
      is( $error,             '',     'get_cpan_checksums did not throw an error' );
      is( $verifier_searched, 1,      'verifier search was called once' );
    }
    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums( $url, 'NoDeps-X.0.tar.gz' ); };
      my $error = $@;

      is( $ok,                undef, 'get_cpan_checksums with unknown module did completely run' );
      is( $error,             '',    'get_cpan_checksums did not throw an error' );
      is( $verifier_searched, 1,     'verifier search was called once' );
    }
  }

  # $CHKSIGS=1 + missing module = fatal
  {
    local $App::MechaCPAN::CHKSIGS = 1;
    local $body                    = clearsign($basic_dd);
    local $verifier                = sub
    {
      $verifier_called++;
      return;
    };

    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums( $url, 'NoDeps-1.0.tar.gz' ); };
      my $error = $@;

      isnt( $ok, undef, 'get_cpan_checksums with known module did completely run' );
      is( ref $ok,            'HASH', 'get_cpan_checksums returns a hashref' );
      is( $error,             '',     'get_cpan_checksums did not throw an error' );
      is( $verifier_searched, 1,      'verifier search was called once' );
    }
    {
      $verifier_searched = 0;
      local $@;
      my $ok    = eval { App::MechaCPAN::get_cpan_checksums( $url, 'NoDeps-X.0.tar.gz' ); };
      my $error = $@;

      is( $ok,                undef, 'get_cpan_checksums with unknown module did completely run' );
      isnt( $error,           '', 'get_cpan_checksums throw an error' );
      is( $verifier_searched, 1, 'verifier search was called once' );
    }
  }
}

done_testing;
