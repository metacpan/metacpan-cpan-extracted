#!/usr/bin/env perl
# Pod-check karr's *source* files, before Pod::Weaver runs.
#
# Plain `podchecker lib/App/karr.pm` on a source file fails two ways on the
# [@Author::GETTY] weaver directives:
#   1. =attr / =method / =synopsis / ... are "Unknown directive" -- they only
#      become standard POD once Pod::Weaver rewrites them at build time.
#   2. L</some_method> links into those sections are "unresolved" -- their
#      =head2 targets do not exist until that same rewrite.
# That is why the canonical check -- [PodSyntaxTests]'s xt/author/pod-syntax.t
# (Test::Pod) -- runs against the *built* dist, where the weave has happened.
#
# This is the fast source-level equivalent: it applies the same directive->head
# mapping Pod::Elemental::Transformer::Author::GETTY uses (in memory, line for
# line so error line numbers still point at the source file), then runs
# Pod::Checker. Use it for a quick POD sanity pass without a full `dzil build`;
# the build-time Test::Pod check stays the authority.
#
# Usage: perl scripts/podcheck.pl [file-or-dir ...]     (default: lib bin)
use strict;
use warnings;
use Pod::Checker;
use File::Find ();

# Mirror Pod::Elemental::Transformer::Author::GETTY exactly (skill
# getty-perl-release-author-getty). Section commands get a fixed =head1 heading;
# inline commands become =head2, keeping their content (the attr/method/... name)
# as the heading -- which is what makes L</name> links resolve.
my %HEAD1 = ( synopsis => 'SYNOPSIS', description => 'DESCRIPTION', seealso => 'SEE ALSO' );
my $HEAD2 = join '|', qw( attr method func opt env hook example );

sub weave_directives {
  my ($pod) = @_;
  $pod =~ s/^=(synopsis|description|seealso)\b.*$/"=head1 $HEAD1{$1}"/mge;
  $pod =~ s/^=(?:$HEAD2)\b[ \t]*(.*)$/=head2 $1/mg;
  return $pod;
}

my @targets = @ARGV ? @ARGV : qw( lib bin );
my @files;
for my $t (@targets) {
  if (-d $t) {
    File::Find::find(sub {
      return unless -f;
      # .pm/.pl/.pod anywhere, plus extension-less executables living in a bin/
      push @files, $File::Find::name
        if /\.(?:pm|pl|pod)$/ || $File::Find::dir =~ m{(?:^|/)bin$};
    }, $t);
  }
  elsif (-f $t) {
    push @files, $t;
  }
  else {
    warn "podcheck: skip (not found): $t\n";
  }
}

my $errors = 0;
for my $file (sort @files) {
  open my $fh, '<:encoding(UTF-8)', $file or die "podcheck: $file: $!\n";
  my $pod = do { local $/; <$fh> };
  close $fh;

  my $checker = Pod::Checker->new;
  open my $report, '>', \my $buf or die "podcheck: in-memory open failed: $!\n";
  $checker->output_fh($report);
  $checker->parse_string_document( weave_directives($pod) );

  my $n = $checker->num_errors;
  next unless $n && $n > 0;    # -1 means "no POD in file"; 0 means clean
  $errors += $n;
  # parse_string_document has no filename to report, so Pod::Checker prints
  # "in file ???"; fill in the real path.
  $buf =~ s/ in file \Q???\E/ in file $file/g;
  printf "%s: %d error(s)\n", $file, $n;
  print $buf;
}

if ($errors) {
  printf "podcheck: %d error(s) across %d file(s)\n", $errors, scalar @files;
  exit 1;
}
printf "podcheck: OK (%d file(s))\n", scalar @files;
exit 0;
