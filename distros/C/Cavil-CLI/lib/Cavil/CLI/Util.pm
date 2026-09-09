# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later

package Cavil::CLI::Util;
use Mojo::Base -strict, -signatures;

use Exporter        qw(import);
use Digest::MD5     ();
use Mojo::File      qw(path);
use Mojo::JSON      qw(to_json);
use Term::ANSIColor ();

our @EXPORT_OK = qw(have_tool md5_file gate render_text render_json);

# Cavil's authoritative risk scale (see the cavil-review-note skill): 1-2 are obligation-free, 3 is file-level
# copyleft, 4 is strong copyleft, 5 and up escalate, 6-7 are reject-lean, 9 is unresolved/unknown. Shown next to
# the number so a bare "risk 4" is not left to interpretation.
my %RISK_LABEL = (
  1 => 'public domain',
  2 => 'permissive',
  3 => 'weak copyleft',
  4 => 'strong copyleft',
  5 => 'managed obligations',
  6 => 'restrictive obligations',
  7 => 'non-commercial',
  9 => 'unresolved'
);

# Whether an external command is on PATH, so a missing one is a clear "please install X" up front rather than a
# cryptic non-zero exit after the fact.
sub have_tool ($cmd) {
  return -x $cmd ? 1 : 0 if $cmd =~ m{/};
  -x "$_/$cmd" and return 1 for split /:/, ($ENV{PATH} // '');
  return 0;
}

# MD5 of a file, streamed so a large vendored archive is never slurped into memory. Matches the hash Cavil
# computes server-side, so it doubles as the upload's integrity checksum.
sub md5_file ($file) {
  my $md5 = Digest::MD5->new;
  $md5->addfile(path($file)->open('r'));
  return $md5->hexdigest;
}

# The CI gate: fail at or above the risk threshold, matching the report's own acceptable/unacceptable line.
sub gate ($risk, $threshold) {
  return {failed => (defined $risk && $risk >= $threshold) ? 1 : 0};
}

sub _label ($risk) { return $RISK_LABEL{$risk} // 'unclassified' }

sub _glyph ($risk, $threshold) {
  return "\x{2717}" if defined $risk && $risk >= $threshold;    # at or above the gate
  return "\x{2713}" if !defined $risk || $risk <= 2;            # obligation-free
  return "\x{2022}";                                            # obligations, but below the gate
}

sub _color ($risk, $threshold) {
  return 'red'   if defined $risk && $risk >= $threshold;
  return 'green' if !defined $risk || $risk <= 2;
  return 'yellow';
}

sub _paint ($on, $color, $text) { return $on && $color ? Term::ANSIColor::colored($text, $color) : $text }

# The machine format: the verdict plus the license list, for a CI step to police or store.
sub render_json ($info) {
  return to_json(
    {
      map  { $_ => $info->{$_} }
      grep { defined $info->{$_} }
        qw(id name risk acceptable_risk threshold state unresolved gate licenses report_url sbom notice)
    }
  ) . "\n";
}

# The human format: a headline tied to the gate, a one-line tally, then the licenses, highest risk first.
sub render_text ($info, %opts) {
  my $color     = $opts{color};
  my $threshold = $info->{threshold};
  my $risk      = $info->{risk};
  my $failed    = defined $risk && $risk >= $threshold;

  my $headline = defined $risk
    ? sprintf(
    '%s %s - risk %d (%s) %s threshold %d',
    _glyph($risk, $threshold),
    $info->{name}, $risk, _label($risk), $failed ? "\x{2265}" : 'within', $threshold
    )
    : sprintf('%s %s - no license risk detected', "\x{2713}", $info->{name});
  my $out = _paint($color, $failed ? 'red' : 'green', $headline) . "\n";

  my @licenses = @{$info->{licenses} || []};
  $out .= sprintf "  %d %s \x{b7} %d unresolved \x{b7} review state: %s\n", scalar(@licenses),
    (@licenses == 1 ? 'license' : 'licenses'), ($info->{unresolved} // 0), $info->{state} // '?';

  if (@licenses) {
    $out .= "\n";
    for my $l (@licenses) {
      my $g = _paint($color, _color($l->{risk}, $threshold), _glyph($l->{risk}, $threshold));
      $out .= sprintf "  %s  %-30s risk %d (%s)\n", $g, $l->{name}, $l->{risk}, _label($l->{risk});
    }
  }

  $out .= "\n  Report: $info->{report_url}\n" if $info->{report_url};
  $out .= "  SBOM:   $info->{sbom}\n"         if $info->{sbom};
  $out .= "  NOTICE: $info->{notice}\n"       if $info->{notice};

  return $out;
}

1;
